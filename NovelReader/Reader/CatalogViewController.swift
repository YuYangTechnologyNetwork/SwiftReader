//
//  CatalogViewController.swift
//  NovelReader
//
//  Created by kyongen on 6/3/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class CatalogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleAndTableSplitLine: UIView!
    @IBOutlet weak var emptyTipsView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fetchCatalogBtn: UIButton!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var mBtnReload: UIButton!
    
    private var mBook: Book!
    private var mSqlDB: Db!
    private var mCursor: Db.Cursor!
    private var mCurrChapter: BookMark!
    private var mCellSelectedBg: UIView!
    private var mDismissListener: ((Bool, BookMark?) -> Void)!
    private var mCatalogIsFetched = false
    private var mShowFetchingAnimation = true
    
    init(book: Book) {
        super.init(nibName: "CatalogViewController", bundle: nil)
        self.mBook = book
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        self.mBook.encodeWithCoder(aCoder)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.mBook = Book(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CatalogCell")
        
        self.tableView.tableFooterView          = UIView()
        self.backBtn.transform                  = CGAffineTransformMakeRotation(CGFloat(M_PI))
        self.mCellSelectedBg                     = UIView()
        self.fetchCatalogBtn.layer.borderWidth  = 1
        self.fetchCatalogBtn.layer.cornerRadius = 8
        
        self.mSqlDB            = Db(db: self.mBook.name, rowable: BookMark())
        self.mCatalogIsFetched = self.mBook.isFetchedCatalog()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.applyTheme()
        
        if self.mCatalogIsFetched {
            self.fetchCatalogBtn.hidden = true
            self.loadingLabel.hidden    = true
            self.emptyTipsView.hidden   = true
        }
    }
    
    @IBAction func onFetchCatalogBtnClicked(sender: AnyObject) {
        self.asyncExtraCatalog()
    }
    
    @IBAction func onBackBtnClicked(sender: AnyObject) {
        if let l = mDismissListener {
            l(false, nil)
        }
    }
    
    @IBAction func onReloadBtnClicked(sender: AnyObject) {
        self.mCatalogIsFetched = false
        self.locatingBookMark()
        self.asyncExtraCatalog()
    }
    
    private func asyncExtraCatalog() {
        self.loadingLabel.alpha     = 0
        self.loadingLabel.hidden    = false
        self.fetchCatalogBtn.alpha  = 1
        self.fetchCatalogBtn.hidden = true
        self.loadingIndicator.startAnimating()
        
        UIView.animateWithDuration(R.AnimInterval.Normal) {
            self.loadingLabel.alpha = 1
            self.fetchCatalogBtn.alpha = 0
        }
        
        Utils.asyncTask({
            self.mSqlDB.open { db in
                db.clear()
                
                let success = db.inTransaction { () -> Bool in
                    // Extracting catalogs
                    let file = fopen(self.mBook.fullFilePath, "r")
                    FileReader().logOff.fetchChaptersOfFile(file, encoding: self.mBook.encoding) { f, c in
                        for ch in c {
                            if ch.range.loc == 0 && ch.title == NO_TITLE {
                                let t = f.fetchRange(file, ch.range, self.mBook.encoding).text
                                if !t.isEmpty {
                                    ch.title = t.componentsSeparatedByString(FileReader.getNewLineCharater(t)).first!
                                }
                            }
                            
                            db.insert(ch)
                        }
                        
                        if !c.isEmpty{
                            Utils.runUITask {
                                if self.mShowFetchingAnimation {
                                    let p = CGFloat(c.last!.range.end) * 100 / CGFloat(self.mBook.size)
                                    self.loadingLabel.text = String(format: "Loading...%.2f", p) + "%"
                                    if !self.loadingIndicator.isAnimating() {
                                        self.loadingIndicator.startAnimating()
                                    }
                                } else if self.loadingIndicator.isAnimating() {
                                    self.loadingIndicator.stopAnimating()
                                }
                            }
                        }
                    }
                    
                    fclose(file)
                    return true
                }
                
                if success {
                    self.mCatalogIsFetched = true
                    self.mBook.setCatalogFetched()
                }
            }
        }) {
            if self.mShowFetchingAnimation {
                self.loadingIndicator.stopAnimating()
            }
            
            if self.locatingBookMark() {
                if self.mShowFetchingAnimation {
                    self.tableView.alpha = 0
                    UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                        self.emptyTipsView.alpha = 0
                        self.tableView.alpha = 1
                    }) { _ in
                        self.emptyTipsView.hidden = true
                        self.emptyTipsView.alpha = 1
                    }
                } else {
                    self.emptyTipsView.hidden = true
                    self.emptyTipsView.alpha = 1
                }
            } else {
                if self.mShowFetchingAnimation {
                    self.fetchCatalogBtn.hidden = false
                    UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                        self.loadingLabel.alpha = 0
                        self.fetchCatalogBtn.alpha = 1
                    }) { _ in self.loadingLabel.hidden = true }
                } else {
                    self.loadingLabel.alpha = 0
                    self.loadingLabel.hidden = true
                    self.fetchCatalogBtn.alpha = 1
                }
            }
            
            self.mShowFetchingAnimation = true
        }
    }

    private func locatingBookMark() -> Bool {
        if self.mCatalogIsFetched {
            let rows = self.mSqlDB.query(true, conditions: "`\(BookMark.Columns.UniqueId)`='\(mCurrChapter.uniqueId)'")
            if rows.count > 0 {
                if self.mCursor == nil {
                    self.mCursor = Db.Cursor(db: self.mSqlDB)
                    if self.mCursor.count() <= 0 {
                        return false
                    }
                }
                
                let rowId = (rows[0] as? BookMark)?.rowId ?? 0
                self.mCursor.moveTo(rowId)
                self.tableView.reloadData()
                self.tableView.scrollToRowAtIndexPath(
                    NSIndexPath(forRow: (rowId ?? 1) - 1, inSection: 0),
                    atScrollPosition: .Middle,
                    animated: false)
                
            }
            
            return true
        } else {
            self.mCursor                 = nil
            self.fetchCatalogBtn.hidden = false
            self.loadingLabel.hidden    = true
            self.emptyTipsView.hidden   = false
            self.tableView.reloadData()
            return false
        }
    }
    
    func syncReaderStatus(currentChapter c: BookMark) {
        self.mCurrChapter = c
        self.locatingBookMark()
    }
    
    func willShow() {
        self.mShowFetchingAnimation = true
    }
    
    func willDismiss() {
        self.mShowFetchingAnimation = false
    }
    
    func applyTheme() {
        self.view.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
        self.titleLabel.textColor = Typesetter.Ins.theme.foregroundColor
        self.backBtn.tintColor = Typesetter.Ins.theme.foregroundColor
        self.mBtnReload.tintColor = Typesetter.Ins.theme.foregroundColor
        self.titleAndTableSplitLine.backgroundColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.1)
        self.tableView.separatorColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.07)
        self.fetchCatalogBtn.tintColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.7)
        self.fetchCatalogBtn.layer.borderColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.4).CGColor
        self.loadingIndicator.color = Typesetter.Ins.theme.foregroundColor.newAlpha(0.7)
        self.loadingLabel.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.7)
        self.mCellSelectedBg.backgroundColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.1)
        self.tableView.reloadData()
    }
    
    func onDismiss(l: (selected: Bool, bm: BookMark?) -> Void) -> CatalogViewController {
        self.mDismissListener = l
        return self
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.mDismissListener != nil {
            mCursor.moveTo(indexPath.row)
            let bm = mCursor.getRow() as? BookMark
            self.mDismissListener(true, bm)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mCursor?.count() ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CatalogCell")!
        
        cell.textLabel!.font = UIFont.systemFontOfSize(R.FontSize.Com_Label)
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.numberOfLines = 4
        cell.selectedBackgroundView = mCellSelectedBg
        
        mCursor.moveTo(indexPath.row)
        let bm = mCursor.getRow() as? BookMark
        cell.textLabel!.text = (bm?.title ?? "Loading")
        
        if bm != nil && bm?.uniqueId == mCurrChapter?.uniqueId {
            cell.textLabel!.textColor = Typesetter.Ins.theme.highlightColor.newAlpha(1)
        } else {
            cell.textLabel!.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.8)
        }
        
        return cell
    }
}
