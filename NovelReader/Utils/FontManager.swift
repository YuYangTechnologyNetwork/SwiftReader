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
	enum SupportFonts: String {
        case System  = "系统字体"
        case Heiti   = "华文黑体"
        case LanTing = "兰亭黑"
        case LiShu   = "隶书"
        case KaiTi   = "楷体"
        case SongTi  = "宋体"

		var postScript: String {
			switch self {
			case .System:
				return UIFont.systemFontOfSize(1).familyName
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

		static var cases: [SupportFonts] {
			return [.System, .SongTi, .LanTing, .KaiTi, .Heiti, .LiShu]
		}
        
		func forSize(size: CGFloat) -> UIFont {
			return UIFont(name: self.postScript, size: size) ?? UIFont.systemFontOfSize(size)
		}
	}

	enum State {
		case Downloading, Finish, Querying, Failure
        
        var completed: Bool {
            return self == .Failure || self == .Finish
        }
	}
    
	private static let StatusMap: [CTFontDescriptorMatchingState: String] = [
			.DidBegin               : "DidBegin",
			.DidFinish              : "DidFinish",
			.WillBeginQuerying      : "WillBeginQuerying",
			.Stalled                : "Stalled",
			.WillBeginDownloading   : "WillBeginDownloading",
			.Downloading            : "Downloading",
			.DidFinishDownloading   : "DidFinishDownloading",
			.DidMatch               : "DidMatch",
			.DidFailWithError       : "DidFailWithError"
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
	static func isAvailable(font: SupportFonts) -> Bool {
		return UIFont(name: font.postScript, size: 1) != nil
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
	static func asyncDownloadFont(font: SupportFonts, callback: (State, SupportFonts, Float) -> Void) {
		let runInUIThread = { (finish: State, font: SupportFonts, progress: Float) in
			dispatch_async(dispatch_get_main_queue()) {
				callback(finish, font, progress)
			}
		}

		if isAvailable(font) {
			runInUIThread(.Finish, font, 1)
			return
		}

		let attrs = NSMutableDictionary(object: font.postScript, forKey: kCTFontNameAttribute as String)
		let descs = NSMutableArray(object: CTFontDescriptorCreateWithAttributes(attrs))

		CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs, nil) { state, paramDict in
			let progress = (paramDict as NSDictionary).objectForKey(kCTFontDescriptorMatchingPercentage)?.floatValue
            var s: State!
            
			switch state {
			case .DidFinish:
				s = .Finish
			case .DidFailWithError:
				s = .Failure
			case .WillBeginDownloading, .Downloading, .DidFinishDownloading:
				s = .Downloading
			default:
				s = .Querying
			}
            
            Utils.Log(StatusMap[state]! + " \(font)")
            runInUIThread(s, font, progress ?? 0)

			return !s.completed
		}
	}
    
	static func tryToLoadAll() {
		for f in SupportFonts.cases {
			FontManager.asyncDownloadFont(f) { s, f, p in }
		}
	}
}