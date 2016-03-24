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

        // Do any additional setup after loading the view.

        let filePath = NSBundle.mainBundle().pathForResource("jy_utf8", ofType: "txt")

        // print(filePath)

        let file = fopen(filePath!, "r")

        if file != nil {
            let reader = FileReader()
            let encoding = reader.guessFileEncoding(file)
            let start = reader.getWordBorder(file, fuzzyPos: 11, encoding: FileReader.Encodings[encoding]!)
            let end = reader.getWordBorder(file, fuzzyPos: 127, encoding: FileReader.Encodings[encoding]!)

            print("Range -> (\(start) - \(end))")

            let len = end - start
            let buffer = UnsafeMutablePointer<UInt8>.alloc(len)
            fseek(file, start, SEEK_SET)
            let _ = fread(buffer, 1, len, file)
            let data = NSData(bytes: buffer, length: len)
            print(String(data: data, encoding: NSUTF8StringEncoding))
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
