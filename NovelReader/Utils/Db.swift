//
//  Db.swift
//  NovelReader
//
//  Created by kyongen on 6/6/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation
import FMDB

/// Lite ORM protocol

protocol Rowable {
    /// Inner sqlite row id, started width 1
    var rowId: Int { get set }
    /// Table name
    var table: String { get }
    /// Table Columns and default value(or update/insert value)
    var fields: [Db.Field] { get }
    /**
     Parse row to Object
     
     - parameter row: row data, [column1, column2...]
     
     - returns: A Rowable type object
     */
    func parse(row: [AnyObject]) -> Rowable
}

/// FMDB Manager class

final class Db {
    /**
     Database fields enum
     
     - TEXT:    Sqlite TEXT => (ColumnName, default/value)
     - REAL:    Sqlite REAL(float) => (ColumnName, default/value)
     - BLOB:    Sqlite BLOB => (ColumnName, default/value)
     - INTEGER: Sqlite INTEGER => (ColumnName, default/value)
     */
    
    enum Field {
        case REAL(name: String, value: Float)
        case BLOB(name: String, value: NSData)
        case TEXT(name: String, value: String)
        case INTEGER(name: String, value: Int)
        
        private var associated: (name: String, value: AnyObject) {
            switch self {
            case .TEXT(let n, let v):
                return (name: n, value: v)
            case .REAL(let n, let v):
                return (name: n, value: v)
            case .BLOB(let n, let v):
                return (name: n, value: v)
            case .INTEGER(let n, let v):
                return (name: n, value: v)
            }
        }
        
        private var sqliteType: String {
            switch self {
            case .TEXT(_, _):
                return "TEXT"
            case .REAL(_, _):
                return "REAL"
            case .BLOB(_, _):
                return "BLOB"
            case .INTEGER(_, _):
                return "INTEGER"
            }
        }
        
        private static func createSql(fields: [Db.Field]) -> String {
            var sql = ""
            for i in 0 ..< fields.count {
                let f = fields[i]
                sql += "`\(f.associated.name)` \(f.sqliteType)"
                
                if i < fields.count - 1 {
                    sql += ","
                }
            }
            
            return sql
        }
        
        private static func split(fields: [Db.Field]) -> (c: String, p: String, v: [AnyObject]) {
            var sql = "", vs: [AnyObject] = [], ps = ""
            
            for i in 0 ..< fields.count {
                let f = fields[i]
                
                sql += "`\(f.associated.name)`"
                ps += "?"
                
                if i < fields.count - 1 {
                    sql += ", "
                    ps += ", "
                }
                
                vs.append(f.associated.value)
            }
            
            return (c: sql, p: ps, v: vs)
        }
    }
    
    /**
     Db execute SQL
     
     - Create: Create
     - Insert: Insert
     - Delete: Delete
     - Update: Update
     - Query:  Select
     - Count:  Count
     - Clear:  Drop
     */
    
    private enum Operator {
        case Create(Rowable)
        case Insert(Rowable)
        case Update(Rowable, conditions: String?)
        case Query(Rowable, conditions: String?)
        case Delete(Rowable, conditions: String?)
        case Count(Rowable, conditions: String?)
        case Clear(Rowable)
        
        private var sql: String {
            switch self {
            case .Create(let r):
                return "CREATE TABLE IF NOT EXISTS \(r.table) (RowId INTEGER PRIMARY KEY, \(Field.createSql(r.fields)))"
            case .Insert(let r):
                let splits = Field.split(r.fields)
                return "INSERT INTO \(r.table) (\(splits.c)) VALUES (\(splits.p))"
            case .Update(let r, let c):
                var sql = ""
                for i in 0 ..< r.fields.count {
                    let f = r.fields[i]
                    sql += "\(f.associated.name) = `\(f.associated.value)`"
                    if i < r.fields.count - 1 {
                        sql += ", "
                    }
                }
                return "UPDATE \(r.table) SET " + sql + " " + (c ?? "")
            case .Query(let r, let c):
                return "SELECT * FROM \(r.table) " + (c ?? "")
            case .Delete(let r, let c):
                return "DELETE FROM \(r.table) " + (c ?? "")
            case .Count(let r, let c):
                return "SELECT COUNT(*) FROM \(r.table) " + (c ?? "")
            case .Clear(let r):
                return "DROP TABLE IF EXISTS \(r.table)"
            }
        }
    }
    
    /// Cursor for segment loading
    
    class Cursor {
        private(set) var db: Db!
        private var mStartPosition: Int
        private var mBufferSize: Int
        private var mBuffer: [Rowable] = []
        private var mRowsCount: Int = 0
        private var mCurrPosition: Int = 0
        
        /// Cursor is empty?
        var isEmpty: Bool {
            return mBuffer.isEmpty
        }
        
        /**
         Cursor for load segment
         
         - parameter db:         Db object
         - parameter start:      First row index
         - parameter bufferSize: Extra buffer size
         */
        init(db: Db, bufferSize: Int = 50) {
            self.db = db
            self.mStartPosition = 0
            self.mBufferSize = bufferSize
            self.mCurrPosition = 0
            
            self.db.open {
                db in
                self.mRowsCount = db.count()
            }
        }
        
        /// Locate the cursor
        ///
        /// - parameter position: row position
        func moveTo(position: Int) {
            let offset = position - mStartPosition
            
            if offset <= 0 || offset >= mBuffer.count - 1 {
                fillBuffer(position)
            }
            
            mCurrPosition = position
        }
        
        func getRow() -> Rowable {
            return mBuffer[mCurrPosition - mStartPosition]
        }
        
        private func fillBuffer(requiredPos: Int) {
            self.db.open {
                db in
                self.mRowsCount = db.count()
                
                if self.mRowsCount == 0 {
                    self.mBuffer = []
                    self.mStartPosition = 0
                    self.mCurrPosition = 0
                } else {
                    let index = max(0, requiredPos - self.mBufferSize)
                    let length = min(requiredPos - index + self.mBufferSize * 2, self.mRowsCount - index)
                    self.mBuffer = db.query(false, conditions: "limit \(index), \(length)")
                    self.mStartPosition = self.mBuffer[0].rowId - 1
                }
            }
        }
        
        private func asyncLoading(callback: ([Rowable]) -> Void) {
            Utils.asyncTask({
                () -> [Rowable] in
                var rows: [Rowable] = []
                self.db.open {
                    db in
                    if self.mRowsCount == 0 {
                        self.mRowsCount = self.db.count()
                    }
                    
                    rows = self.db.query(false, conditions: "limit \(self.mStartPosition), \(self.mBufferSize * 3)")
                }
                
                return rows
            }) {
                rows in
                callback(rows)
                Utils.Log("Loaded: \(self.mStartPosition)")
            }
        }
        
        /**
         Total count
         
         - returns: Database total count
         */
        func count() -> Int {
            return mRowsCount
        }
    }
    
    private var fmDb: FMDatabase
    private var rowable: Rowable!
    private var database: String
    
    /**
     Init db
     
     - parameter name:  database name
     - parameter table: table name
     
     - returns: If fail nil will return
     */
    init!(db: String = "NovelReader", rowable r: Rowable) {
        let filemgr = NSFileManager.defaultManager()
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let databasePath = dirPath.stringByAppendingString("/" + db + ".sqlite")
        
        Utils.Log("Db Path: " + databasePath)
        if !filemgr.fileExistsAtPath(databasePath) {
            if let db = FMDatabase(path: databasePath) {
                if db.open() {
                    if !db.executeStatements(Operator.Create(r).sql) {
                        Utils.Log("Error: \(db.lastErrorMessage())")
                    }
                    
                    db.close()
                } else {
                    Utils.Log("Error: \(db.lastErrorMessage())")
                    return nil
                }
            } else {
                Utils.Log("Error: init db for path[\(databasePath)] failed")
                return nil
            }
        }
        
        fmDb = FMDatabase(path: databasePath)
        rowable = r
        database = db + ".sqlite"
    }
    
    var description: String {
        return "\(database)/\(rowable.table)[\(Field.split(rowable.fields).c)]"
    }
    
    /**
     Open sqlite db
     
     - parameter task: auto execute task, if not nil, db.close will be call when task finished
     */
    func open(task:((db:Db) -> Void)? = nil) {
        fmDb.open()
        
        if let t = task {
            t(db: self)
            fmDb.close()
        }
    }
    
    /**
     Close sqlite db
     */
    func close() {
        fmDb.close()
    }
    
    /**
     Recreate table
     
     - parameter reopen: need open db
     
     - returns: For chain-type call
     */
    func clear(reopen: Bool = false) -> Db {
        if reopen {
            fmDb.open()
        }
        
        fmDb.executeStatements(Operator.Clear(rowable).sql)
        
        if !fmDb.executeStatements(Operator.Create(rowable).sql) {
            Utils.Log("Error: \(fmDb.lastErrorMessage())")
        }
        
        if reopen {
            fmDb.close()
        }
        
        return self
    }
    
    /**
     Count rows
     
     - parameter reopen: need open db
     
     - returns: Count of rows or -1 if count exception
     */
    func count(reopen: Bool = false) -> Int {
        if reopen {
            fmDb.open()
        }
        
        let res = fmDb.executeQuery(Operator.Count(rowable, conditions: nil).sql, withArgumentsInArray: nil)
        var count = -1
        
        if let r = res {
            if r.next() {
                count = r.longForColumnIndex(0)
            }
        } else {
            Utils.Log(fmDb.lastErrorMessage())
        }
        
        if reopen {
            fmDb.close()
        }
        
        return count
    }
    
    /**
     Insert
     
     - parameter row:    Give column values
     - parameter reopen: need open db
     
     - returns: Success is true
     */
    func insert(row: Rowable, reopen: Bool = false) -> Bool {
        if reopen {
            fmDb.open()
        }
        
        let res = fmDb.executeUpdate(Operator.Insert(row).sql, withArgumentsInArray: Field.split(row.fields).v)
        
        if reopen {
            fmDb.close()
        }
        
        return res
    }
    
    /**
     Query
     
     - parameter reopen:     need open db?
     - parameter conditions: Conditions: conform to standard SQL syntax. eg: where `column1` = 123 limit 0, 30
     
     - returns: Result [Rowable]
     */
    func query(reopen: Bool = false, conditions: String? = nil) -> [Rowable] {
        if reopen {
            fmDb.open()
        }
        
        let res = fmDb.executeQuery(Operator.Query(rowable, conditions: conditions).sql, withArgumentsInArray: nil)
        var rows: [Rowable] = []
        
        while res != nil && res.next() {
            var row: [AnyObject] = []
            
            for f in rowable.fields {
                let value: AnyObject
                switch f {
                case .TEXT(let n, _):
                    value = res.stringForColumn(n)
                case .REAL(let n, _):
                    value = NSNumber(double: res.doubleForColumn(n)).floatValue
                case .BLOB(let n, _):
                    value = res.dataForColumn(n)
                case .INTEGER(let n, _):
                    value = NSNumber(integer: res.longForColumn(n)).integerValue
                }
                
                row.append(value)
            }
            
            var r = rowable.parse(row)
            r.rowId = NSNumber(integer: res.longForColumn("RowId")).integerValue
            rows.append(r)
        }
        
        if reopen {
            fmDb.close()
        }
        
        return rows
    }
    
    /**
     Do transaction
     
     - parameter task: If false return, rollback will be execute
     */
    func inTransaction(task: () -> Bool) {
        fmDb.beginTransaction()
        
        if !task() {
            fmDb.rollback()
        } else {
            fmDb.commit()
        }
    }
    
}
