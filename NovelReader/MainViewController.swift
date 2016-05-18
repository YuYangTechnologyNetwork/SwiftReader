//
//  MainViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import YYText

class MainViewController: UIViewController {
    
    @IBOutlet weak var yyLabel: YYLabel!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progressIndicator.startAnimating()

        Typesetter.Ins.font       = FontManager.SupportFonts.KaiTi
        Typesetter.Ins.fontSize   = 18
        Typesetter.Ins.line_space = 4
        
        FontManager.asyncDownloadFont(Typesetter.Ins.font) { (_: Bool, _: String, _: String) in
            // Async load book content
            dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
                let filePath = NSBundle.mainBundle().pathForResource("zx_utf8", ofType: "txt")
                let book     = try! Book(fullFilePath: filePath!)
                let file     = fopen(filePath!, "rb+")
                let reader   = FileReader()

                //let chs = reader.chaptersInRange(file, range: NSMakeRange(0, 10 * CHAPTER_SIZE), encoding: FileReader.Encodings[book.encoding]!)

                //for ch in chs {
                    //Utils.Log(ch)
                //}

                Utils.Log(book)

                let range = NSMakeRange(1022, FileReader.BUFFER_SIZE + 2)
                let result = reader.fetchRange(file, range, FileReader.Encodings[book.encoding]!)

                Utils.Log("InOut: \(range)→\(result.1)")

                let paper    = Paper(size: CGSizeMake(self.yyLabel.bounds.width, self.yyLabel.bounds.height))
                paper.writtingLineByLine(result.0, firstLineIsTitle: false, startWithNewLine: result.1.loc == 0)

                fclose(file)
                
                dispatch_async(dispatch_get_main_queue()) {
                    paper.attachToView(self.yyLabel)
                    self.progressIndicator.stopAnimating()
                    self.progressIndicator.hidden = true
                }
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
