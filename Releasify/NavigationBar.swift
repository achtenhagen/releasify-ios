//
//  NavigationBar.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/5/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {

	private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	private var theme: NavigationBarTheme!

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		// Safeguard against initial nil value
		// (presumably due to AppController being initial view controller in storyboard)
		guard let appDelegateTheme = appDelegate.theme else { return }
		theme = NavigationBarTheme(style: appDelegateTheme.style)
		self.barStyle = theme.navBarStyle
		self.barTintColor = theme.navBarTintColor
		if theme.style == .Dark {
			self.shadowImage = UIImage()
		} else {
			self.shadowImage = UIImage(named: "navbar_shadow")
		}
		self.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		self.tintColor = theme.navTintColor
		self.titleTextAttributes = [NSForegroundColorAttributeName: theme.navTextColor]
		self.translucent = false
	}
}

// Theme Subclass
private class NavigationBarTheme: Theme {
	var navBarStyle: UIBarStyle!
	var navBarTintColor: UIColor!
	var navTintColor: UIColor!
	var navTextColor: UIColor!

	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			navBarStyle = .Black
			navBarTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
			navTintColor = globalTintColor
			navTextColor = globalTintColor
		case .Light:
			navBarStyle = .Default
			navBarTintColor = UIColor.whiteColor()
			navTintColor = globalTintColor
			navTextColor = globalTintColor
		}
	}
}
