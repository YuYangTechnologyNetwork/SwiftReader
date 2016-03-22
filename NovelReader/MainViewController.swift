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

        let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")

        // print(filePath)

        let file = fopen(filePath!, "r")

        if file != nil {
            var reader = FilerReader()
            var encoding = reader.guessFileEncoding(file)
            let buffer = UnsafeMutablePointer<Int8>.alloc(reader.BUFFER_SIZE)
            var line =  fgets(buffer, 1, file)
            var len:fpos_t
            fgetpos(file, &len)
            var str = NSData(bytes: line, length: len)
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
