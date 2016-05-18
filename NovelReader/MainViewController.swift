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

				reader.asyncGetChaptersOfFile(filePath!, encoding: FileReader.Encodings[book.encoding]!)({ chapters in
					Utils.Log("Chapters count: [\(chapters.count)]")
				})

                let paper    = Paper(size: CGSizeMake(self.yyLabel.bounds.width, self.yyLabel.bounds.height))
                paper.writtingLineByLine(book.description, firstLineIsTitle: false, startWithNewLine: false)
                
                print(book)
                
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
