//
//  Theme.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/6/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

public class Theme {
	
	enum Styles { case Dark, Light }
	
	var style: Styles = .Dark
	
	// Global App tint color
	var globalTintColor: UIColor!
	
	// Common colors
	let blueColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)				  // #00D8FF
	let greenColor = UIColor(red: 0, green: 242/255, blue: 192/255, alpha: 1)		  // #00F2C0
	let greenAltColor = UIColor(red: 0, green: 216, blue: 151, alpha: 1)			  // #00D897
	let redColor = UIColor(red: 1, green: 40/255, blue: 81/255, alpha: 1)			  // #FF2851
	let orangeColor = UIColor(red: 1, green: 85/255, blue: 80/255, alpha: 1)		  // #FF5550
	let orangeAltColor = UIColor(red: 248/255, green: 65/255, blue: 48/255, alpha: 1) // #F84130
	
	// Status bar appearance
	var statusBarStyle: UIStatusBarStyle!

	// Navigation bar appearance
	var navBarStyle: UIBarStyle!
	var navBarTintColor: UIColor!
	var navTintColor: UIColor!
	var navTextColor: UIColor!
	
	// Search bar appearance
	var searchBarStyle: UIBarStyle!
	var searchBarTintColor: UIColor!
	
	// Tab bar appearance
	var tabTintColor: UIColor!
	var tabBarTintColor: UIColor!
	
	// Tab bar top border color
	var tabBarTopBorderColor: UIColor!
	
	// Keyboard appearance
	var keyboardStyle: UIKeyboardAppearance!
	
	// Refresh control appearance
	var refreshControlTintColor: UIColor!

	// Table view appearance
	var tableViewBackgroundColor: UIColor!
	var cellHighlightColor: UIColor!
	var cellSeparatorColor: UIColor!
	var sectionHeaderBackgroundColor: UIColor!
	var sectionHeaderTextColor: UIColor!

	init(style: Styles = .Dark) {
		self.style = style
		set()
	}
	
	// MARK: - Set theme
	func set() {
		switch style {
		case .Dark:
			// Global App tint color
			globalTintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)

			// Status bar appearance
			statusBarStyle = .LightContent

			// Navigation bar appearance
			navBarStyle = .Black
			navBarTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
			navTintColor = globalTintColor
			navTextColor = globalTintColor
			
			// Search bar appearance
			searchBarStyle = .Black
			searchBarTintColor = globalTintColor
			
			// Tab bar appearance
			tabTintColor = blueColor
			tabBarTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
			
			// Tab bar top border color
			tabBarTopBorderColor = blueColor
			
			// Keyboard appearance
			keyboardStyle = .Dark

			// Refresh control appearance
			refreshControlTintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)

			// Table view appearance
			tableViewBackgroundColor = UIColor.clearColor()
			cellHighlightColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
			cellSeparatorColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
			sectionHeaderBackgroundColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
			sectionHeaderTextColor = greenColor
		case .Light:
			// Global App tint color
			globalTintColor = UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1)

			// Status bar appearance
			statusBarStyle = .Default

			// Navigation bar appearance
			navBarStyle = .Default
			navBarTintColor = UIColor.whiteColor()
			navTintColor = globalTintColor
			navTextColor = globalTintColor
			
			// Search bar appearance
			searchBarStyle = .Default
			searchBarTintColor = globalTintColor
			
			// Tab bar appearance
			tabTintColor = globalTintColor
			tabBarTintColor = UIColor.whiteColor()
			
			// Tab bar top border color
			tabBarTopBorderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
			
			// Keyboard appearance
			keyboardStyle = .Light
			
			// Refresh control appearance
			refreshControlTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)

			// Table view appearance
			tableViewBackgroundColor = UIColor.whiteColor()
			cellHighlightColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
			cellSeparatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
			sectionHeaderBackgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
			sectionHeaderTextColor = globalTintColor
		}
	}
	
	// MARK: - View gradient for dark theme
	func gradient() -> CAGradientLayer {
		let gradient = CAGradientLayer()
		gradient.colors = [
			UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1).CGColor,
			UIColor(red: 0, green: 0, blue: 6/255, alpha: 1).CGColor
		]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		return gradient
	}
}
