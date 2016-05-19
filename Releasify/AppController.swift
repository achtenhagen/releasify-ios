//
//  AppController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 7/26/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

protocol AppControllerDelegate: class {
	func addNotificationView (notification: Notification)
}

let kHeaderHeight: CGFloat = 60
var window = UIWindow()
var panGesture = UIPanGestureRecognizer()

final class AppController: UINavigationController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var tabController: TabBarController!
	var firstX = Float()
	var firstY = Float()
	var _origin = CGPoint()
	var _final = CGPoint()
	var duration = CGFloat()

	@IBOutlet weak var navBar: UINavigationBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// AppDB.sharedInstance.upgrade_db_v2()
		// Favorites.sharedInstance.clearList()

		// Get pending artists waiting to be removed
		AppDB.sharedInstance.getPendingArtists()
		
		// Housekeeping
		if appDelegate.removeExpiredAlbums {
			AppDB.sharedInstance.removeExpiredAlbums()
		}
		
		// Print debug info
		if appDelegate.debug {
			print("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications!.count)")
			print("App Controller loaded.")
		}

		// Instantiate tab bar controller
		if tabBarController == nil {
			tabController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TabBarController") as! TabBarController
			tabController.notificationDelegate = self
		}
		
		self.setViewControllers([tabController], animated: true)

		window = appDelegate.window!
		window.layer.shadowRadius = 15
		window.layer.shadowOffset = CGSizeMake(0, 0)
		window.layer.shadowColor = UIColor.blackColor().CGColor
		window.layer.shadowOpacity = 0.8
		duration = 0.3
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func activateSwipeToOpenMenu(onlyNavigation: Bool) {
		panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
		if onlyNavigation == true {
			self.navigationBar.addGestureRecognizer(panGesture)
		} else {
			window.addGestureRecognizer(panGesture)
		}
	}

	func openAndCloseMenu() {
		var finalOrigin = CGPoint()
		var f = CGRect()
		f = window.frame
		if f.origin.y == CGPointZero.y {
			finalOrigin.y = CGRectGetHeight(UIScreen.mainScreen().bounds) - kHeaderHeight
		} else {
			finalOrigin.y = CGPointZero.y
		}
		finalOrigin.x = 0
		f.origin = finalOrigin
		UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
			window.transform = CGAffineTransformIdentity
			window.frame = f
		}, completion: nil)
	}

	func setAnimationDuration(d: CGFloat) {
		duration = d
	}

	func onPan(pan: UIPanGestureRecognizer) {
		let translation:CGPoint = pan.translationInView(window)
		let velocity:CGPoint = pan.velocityInView(window)

		switch (pan.state) {
		case .Began:
			_origin = window.frame.origin
			break
		case .Changed:
			if _origin.y + translation.y >= 0 {
				if window.frame.origin.y != CGPointZero.y {
					window.transform = CGAffineTransformMakeTranslation(0, translation.y)
				} else {
					window.transform = CGAffineTransformMakeTranslation(0, translation.y)
				}
			}
			break
		case .Ended:
			break
		case .Cancelled:
			var finalOrigin = CGPointZero
			if velocity.y >= 0 {
				finalOrigin.y = CGRectGetHeight(UIScreen.mainScreen().bounds) - kHeaderHeight
			}
			var f = window.frame
			f.origin = finalOrigin
			UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
				window.transform = CGAffineTransformIdentity
				window.frame = f
			}, completion: nil)
			break
		default:
			break
		}
	}
}

// MARK: - AppControllerDelegate
extension AppController: AppControllerDelegate {
	func addNotificationView(notification: Notification) {
		self.view.addSubview(notification)
	}
}

// MARK: - UIView fade in/out extension
extension UIView {
	func fadeIn(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0.0, completion: (Bool) -> Void = { (finished: Bool) -> Void in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 1.0 }, completion: completion)
	}
	func fadeOut(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0.0, completion: (Bool) -> Void = { (finished: Bool) -> Void in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 0.0 }, completion: completion)
	}
}
