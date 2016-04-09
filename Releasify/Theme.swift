//
//  Theme.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/6/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

public class Theme {
	static let sharedInstance = Theme()
	
	enum Styles { case dark, light }
	
	var style: Styles = .dark
	
	// Global App tint color
	var globalTintColor: UIColor!
	
	// Common colors (Green alternative: #00D897)
	let blueColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)
	let greenColor = UIColor(red: 0, green: 242/255, blue: 192/255, alpha: 1)
	let redColor = UIColor(red: 252/255, green: 77/255, blue: 119/255, alpha: 1)
	let orangeColor = UIColor(red: 1, green: 85/255, blue: 80/255, alpha: 1)
	let orangeAltColor = UIColor(red: 248/255, green: 65/255, blue: 48/255, alpha: 1)
	
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
	
	// MARK: - Set theme
	func set() {
		switch style {
		case .dark:
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
		case .light:
			// Global App tint color
			globalTintColor = UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0)

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
			tabBarTopBorderColor = UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0)
			
			// Keyboard appearance
			keyboardStyle = .Light
			
			// Refresh control appearance
			refreshControlTintColor = UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 0.5)
		}
	}
	
	// View gradient for dark theme
	func gradient() -> CAGradientLayer {
		let gradient = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		return gradient
	}
}
