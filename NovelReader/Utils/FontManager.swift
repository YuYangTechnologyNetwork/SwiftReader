//
//  FontManager.swift
//  NovelReader
//
//  Created by kangyonggen on 3/30/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class FontManager {

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

    static func isAvailable(fontName: String) -> Bool {
        let aFont = UIFont(name: fontName, size: 10)
        return aFont != nil && (aFont?.fontName == fontName || aFont?.familyName == fontName)
    }

    static func asyncDownloadFont(fontName: String, callback: (Bool, UIFont?, String) -> Void) {
        let attrs = [fontName: kCTFontNameAttribute]
        let descs = [CTFontDescriptorCreateWithAttributes(attrs as CFDictionary)]

        let runInUIThread = { (finish: Bool, font: UIFont?, msg: String) in
            dispatch_async(dispatch_get_main_queue()) {
                callback(finish, font, msg)
            }
        }

        CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs as CFArray, nil) {
            (state: CTFontDescriptorMatchingState, progressParameter: CFDictionaryRef) in

            switch state {
            case .DidFailWithError:
                runInUIThread(true, nil, "Download \(fontName) failed!")
            case .DidFinish:
                let fontRef = CTFontCreateWithName(fontName as CFStringRef, 0, nil)
                let fontUri = CTFontCopyAttribute(fontRef, kCTFontURLAttribute)
                runInUIThread(true, UIFont(name: fontName, size: UIFont.systemFontSize()), String(fontUri))
            default:
                runInUIThread(false, nil, "Downloading")
            }

            return true
        }
    }
}