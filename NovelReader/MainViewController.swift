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

        Utils.asyncTask({ () -> Paper in
            let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")
            let book = Book(fullFilePath: filePath!, getInfo: true)!
            let file = fopen(filePath!, "r")
            let reader = FileReader()

            Utils.Log(book)

            let range = NSMakeRange(0, FileReader.BUFFER_SIZE)
            let result = reader.fetchRange(file, range, book.encoding)
            Utils.Log("InOut: \(range)→\(result.1)")

            let paper = Paper(size: CGSizeMake(self.yyLabel.bounds.width, self.yyLabel.bounds.height))
            paper.writingLineByLine(result.0, firstLineIsTitle: false, startWithNewLine: result.1.loc == 0)

            let chapter = reader.fetchChapterAtLocation(file, location: 673484, encoding: book.encoding)
            Utils.Log(chapter)

            //reader.logOff.fetchChaptersOfFile(file, encoding: book.encoding) { f, chapters in
                //for ch in chapters {
                    //Utils.Log(ch)
                //}
            //}

            fclose(file)
            return paper
        }) { paper in
            paper.attachToView(self.yyLabel)
            self.progressIndicator.stopAnimating()
            self.progressIndicator.hidden = true

        }
    }
}
