//
//  AppController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 7/26/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class AppController: UINavigationController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
	@IBOutlet weak var navBar: UINavigationBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Load data from database.
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getAlbums()
		
		// Check for any pending artists waiting to be removed.
		AppDB.sharedInstance.getPendingArtists()
		
		// Global UINavigationBar styles.
		let navBarAppearance = UINavigationBar.appearance()
		navBarAppearance.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1.0)
		navBarAppearance.shadowImage = UIImage()
		navBarAppearance.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		navBarAppearance.translucent = false		
		
		view.addSubview(Notification.sharedInstance)
		Notification.sharedInstance.userInteractionEnabled = false
		Notification.sharedInstance.drawRect(CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 55))
		
		print("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications!.count)")
		print("App Controller loaded.")
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}
