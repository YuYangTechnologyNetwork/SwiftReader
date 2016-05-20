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

        FontManager.asyncDownloadFont(Typesetter.Ins.font) { (_: Bool, _: String, _: String) in
            Utils.asyncTask { () -> Paper in
                let filePath = NSBundle.mainBundle().pathForResource("zx_utf8", ofType: "txt")
                let book     = try! Book(fullFilePath: filePath!)
                let file     = fopen(filePath!, "r")
                let reader   = FileReader()
                let encoding = FileReader.Encodings[book.encoding]!

                Utils.Log(book)

                let range    = NSMakeRange(0, FileReader.BUFFER_SIZE)
                let result   = reader.fetchRange(file, range, encoding)
                Utils.Log("InOut: \(range)→\(result.1)")

                let paper    = Paper(size: CGSizeMake(self.yyLabel.bounds.width, self.yyLabel.bounds.height))
                paper.writtingLineByLine(result.0, firstLineIsTitle: false, startWithNewLine: result.1.loc == 0)

                let location = 4680//382
                let chapter  = reader.fetchChapterAtLocation(file, location: location, encoding: encoding)
                Utils.Log("Chapter: \(chapter!) at loc: \(location)")

                reader.logOff.fetchChaptersOfFile(file, encoding: encoding) { chapters in
                    for ch in chapters {
                        Utils.Log(ch)
                    }
                }

                fclose(file)
                return paper
            }(onMain: { paper in
                paper.attachToView(self.yyLabel)
                self.progressIndicator.stopAnimating()
                self.progressIndicator.hidden = true

                
            })
        }
    }
}
