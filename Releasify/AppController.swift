//
//  AppController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 7/26/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

protocol AppControllerDelegate: class {
	func addNotificationView(notification: Notification)
	func fullyHideMenu()
	func restoreMenu()
}

var window: UIWindow!
private let kLeftInset: CGFloat = 60

final class AppController: UINavigationController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var leftEdgePan: UIScreenEdgePanGestureRecognizer!
	var swipeGesture: UISwipeGestureRecognizer!
	var tapGesture: UITapGestureRecognizer!
	var tabController: TabBarController!
	var _origin: CGPoint!

	enum Menu {
		case Closed, Hidden, Open
		func position() -> CGFloat {
			switch self {
			case .Closed:
				return CGPointZero.x
			case .Hidden:
				return CGRectGetWidth(UIScreen.mainScreen().bounds)
			case .Open:
				return CGRectGetWidth(UIScreen.mainScreen().bounds) - kLeftInset
			}
		}
	}

	@IBOutlet weak var navBar: UINavigationBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// AppDB.sharedInstance.upgrade_db_v2()

		// UnreadItems.sharedInstance.clearList()
		UnreadItems.sharedInstance.load()

		// Get pending artists waiting to be removed
		AppDB.sharedInstance.getPendingArtists()
		
		// Housekeeping
		if appDelegate.removeExpiredAlbums {
			AppDB.sharedInstance.removeExpiredAlbums()
		}
		
		// Print debug info
		if appDelegate.debug {
			print("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications!.count)")
			print("Unread items: \(UnreadItems.sharedInstance.list.count)")
			print("App Controller loaded.")
		}

		// Instantiate tab bar controller
		if tabBarController == nil {
			tabController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TabBarController") as! TabBarController
			tabController.notificationDelegate = self
		}
		self.setViewControllers([tabController], animated: true)

		// Window customizations
		window = appDelegate.window!
		window.layer.shadowRadius = 15
		window.layer.shadowOffset = CGSizeMake(0, 0)
		window.layer.shadowColor = UIColor.blackColor().CGColor
		window.layer.shadowOpacity =  appDelegate.theme.style == .Dark ? 0.8 : 0.2
		_origin = window.frame.origin

		// Menu gestures
		leftEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
		leftEdgePan.edges = .Left
		swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
		swipeGesture.direction = .Left
		tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
		tabController.view.addGestureRecognizer(leftEdgePan)
	}

	// MARK: - Tap gesture handler
	func handleTap(recognizer: UITapGestureRecognizer) {
		closeMenu()
	}

	// MARK: - Swipe gesture handler
	func handleSwipe(recognizer: UISwipeGestureRecognizer) {
		closeMenu()
	}

	// MARK: - Edge pan gesture handler
	func handleEdgePan(recognizer: UIScreenEdgePanGestureRecognizer) {
		let translation: CGPoint = recognizer.translationInView(window)
		let velocity: CGPoint = recognizer.velocityInView(window)
		switch (recognizer.state) {
		case .Began:
			_origin = window.frame.origin
			break
		case .Changed:
				tabController.streamController.view.userInteractionEnabled = false
				tabController.subscriptionController.view.userInteractionEnabled = false
				if _origin.x + translation.x <= Menu.Open.position() {
					window.transform = CGAffineTransformMakeTranslation(translation.x, 0)
				}
		case .Ended:
			var finalOrigin = CGPointZero
			var f = window.frame
			if velocity.x > 0 {
				if _origin.x + translation.x >= 50 {
					finalOrigin = CGPoint(x: Menu.Open.position(), y: 0)
				}
			} else {
				if _origin.x + translation.x >= Menu.Open.position() - 50 {
					finalOrigin = CGPoint(x: Menu.Open.position(), y: 0)
				}
			}
			f.origin = finalOrigin
			UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
				window.transform = CGAffineTransformIdentity
				window.frame = f
			}, completion: { (completed) in
				if window.frame.origin.x == Menu.Open.position() {
					self.tabController.view.addGestureRecognizer(self.tapGesture)
					self.tabController.view.addGestureRecognizer(self.swipeGesture)
				}
				self.setViewInteraction(finalOrigin)
			})
		case .Cancelled:
			closeMenu()
		default:
			break
		}
	}

	// MARK: - Toggle menu state
	func openAndCloseMenu() {
		var finalOrigin = CGPoint()
		var f = window.frame
		if f.origin.x == Menu.Closed.position(){
			finalOrigin.x = Menu.Open.position()
			self.tabController.view.addGestureRecognizer(self.tapGesture)
			self.tabController.view.addGestureRecognizer(self.swipeGesture)
		} else {
			finalOrigin.x = Menu.Closed.position()
			self.tabController.view.removeGestureRecognizer(self.tapGesture)
			self.tabController.view.removeGestureRecognizer(self.swipeGesture)
		}
		f.origin = finalOrigin
		UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
			window.transform = CGAffineTransformIdentity
			window.frame = f
		}, completion: { (completed) in
			self.setViewInteraction(finalOrigin)
		})
	}

	// MARK: - Close the menu
	func closeMenu() {
		var finalOrigin = CGPointZero
		var f = window.frame
		finalOrigin = CGPoint(x: Menu.Closed.position(), y: 0)
		f.origin = finalOrigin
		UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
			window.transform = CGAffineTransformIdentity
			window.frame = f
			}, completion: { (completed) in
				self.tabController.view.removeGestureRecognizer(self.tapGesture)
				self.tabController.view.removeGestureRecognizer(self.swipeGesture)
				self.setViewInteraction(finalOrigin)
		})
	}

	// MARK: - Set the view's user interaction ability
	func setViewInteraction(point: CGPoint) {
		if point == CGPointZero {
			self.tabController.streamController.view.userInteractionEnabled = true
			self.tabController.subscriptionController.view.userInteractionEnabled = true
		} else {
			self.tabController.streamController.view.userInteractionEnabled = false
			self.tabController.subscriptionController.view.userInteractionEnabled = false
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

// MARK: - AppControllerDelegate
extension AppController: AppControllerDelegate {
	func addNotificationView(notification: Notification) {
		self.view.addSubview(notification)
	}

	func fullyHideMenu() {
		UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
			window.transform = CGAffineTransformIdentity
			window.frame.origin.x = Menu.Hidden.position()
		}, completion: nil)
	}

	func restoreMenu() {
		UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
			window.transform = CGAffineTransformIdentity
			window.frame.origin.x = Menu.Open.position()
		}, completion: nil)
	}
}

// MARK: - UIView fade in/out extension
extension UIView {
	func fadeIn(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0, completion: (Bool) -> Void = { (finished) in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 1 }, completion: completion)
	}
	func fadeOut(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0, completion: (Bool) -> Void = { (finished) in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 0 }, completion: completion)
	}
}
