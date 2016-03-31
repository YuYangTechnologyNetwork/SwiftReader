//
//  MainViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var yyLabel: YYLabel!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.progressIndicator.startAnimating()

        let filePath            = NSBundle.mainBundle().pathForResource("jy_utf8", ofType: "txt")
        let book                = try! Book(fullFilePath: filePath!)

        yyLabel.numberOfLines      = 0
        yyLabel.textColor          = UIColor.blackColor()
        yyLabel.truncationToken    = NSAttributedString(string: "")
        yyLabel.lineBreakMode      = .ByWordWrapping
        yyLabel.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
        //yyLabel.verticalForm       = true

        Typesetter.Ins.addListener("text") { (path: String) in
            print("Typesetter changed(\(path))")
        }.font = FontManager.SupportFonts.LanTing

        let file     = fopen(filePath!, "r")
        let reader   = FileReader()
        let result   = reader.asyncGetChaptersInRange(file, range: NSMakeRange(0, 30960)){ categories in

            FontManager.asyncDownloadFont(Typesetter.Ins.font) { (success: Bool, fontName: String, msg: String) in

                print("Message: \(msg)")

                if success {
                    self.progressIndicator.stopAnimating()
                    self.progressIndicator.hidden = true

                    let content                   = reader.readRange(file, range: NSMakeRange(512, 3096),
                                                                     encoding: FileReader.Encodings[book.encoding]!)

                    let attrText                  = Typesetter.Ins.typeset(content!)
                    self.yyLabel.attributedText   = attrText

                    Typesetter.Ins.line_space     = 10.0


                    /*let visibleRange              = self.yyLabel.textLayout.visibleRange

                     print(visibleRange)

                     let visibAttr = attrText.attributedSubstringFromRange(visibleRange).string
                     
                     print(visibAttr)*/
                    
                    fclose(file)
                    
                    /*print(FontManager.listSystemFonts())*/
                }
            }
        }

        if !result {
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
