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

final class AppController: UINavigationController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var tabController: TabBarController!
	
	@IBOutlet weak var navBar: UINavigationBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		AppDB.sharedInstance.upgrade_db_v2()

		AppDB.sharedInstance.getAlbums()
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getPendingArtists()
		
		if appDelegate.removeExpiredAlbums {
			AppDB.sharedInstance.removeExpiredAlbums()
		}
		
		if appDelegate.debug {
			print("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications!.count)")
			print("App Controller loaded.")			
		}

		if tabBarController == nil {
			tabController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TabBarController") as! TabBarController
			tabController.notificationDelegate = self
		}		
		
		self.setViewControllers([tabController], animated: true)
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
