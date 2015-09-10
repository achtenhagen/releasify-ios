//
//  AppController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 7/26/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AppController: UINavigationController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
	@IBOutlet weak var navBar: UINavigationBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Load data from database.
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getAlbums()
		
		// Check for any pending artists waiting to be removed.
		let pendingArtists = AppDB.sharedInstance.getPendingArtists()
		
		// Global UINavigationBar style.
		var navBarAppearance = UINavigationBar.appearance()
		navBarAppearance.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1.0)
		navBarAppearance.setBackgroundImage(UIImage(named: "navBar.png"), forBarMetrics: .Default)
		navBarAppearance.shadowImage = UIImage()
		navBarAppearance.translucent = false
		
		println("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications.count)")
		println("App Controller loaded.")
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}