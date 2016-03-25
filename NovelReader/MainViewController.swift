//
//  MainViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")
        let file     = fopen(filePath!, "r")

        if file != nil {
            let reader   = FileReader()
            let encoding = reader.guessFileEncoding(file)

            if reader.isSupportEncding(encoding) {
                let start  = reader.getWordBorder(file, fuzzyPos: 6257902, encoding: FileReader.Encodings[encoding]!)
                let end    = reader.getWordBorder(file, fuzzyPos: 6258004, encoding: FileReader.Encodings[encoding]!)
                let len    = end - start
                let buffer = UnsafeMutablePointer<UInt8>.alloc(len)

                fseek(file, start, SEEK_SET)
                fread(buffer, 1, len, file)

                print("File Size: \(reader.getFileSize(file))")
                print("Range -> (\(start) - \(end))")
                print(String(data: NSData(bytes: buffer, length: len), encoding: FileReader.Encodings[encoding]!))
            }

            fclose(file)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
