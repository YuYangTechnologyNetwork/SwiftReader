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

    private var book: Book!
    private var cursor: Db.Cursor!
    private var currChapter: BookMark!
    private var cellSelectedBg: UIView!
    private var onDismissListener: ((Bool, BookMark?) -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CatalogCell")
        backBtn.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        let v = UIView()
        v.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = v
        self.cellSelectedBg = UIView()
        self.fetchCatalogBtn.layer.borderWidth = 1
        self.fetchCatalogBtn.layer.cornerRadius = 8
        self.cursor = Db.Cursor(db: Db(db: self.book.name, rowable: BookMark()))

        if self.cursor.count() <= 0 {
            self.cursor = nil
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.applyTheme()

        if let _ = self.cursor {
            self.fetchCatalogBtn.hidden = true
            self.loadingLabel.hidden = true
            self.emptyTipsView.hidden = true
        }
    }

    @IBAction func onFetchCatalogBtnClicked(sender: AnyObject) {
        asyncExtraCatalog()
    }

    @IBAction func onBackBtnClicked(sender: AnyObject) {
        if let l = onDismissListener {
            l(false, nil)
        }
    }

    private func asyncExtraCatalog() {
        if self.book == nil {
            return
        }

        self.loadingIndicator.startAnimating()
        self.loadingLabel.alpha = 0
        self.loadingLabel.hidden = false
        self.fetchCatalogBtn.alpha = 1
        self.fetchCatalogBtn.hidden = true

        UIView.animateWithDuration(R.AnimInterval.Normal) {
            self.loadingLabel.alpha = 1
            self.fetchCatalogBtn.alpha = 0
        }

        Utils.asyncTask({
            let file = fopen(self.book.fullFilePath, "r")
            Db(db: self.book.name, rowable: BookMark()).clear(true).open {
                db in
                db.inTransaction {
                    () -> Bool in
                    // Extracting catalogs
                    FileReader().logOff.fetchChaptersOfFile(file, encoding: self.book.encoding) {
                        f, c in
                        for ch in c {
                            if ch.range.loc == 0 && ch.title == NO_TITLE {
                                let t = f.fetchRange(file, ch.range, self.book.encoding).text
                                if !t.isEmpty {
                                    ch.title = t.componentsSeparatedByString(FileReader.getNewLineCharater(t)).first!
                                }
                            }

                            db.insert(ch)
                        }

                        if !c.isEmpty {
                            let p = CGFloat(c.last!.range.end) * 100 / CGFloat(self.book.size)
                            let l = String(format: "提取中...%.2f", p) + "%"
                            Utils.runUITask {
                                Utils.Log(l)
                                self.loadingLabel.text = l
                            }
                        }
                    }

                    return true
                }

                self.cursor = Db.Cursor(db: db)
            }

            fclose(file)
        }) {
            if self.cursor != nil {
                self.locatingBookMark {
                    self.loadingIndicator.stopAnimating()

                    if !self.cursor.isEmpty {
                        self.tableView.alpha = 0
                        self.tableView.reloadData()

                        UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                            self.emptyTipsView.alpha = 0
                            self.tableView.alpha = 1
                        }) {
                            _ in self.emptyTipsView.hidden = true
                        }

                        return
                    }
                }
            }

            self.fetchCatalogBtn.hidden = false

            UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                self.loadingLabel.alpha = 0
                self.fetchCatalogBtn.alpha = 1
            }) {
                _ in self.loadingLabel.hidden = true
            }
        }
    }

    private func locatingBookMark(finish: (() -> Void)? = nil) {
        if self.cursor != nil && self.currChapter != nil && self.cursor.count() > 0 {
            let rows = cursor.db.query(
                true,
                conditions: "`\(BookMark.Columns.UniqueId)`='\(currChapter.uniqueId)'",
                tail: ""
            )
            
            if rows.count > 0 {
                let rowId = (rows[0] as? BookMark)?.rowId ?? 0
                
                cursor.moveTo(rowId)
                self.tableView.reloadData()
                
                if let f = finish {
                    f()
                } else {
                    self.tableView.reloadData()
                }
                
                self.tableView.scrollToRowAtIndexPath(
                    NSIndexPath(forRow: (rowId ?? 1) - 1, inSection: 0),
                    atScrollPosition: .Middle,
                    animated: false)
                
            }
        }
    }

    func syncReaderStatus(book: Book, currentChapter c: BookMark) {
        self.book = book
        self.currChapter = c
        self.locatingBookMark()
    }

    func applyTheme() {
        self.view.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
        self.titleLabel.textColor = Typesetter.Ins.theme.foregroundColor
        self.backBtn.tintColor = Typesetter.Ins.theme.foregroundColor
        self.titleAndTableSplitLine.backgroundColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.1)
        self.tableView.separatorColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.07)
        self.fetchCatalogBtn.tintColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.7)
        self.fetchCatalogBtn.layer.borderColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.4).CGColor
        self.loadingIndicator.color = Typesetter.Ins.theme.foregroundColor.newAlpha(0.7)
        self.loadingLabel.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.7)
        self.cellSelectedBg.backgroundColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.1)
        self.tableView.reloadData()
    }

    func onDismiss(l: (selected: Bool, bm: BookMark?) -> Void) -> CatalogViewController {
        self.onDismissListener = l
        return self
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.onDismissListener != nil {
            cursor.moveTo(indexPath.row)
            let bm = cursor.getRow() as? BookMark
            self.onDismissListener(true, bm)
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cursor?.count() ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CatalogCell")!

        cell.textLabel!.font = UIFont.systemFontOfSize(R.FontSize.Com_Label)
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.numberOfLines = 4
        cell.selectedBackgroundView = cellSelectedBg

        cursor.moveTo(indexPath.row)
        let bm = cursor.getRow() as? BookMark
        cell.textLabel!.text = (bm?.title ?? "Loading")

        if bm != nil && bm?.uniqueId == currChapter?.uniqueId {
            cell.textLabel!.textColor = Typesetter.Ins.theme.highlightColor.newAlpha(1)
        } else {
            cell.textLabel!.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.8)
        }

        return cell
    }
}
