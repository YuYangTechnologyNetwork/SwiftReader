//
//  Db.swift
//  NovelReader
//
//  Created by kyongen on 6/6/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation
import FMDB

protocol Rowable {
    func values() -> [AnyObject]
}

class Db {

    /// Define tables
    enum Table: String {
        case Books = "Book TEXT, Downloaded INTEGER, Extracted INTEGER,  BmTItle TEXT, BmLoc INTEGER"
        case Catalog = "Title TEXT, Location INTEGER, Length INTEGER, Hash INTEGER"
        case Profile = "AutoNight INTEGER, Typesetter TEXT"

        var Insert: String {
            switch self {
            case .Catalog:
                return "INSERT INTO \(self) (Title, Location, Length, Hash) VALUES (?, ?, ?, ?)"
            case .Books:
                break
            case .Profile:
                break
            }

            return ""
        }

        var Count: String {
            switch self {
            case .Catalog:
                return "SELECT COUNT(*) AS `Count` FROM \(self)"
            case .Books:
                break
            case .Profile:
                break
            }

            return ""
        }
    }
    
    private var fmDb: FMDatabase
    private(set) var table: Table!

    /**
     Init db

     - parameter name:  database name
     - parameter table: table name

     - returns: If fail nil will return
     */
    init!(name: String, table: Table) {
        let filemgr = NSFileManager.defaultManager()
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let databasePath = dirPath.stringByAppendingString("/" + name + ".sqlite")

        Utils.Log("Db Path: " + databasePath)
        if !filemgr.fileExistsAtPath(databasePath) {
            if let db = FMDatabase(path: databasePath) {
                if db.open() {
                    let sql_stmt = "CREATE TABLE IF NOT EXISTS \(table) (\(table.rawValue))"
                    if !db.executeStatements(sql_stmt) {
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
        self.table = table
    }

    /**
     Open sqlite db

     - parameter task: auto execute task
     */
    func open(task: ((db: Db) -> Void)? = nil) {
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

        fmDb.executeStatements("DROP TABLE IF EXISTS \(table)")

        let sql_stmt = "CREATE TABLE IF NOT EXISTS \(table) (\(table.rawValue))"
        if !fmDb.executeStatements(sql_stmt) {
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

     - returns: Count of rows
     */
    func count(reopen: Bool = false) -> Int {
        if reopen {
            fmDb.open()
        }

        let res = fmDb.executeQuery(table.Count, withArgumentsInArray: nil)
        if res.next() {
            return res.longForColumnIndex(0)
        }

        if reopen {
            fmDb.close()
        }

        return 0
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

        let res = fmDb.executeUpdate(table.Insert, withArgumentsInArray: row.values())

        if reopen {
            fmDb.close()
        }

        return res
    }
}