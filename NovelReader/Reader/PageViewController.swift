//
//  PageViewController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import YYText

class PageViewController: UIViewController {
	@IBOutlet weak var containerView: YYLabel!
	@IBOutlet weak var boardMaskView: UIImageView!
    @IBOutlet weak var bufferContainerView: YYLabel!

	private var paper: Paper?
    private var needRefresh: Bool    = true
    private var _index: Int          = 0
    private var dispalyWithAnimation = false

	var index: Int {
		return _index
	}

	override func viewDidLoad() {
        containerView.textVerticalAlignment        = .Top
        containerView.ignoreCommonProperties       = true
        bufferContainerView.textVerticalAlignment  = .Top
        bufferContainerView.ignoreCommonProperties = true
        boardMaskView.alpha                        = Typesetter.Ins.theme.boardMaskNeeded ? 1 : 0
		applyTheme(false)
	}

	override func viewWillAppear(animated: Bool) {
		if self.needRefresh {
			needRefresh = false
			if let p = self.paper {
				p.attachToView(containerView)
                
				if dispalyWithAnimation {
                    dispalyWithAnimation = false
                    containerView.alpha  = 0
                    
					UIView.animateWithDuration(0.3) {
						self.containerView.alpha = 1
					}
				}
			}
		}
	}

	func index(index: Int) -> PageViewController {
		_index = index
		return self
	}

    func applyTheme(withAnim: Bool = true) {
        if let c = self.containerView {
            if let p = paper {
                p.attachToView(c)
            }
        }

        let cT = Typesetter.Ins.theme
        let oT = Typesetter.Ins.oldTheme

        var notParchemnt = true
        if cT == Theme.Night || oT == Theme.Night {
            notParchemnt = true
        } else {
            notParchemnt = oT != .Parchment && cT != .Parchment
        }

        if withAnim && notParchemnt {
            UIView.animateWithDuration(0.3) {
                if cT == .Night && oT != nil {
                    self.view.backgroundColor = oT!.menuBackgroundColor
                }

                if let mask = self.boardMaskView {
                    mask.alpha = Typesetter.Ins.theme.boardMaskNeeded ? 1 : 0
                }

                self.view.backgroundColor = Typesetter.Ins.theme.backgroundColor
            }
        } else {
            self.view.backgroundColor = Typesetter.Ins.theme.backgroundColor
            if let mask = self.boardMaskView {
                UIView.animateWithDuration(0.3) {
                    mask.alpha = Typesetter.Ins.theme.boardMaskNeeded ? 1 : 0
                }
            }
        }
    }
    
    func applyFormat() {
        if let p = self.paper {
            if let c = containerView {
                p.attachToView(c, reTypesetting: true)
            }
        }
    }

	func bindPaper(paper: Paper?, doAnimation: Bool = false) -> PageViewController? {
		if let p = paper {
			if p != self.paper {
                let lp     = self.paper
                self.paper = p
				if let c = self.containerView {
					if doAnimation {
                        if let l = lp {
                            containerView.textLayout = nil
                            l.attachToView(bufferContainerView)
                        }
                        
                        bufferContainerView.alpha = 1
                        containerView.alpha       = 0
                        p.attachToView(c)

						UIView.animateWithDuration(0.3) {
                            self.containerView.alpha       = 1
                            self.bufferContainerView.alpha = 0
						}
					} else {
						p.attachToView(containerView)
					}
				} else {
					self.needRefresh = true
                    self.dispalyWithAnimation = doAnimation
				}
			}

			return self
		} else {
			if let c = containerView {
				c.textLayout = nil
			}

			self.paper = nil

			return nil
		}
	}
}