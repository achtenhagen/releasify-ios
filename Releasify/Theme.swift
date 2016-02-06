//
//  Theme.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/6/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

enum Theme {
	
	case dark, light
	
	func set () -> [String:UIColor] {
		switch self {
		case .dark:
			return [String:UIColor]()
		case .light:
			return [String:UIColor]()
		}
	}
}
