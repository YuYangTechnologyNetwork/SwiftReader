//
//  MainViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var uiLabel: UILabel!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let workingQueue = dispatch_queue_create("my_queue", nil)
        self.progressIndicator.startAnimating()

        // 派发到刚创建的队列中，GCD 会负责进行线程调度
        dispatch_async(workingQueue) {
            let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")
            let file     = fopen(filePath!, "r")

            if file != nil {
                let reader   = FileReader()
                let encodingStr = reader.guessFileEncoding(file)

                if reader.isSupportEncding(encodingStr) {
                    let ecnoding = FileReader.Encodings[encodingStr]!
                    let fileSize = reader.getFileSize(file)
                    var location = 0
                    repeat {
                        let start = reader.getWordBorder(file, fuzzyPos: location, encoding: ecnoding)
                        let end = reader.getWordBorder(file, fuzzyPos: start + FileReader.BUFFER_SIZE, encoding: ecnoding)
                        let length = end - start

                        if length > 0 {
                            let categories = reader.getCategories(file, range: NSMakeRange(start, length), encoding: ecnoding)
                            if categories.count > 0 {
                                for category in categories {
                                    print(category.0)
                                }
                            }

                            location = end
                        }
                    } while (location < fileSize)
                }
                
                fclose(file)
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.progressIndicator.stopAnimating()
                self.progressIndicator.hidden = true
                self.uiLabel.hidden = false
            }
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
