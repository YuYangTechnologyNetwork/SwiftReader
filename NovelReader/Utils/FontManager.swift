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
    enum SupportFonts:String {
        case System  = "系统字体"
        case Heiti   = "华文黑体"
        case LanTing = "兰亭黑  "
        case LiShu   = "隶书    "
        case KaiTi   = "楷体    "
        case SongTi  = "宋体    "
        
		var postScript: String {
			switch self {
			case .System:
				return "Helvetica-Light"
			case .Heiti:
				return "STHeitiTC-Light"
			case .KaiTi:
				return "STKaiti-SC-Regular"
			case .LanTing:
				return "FZLTXHK--GBK1-0"
			case .LiShu:
				return "STLibian-SC-Regular"
			case .SongTi:
				return "STSongti-SC-Regular"
			}
		}
    }
    
    enum State {
        case Downloading, Success, Failure, Matched
    }

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
     * Download apple listed support fonts.
     * [Ref]: http://developer.applae.com/.../DownloadFont
     * [Ref]: https://support.apple.com/en-us/HT202771
     *
     * @param fontName      The font postscript name. What's the postscript name? Searching with Google
     *
     * @param callback      The downloading callback, will be called on main-thread
     */
    static func asyncDownloadFont(font: SupportFonts, callback: (State, String, String?) -> Void) {
        let pname = font.postScript

        let runInUIThread = { (finish: State, font:String, msg: String?) in
            dispatch_async(dispatch_get_main_queue()) {
                callback(finish, font, msg)
            }
        }

        if isAvailable(pname) {
            runInUIThread(.Matched, pname, nil)
            return
        }

        let attrs = NSMutableDictionary(object: pname, forKey: kCTFontNameAttribute as String)
        let descs = NSMutableArray(object: CTFontDescriptorCreateWithAttributes(attrs))

        CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil) { state, paramDict in
            let progress = (paramDict as NSDictionary).objectForKey(kCTFontDescriptorMatchingPercentage)?.doubleValue
            
            switch state {
            case .DidBegin:
                Utils.Log("Begin Matching")
            case .DidFailWithError:
                runInUIThread(State.Failure , pname, nil)
            case .WillBeginDownloading:
                runInUIThread(State.Downloading, pname, "\(progress)")
            case .DidFinishDownloading:
                runInUIThread(State.Downloading, pname, "\(progress)")
            case .WillBeginQuerying:
                Utils.Log("Begin querying")
            case .Stalled:
                Utils.Log("Stalled")
            case .Downloading:
                runInUIThread(State.Downloading, pname, "\(progress)")
            case .DidMatch:
                runInUIThread(State.Matched, pname, nil)
            case .DidFinish:
                runInUIThread(State.Success, pname, nil)
            }

            return true
        }
    }
}