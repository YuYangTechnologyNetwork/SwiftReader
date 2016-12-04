//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 4/27/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import SnapKit

class MenuViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var maskPanel: UIView!
    @IBOutlet weak var chapterTitle: UILabel!
    @IBOutlet weak var brightnessMask: UIView!
    @IBOutlet weak var topSubContainer: UIView!
    @IBOutlet weak var btmSubContainer: UIView!
    @IBOutlet weak var loadingBoardMask: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var topActivityIndicatorContainer: UIView!
    @IBOutlet weak var topActivityIndicatorLabel: UILabel!
    @IBOutlet weak var topActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var catalogContainer: UIView!
    @IBOutlet weak var centerTipsLabel: UILabel!
    @IBOutlet weak var mCenterTipsContainer: UIView!

    //    @IBAction func onBackBtnClicked(sender: AnyObject) {
    //    }

    private var size: CGSize {
        return self.view.bounds.size
    }

    private enum DownZone {
        case None
        case Menu
        case Next
        case Prev
    }

    private var mReaderMgr: ReaderManager!
    private var mStylePanelView: StylePanelView!
    private var mJumpPanelView: JumpPanelView!
    private var mVCReader: ReaderViewController!
    private var mVCCatalog: CatalogViewController!
    private var mStyleFontsListView: StyleFontsPickerView!
    
    private var mIsMenuShow: Bool   = false
    private var mIsNeedReload: Bool = false
    private var mDownZone: DownZone = .None
    private var mIsBookLoaded: Bool = false
    
    private let STYLE_PANEL_HEIGHT  = R.MenuView.StylePanelHeight
    private let JUMP_PANEL_HEIGHT   = R.MenuView.JumpPanelHeight

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let styleMenuRect = CGRectMake(0, 0, self.view.bounds.width, STYLE_PANEL_HEIGHT)
        self.mStylePanelView = StylePanelView(frame: styleMenuRect).onShowFontsList {
            self.showFontsList()
        }

        self.mStyleFontsListView = StyleFontsPickerView(frame: styleMenuRect).onFontsChanged { changed, font in
            if changed && Typesetter.Ins.font != font {
                self.hideMenu {
                    let shouldReload = self.mIsNeedReload
                    self.mIsNeedReload = false
                    self.topActivityIndicator.startAnimating()
                    self.topActivityIndicatorContainer.hidden = false
                    FontManager.asyncDownloadFont(font) { s, f, p in
                        if s == FontManager.State.Downloading {
                            let l = "Downloading \(font) \(p)%"
                            self.topActivityIndicatorLabel.text = l
                            Utils.Log(l)
                        } else if s.completed {
                            self.topActivityIndicator.stopAnimating()
                            self.topActivityIndicatorContainer.hidden = true
                            if s == FontManager.State.Finish {
                                Typesetter.Ins.font = font
                            } else if shouldReload {
                                self.reloadReader(true)
                            }
                        } else {
                            self.topActivityIndicatorLabel.text = "Querying \(font)"
                        }
                    }
                }
            } else {
                self.hideMenu()
            }
        }
        
        self.mJumpPanelView = JumpPanelView(frame: CGRectMake(0, 0, self.view.bounds.width, JUMP_PANEL_HEIGHT))
            .setJumpActionListener { type in
                self.showCenterTips(nil)
                if self.mReaderMgr.jumpTo(type) {
                    self.reloadReader()
                } else {
                    self.refreshReaderStatus(self.mReaderMgr.currentChapter, withBlink: false)
                    self.hideMenu()
                }
            }
            .setSliderValueMonitor { v in
                self.showCenterTips(String(format: "%.2f", v * 100) + "%")
        }
        
        self.mCenterTipsContainer.layer.cornerRadius  = 10
        self.mCenterTipsContainer.layer.opacity       = 1
        self.mCenterTipsContainer.backgroundColor     = UIColor.blackColor()
        self.mCenterTipsContainer.alpha               = 0.8
        self.centerTipsLabel.textColor                = UIColor.whiteColor()
        self.centerTipsLabel.font                     = UIFont.systemFontOfSize(15)
        
        self.btmSubContainer.addSubview(mStyleFontsListView)
        self.btmSubContainer.addSubview(mStylePanelView)
        self.btmSubContainer.addSubview(mJumpPanelView)

        self.mStylePanelView.hidden          = true
        self.mStyleFontsListView.hidden      = true
        self.mJumpPanelView.hidden           = true
        self.loadingBoardMask.hidden        = !Typesetter.Ins.theme.boardMaskNeeded
        self.topActivityIndicator.transform = CGAffineTransformMakeScale(0.5, 0.5)

        Typesetter.Ins.addListener("MenuListener") { observer, oldValue in
            switch (observer) {
            case .Theme:
                self.hideMenu { self.applyTheme() }
            case .Brightness:
                self.brightnessMask.alpha  = 1 - Typesetter.Ins.brightness
                self.brightnessMask.hidden = Typesetter.Ins.brightness == 1
            case .Font:
                self.reloadReader(false)
            default:
                if let reader = self.mVCReader {
                    reader.applyFormat()
                }
                self.mIsNeedReload = true
                break
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        // Start loading
        self.loadingIndicator.startAnimating()
    
        Utils.asyncTask({ () -> Book? in
            let bookPath = NSBundle.mainBundle().pathForResource(Config.BuiltInBook, ofType: "txt")
            if let bPath = bookPath {
                var book = Book(fullFilePath: bPath, getInfo: true)
                
                if let b = book {
                    Utils.Log(b.description)
                    Db(db: Config.Db.DefaultDB, rowable: b).open { db in
                        let books     =  db.query(false,  conditions: "`\(Book.Columns.UniqueId)`='\(b.uniqueId)'")
                        let savedBook = books.count > 0 ? books[0] as? Book : nil
                        
                        if let sb = savedBook {
                            if !b.mIsBunltIn {
                                book = Book(otherBook: sb)
                            } else {
                                book!.bookMark     = sb.bookMark
                                book!.lastOpenTime = sb.lastOpenTime
                            }
                        } else {
                            Utils.Log(db.lastExecuteInfo)
                        }
                    }
                    
                    return book!
                }
            }
            
            return nil
        }) { book in
            if let b = book {
                self.mIsBookLoaded = true
                self.mReaderMgr = ReaderManager(b: b, size: self.view.frame.size)
                
                self.mReaderMgr.addListener("MenuTitle", forMonitor: .ChapterChanged) { chapter in
                    self.chapterTitle.text = chapter.title
                    self.mVCCatalog.syncReaderStatus(currentChapter: chapter)
                }
                
                self.mReaderMgr.asyncLoading { chapter in
                    self.attachReaderView(chapter)
                    self.chapterTitle.text = chapter.title
                    self.mVCCatalog.syncReaderStatus(currentChapter: chapter)
                }
            } else {
                self.loadingIndicator.stopAnimating()
                self.showCenterTips("Open book failure!")
            }
        }

        self.mStylePanelView.snp_makeConstraints { make in
            make.height.equalTo(self.STYLE_PANEL_HEIGHT)
            make.top.equalTo(self.btmSubContainer.snp_top)
            make.left.equalTo(self.btmSubContainer.snp_left)
            make.width.equalTo(self.btmSubContainer.snp_width)
        }

        self.mStyleFontsListView.snp_makeConstraints { make in
            make.height.equalTo(self.STYLE_PANEL_HEIGHT)
            make.top.equalTo(self.btmSubContainer.snp_top)
            make.left.equalTo(self.btmSubContainer.snp_left)
            make.width.equalTo(self.btmSubContainer.snp_width)
        }
        
        self.mJumpPanelView.snp_makeConstraints { make in
            make.height.equalTo(self.JUMP_PANEL_HEIGHT)
            make.left.equalTo(self.btmSubContainer.snp_left)
            make.width.equalTo(self.btmSubContainer.snp_width)
            make.bottom.equalTo(self.btmSubContainer.snp_bottom)
        }

        self.applyTheme()
    }

    override func prefersStatusBarHidden() -> Bool {
        return !mIsMenuShow
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return Typesetter.Ins.theme == Theme.Night ? UIStatusBarStyle.LightContent : UIStatusBarStyle.Default
    }
    
    private func refreshReaderStatus(c: BookMark, withBlink: Bool = true) {
        self.mVCReader.loadPapers(withBlink)
        self.brightnessMask.userInteractionEnabled = false
        self.chapterTitle.text = c.title
        self.mVCCatalog?.syncReaderStatus(currentChapter: self.mReaderMgr.currentChapter)
    }

    private func reloadReader(withBlink: Bool = true, limit: Bool = false) {
        if self.mReaderMgr != nil {
            self.brightnessMask.userInteractionEnabled = true
            self.loadingIndicator.startAnimating()

            self.mReaderMgr.asyncLoading(limit) { c in
                self.refreshReaderStatus(c, withBlink: withBlink)
                self.loadingIndicator.stopAnimating()
            }
        }
    }
    
    private func showCenterTips(text: String?) {
        if let s = text {
            self.mCenterTipsContainer.hidden = false
            self.centerTipsLabel.text = s
        } else {
            self.mCenterTipsContainer.hidden = true
            self.centerTipsLabel.text = ""
        }
    }
    
    private func applyTheme() {
        self.topBar.tintColor                    = Typesetter.Ins.theme.foregroundColor
        self.bottomBar.tintColor                 = Typesetter.Ins.theme.foregroundColor
        self.view.backgroundColor                = Typesetter.Ins.theme.backgroundColor
        self.brightnessMask.alpha                = 1 - Typesetter.Ins.brightness
        self.brightnessMask.hidden               = Typesetter.Ins.brightness == 1
        self.chapterTitle.textColor              = Typesetter.Ins.theme.foregroundColor
        self.loadingIndicator.color              = Typesetter.Ins.theme.foregroundColor
        self.topBar.backgroundColor              = Typesetter.Ins.theme.menuBackgroundColor
        self.bottomBar.backgroundColor           = Typesetter.Ins.theme.menuBackgroundColor
        self.topActivityIndicator.color          = Typesetter.Ins.theme.foregroundColor.newAlpha(0.5)
        self.topActivityIndicatorLabel.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.5)

        if let rvc = self.mVCReader {
            rvc.applyTheme()
        }

        if mVCCatalog != nil {
            mVCCatalog.applyTheme()
        }
    }
    
    private func attachReaderView(currChapter: Chapter) {
        chapterTitle.text   = currChapter.title
        mVCReader            = ReaderViewController(nibName: "ReaderViewController", bundle: nil)
        mVCReader.readerMgr  = self.mReaderMgr
        mVCReader.view.frame = self.view.frame
        mVCReader.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.maskTaped(_:))))

        loadingIndicator.stopAnimating()
        addChildViewController(self.mVCReader)
        view.addSubview(self.mVCReader.view)
        view.sendSubviewToBack(self.mVCReader.view)

        if !loadingBoardMask.hidden {
            UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                self.loadingBoardMask.alpha  = 0
            }) { end in
                self.loadingBoardMask.hidden = true
                self.loadingBoardMask.alpha  = 1
            }
        }

        mVCCatalog = CatalogViewController(book: self.mReaderMgr.book)
        mVCCatalog.view.frame = catalogContainer.frame
        mVCCatalog.onDismiss { selected, bm in
            self.dismissCatalog {
                if selected {
                    if bm != self.mReaderMgr.currentChapter {
                        if let b = bm {
                            Utils.Log("Jump to \(b)")
                            self.mReaderMgr.book.bookMark = b
                            self.reloadReader(false, limit: true)
                        }
                    }
                }
            }
        }
        
        catalogContainer.onClick { v in
            if self.mIsMenuShow {
                self.hideMenu()
            } else {
                self.dismissCatalog()
            }
        }

        addChildViewController(mVCCatalog)
        catalogContainer.addSubview(mVCCatalog.view)

        mVCCatalog.view.snp_makeConstraints { make in
            make.top.equalTo(self.catalogContainer.snp_top)
            make.left.equalTo(self.catalogContainer.snp_left)
            make.width.equalTo(self.size.width * 5 / 6)
            make.height.equalTo(self.catalogContainer.snp_height)
        }
    }

    func maskTaped(recognizer: UITapGestureRecognizer) {
        if !self.mIsBookLoaded {
            Utils.Log("Bool load failure!")
            return
        }
        
        let point = recognizer.locationInView(maskPanel)

        if !mIsMenuShow && self.catalogContainer.hidden {
            if inMenuRegion(point) {
                showMenu()
            } else if inNextRegion(point) {
                mVCReader.snapToNextPage()
            } else if inPrevRegion(point) {
                mVCReader.snapToPrevPage()
            }
        } else {
            if mIsMenuShow {
                hideMenu()
            } else {
                dismissCatalog()
            }
        }
    }

    private func inMenuRegion(p: CGPoint) -> Bool {
        return size.width / 3 < p.x && p.x < size.width * 2 / 3 && size.height / 3 < p.y && p.y < size.height * 2 / 3
    }

    private func inNextRegion(p: CGPoint) -> Bool {
        return (size.width * 2 / 3 <= p.x) || (size.width / 3 < p.x && size.height * 2 / 3 <= p.y)
    }

    private func inPrevRegion(p: CGPoint) -> Bool {
        return (p.x <= size.width / 3) || (p.x < size.width * 2 / 3 && p.y <= size.height / 3)
    }

    private func showMenu() {
        self.topBar.frame.origin.y    = -self.topBar.bounds.height
        self.bottomBar.frame.origin.y = self.size.height
        self.maskPanel.alpha          = 0.0
        self.topSubContainer.alpha    = 0.0

        self.mIsMenuShow                 = true
        self.topBar.hidden            = false
        self.bottomBar.hidden         = false
        self.maskPanel.hidden         = false
        
        UIView.animateWithDuration(R.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y    = 0
            self.maskPanel.alpha          = 0.25
            self.topSubContainer.alpha    = 1.0
            self.bottomBar.frame.origin.y = self.size.height - self.bottomBar.bounds.height
        }) { finish in }
    }

    private func hideMenu(animationCompeted:(()->Void)? = nil ) {
        self.mIsMenuShow = false
        self.btmSubContainer.userInteractionEnabled = false
        
        UIView.animateWithDuration(R.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y          = -self.topBar.bounds.height
            self.bottomBar.frame.origin.y       = self.size.height
            self.btmSubContainer.frame.origin.y = self.size.height
            self.maskPanel.alpha                = 0
            self.topSubContainer.alpha          = 0
            self.bottomBar.alpha                = 1
            self.btmSubContainer.alpha          = 0
        }) { finish  in
            self.mStylePanelView.frame.origin.x  = 0
            self.topBar.hidden                  = true
            self.bottomBar.hidden               = true
            self.maskPanel.hidden               = true
            self.mStylePanelView.hidden          = true
            self.btmSubContainer.hidden         = true
            self.mStyleFontsListView.hidden      = true
            self.mJumpPanelView.hidden           = true
            
            if let end = animationCompeted { end() }
            
            if self.mIsNeedReload {
                self.mIsNeedReload = false
                self.reloadReader()
            }
        }
    }
    
    @IBAction func onStyleBtnClicked(sender: AnyObject) {
        self.mStylePanelView.hidden                 = false
        self.btmSubContainer.hidden                 = false
        self.btmSubContainer.frame.origin.y         = self.size.height
        self.btmSubContainer.userInteractionEnabled = true
        
        self.mStylePanelView.applyTheme()
        self.mStyleFontsListView.applyTheme()
        
        UIView.animateWithDuration(R.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.setNeedsStatusBarAppearanceUpdate()
            self.bottomBar.alpha                = 0
            self.btmSubContainer.alpha          = 1
            self.btmSubContainer.frame.origin.y = self.size.height - self.STYLE_PANEL_HEIGHT
        }) { finish in }
    }

    @IBAction func onCatalogBtnClicked(sender: AnyObject) {
        self.hideMenu { self.showCatalog() }
    }

    @IBAction func onJumpBtnClicked(sender: AnyObject) {
        self.mJumpPanelView.hidden                 = false
        self.btmSubContainer.hidden               = false
        self.btmSubContainer.frame.origin.y       = self.size.height
        self.btmSubContainer.userInteractionEnabled = true
        
        self.mJumpPanelView.applyTheme()
        self.mJumpPanelView.setNowProgress(mReaderMgr.book.currentPrecent)
        
        UIView.animateWithDuration(R.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.setNeedsStatusBarAppearanceUpdate()
            self.bottomBar.alpha                = 0
            self.btmSubContainer.alpha          = 1
            self.btmSubContainer.frame.origin.y = self.size.height - self.JUMP_PANEL_HEIGHT
        }) { finish in }
    }

    private func showFontsList() {
        self.mStyleFontsListView.frame.origin.x = self.size.width
        self.mStyleFontsListView.hidden = false
        
        UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
            self.mStylePanelView.frame.origin.x = -self.size.width
            self.mStyleFontsListView.frame.origin.x = 0
        }) { finish in }
    }

    private func showCatalog() {
        if mVCCatalog != nil {
            self.maskPanel.hidden = false
            self.catalogContainer.hidden = false
            self.catalogContainer.frame.origin.x = -self.mVCCatalog.view.frame.width
            UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                self.maskPanel.alpha = 0.6
                self.catalogContainer.frame.origin.x = 0
            }) { finish in
                self.mVCCatalog.willShow()
            }
        }
    }
    
    private func dismissCatalog(end: (()->Void)? = nil) {
        if mVCCatalog != nil {
            self.mVCCatalog.willDismiss()
            self.catalogContainer.frame.origin.x = 0
            self.brightnessMask.userInteractionEnabled = true
            
            UIView.animateWithDuration(R.AnimInterval.Normal, animations: {
                self.catalogContainer.frame.origin.x = 0
                self.maskPanel.alpha = 0
                self.catalogContainer.frame.origin.x = -self.mVCCatalog.view.frame.width
            }) { finish in
                self.brightnessMask.userInteractionEnabled = false
                self.catalogContainer.hidden = true
                self.maskPanel.hidden = true
                
                if let e = end {
                    e()
                }
            }
        }
    }
}
