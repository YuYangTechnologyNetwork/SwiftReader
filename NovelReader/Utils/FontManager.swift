//
//  FontManager.swift
//  NovelReader
//
//  Created by kangyonggen on 3/30/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

final class FontManager {

    // Supported Fonts
    enum SupportFonts {
        case System
        case Heiti
        case LanTing
        case LiShu
        case KaiTi
        case SongTi
    }

    // Define support fonts properties:  [Index : (PostScript Name, Chinese Name)]
    private static let PostScriptNameTable = [
        SupportFonts.System  : ("Helvetica-Light", "系统字体"),
        SupportFonts.LanTing : ("FZLTXHK--GBK1-0", "兰亭黑"),
        SupportFonts.Heiti   : ("STHeitiTC-Light", "华文黑体"),
        SupportFonts.KaiTi   : ("STKaiti-SC-Regular", "楷体"),
        SupportFonts.LiShu   : ("STLibian-SC-Regular", "隶书"),
        SupportFonts.SongTi  : ("STSongti-SC-Regular", "宋体")
    ]

    /*
     * List all installed font
     *
     * @return Dictionary   [Family:[FontName...]]
     */
    static func listSystemFonts() -> [String: [String]] {
        var fontList: [String: [String]] = ["": [""]]

        for family in UIFont.familyNames() {
            fontList["'\(family)"] = []
            for name in UIFont.fontNamesForFamilyName(family) {
                fontList["'\(family)"]?.append(name)
            }
        }

        return fontList
    }

    /*
     * Check the special font installtion is or not installed
     *
     * @return Bool
     */
    static func isAvailable(fontName: String) -> Bool {
        let aFont = UIFont(name: fontName, size: 10)
        return aFont != nil && (aFont?.fontName == fontName || aFont?.familyName == fontName)
    }

    /*
     * Get the font name for Enum.SupportFonts
     *
     * @param font      See FontManager.SupportFonts
     *
     * @return String   If font illegal, system font name will be returned
     */
    static func getFontName(font: SupportFonts) -> String{
        if PostScriptNameTable.indexForKey(font) != nil {
            return PostScriptNameTable[font]!.0
        }

        return PostScriptNameTable[SupportFonts.System]!.0
    }

    /*
     * Download apple listed support fonts.
     * [Ref]: http://developer.applae.com/.../DownloadFont
     * [Ref]: https://support.apple.com/en-us/HT202771
     *
     * @param fontName      The font postscript name. What's the postscript name? Searching with Google
     *
     * @param callback      The downloading callback, will be called on main-thread
     */
    static func asyncDownloadFont(font: SupportFonts, callback: (Bool, String, String) -> Void) {
        let pname = getFontName(font)

        let runInUIThread = { (finish: Bool, font:String, msg: String) in
            dispatch_async(dispatch_get_main_queue()) {
                callback(finish, font, msg)
            }
        }

        if isAvailable(pname) {
            runInUIThread(true, pname, pname)
            return
        }

        let attrs = NSMutableDictionary(object: pname, forKey: kCTFontNameAttribute as String)
        let descs = NSMutableArray(object: CTFontDescriptorCreateWithAttributes(attrs))


        CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil) {
            (state: CTFontDescriptorMatchingState, paramDict: CFDictionaryRef) in

            switch state {
            case .DidBegin:
                Utils.Log("Begin Matching")
            case .DidFailWithError:
                runInUIThread(true, pname, "Download \(pname) failed!")
            case .WillBeginDownloading:
                Utils.Log("Begin dowloading")
            case .DidFinishDownloading:
                Utils.Log("Finish downloading")
            case .WillBeginQuerying:
                Utils.Log("Begin querying")
            case .Stalled:
                Utils.Log("Stalled")
            case .Downloading:
                Utils.Log("Downloading")
            case .DidMatch:
                Utils.Log("Finish Matching")
            case .DidFinish:
                runInUIThread(true, pname, pname)
            }

            return true
        }
    }
}