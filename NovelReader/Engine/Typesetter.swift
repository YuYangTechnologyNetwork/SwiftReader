//
//  Typesetter.swift
//  NovelReader
//
//  Created by kang on 3/14/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

public class Typesetter: NSObject {
    struct Margin {
		var top: Int? , left : Int? , right : Int? , bottom : Int?
	}

	var font_size : CGFloat?
	var font_family : String?
	var line_space : CGFloat?

	override init()
	{
        font_size   = 12.6
        font_family = ""
        line_space  = 8
	}

	init(config : String)
	{
        
	}
}
