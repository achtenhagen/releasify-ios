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
	var streamController: StreamViewController!
	
	@IBOutlet weak var navBar: UINavigationBar!
	
	override func viewDidLoad () {
		super.viewDidLoad()
		
		AppDB.sharedInstance.getAlbums()
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getPendingArtists()
		
		if appDelegate.removeExpiredAlbums {
			AppDB.sharedInstance.removeExpiredAlbums()
		}
		
		let navBarAppearance = UINavigationBar.appearance()
		
		navBarAppearance.barStyle = .Black
		
		// navBarAppearance.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1.0)
		navBarAppearance.shadowImage = UIImage()
		navBarAppearance.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		navBarAppearance.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)
		navBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)]
		// navBarAppearance.translucent = false
		
		if appDelegate.debug {
			print("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications!.count)")
			print("App Controller loaded.")			
		}
		
		if streamController == nil {
			streamController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("StreamController") as! StreamViewController
			streamController.delegate = self
		}
		self.setViewControllers([streamController], animated: true)
	}
	
	override func didReceiveMemoryWarning () {
		super.didReceiveMemoryWarning()
	}
}

// MARK: - AppControllerDelegate
extension AppController: AppControllerDelegate {
	func addNotificationView(notification: Notification) {
		print("called")
		self.view.addSubview(notification)
	}
}
