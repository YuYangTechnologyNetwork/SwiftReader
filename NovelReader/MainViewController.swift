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

        self.progressIndicator.startAnimating()

        let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")
        let book     = try! Book(fullFilePath: filePath!)
        uiLabel.text = book.description

        let file     = fopen(filePath!, "r")
        let reader   = FileReader()
        let result   = reader.asyncGetChapters(file){ categories in
            self.progressIndicator.stopAnimating()
            self.progressIndicator.hidden = true
            self.uiLabel.hidden = false
            fclose(file)
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
