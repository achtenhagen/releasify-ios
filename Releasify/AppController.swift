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
		
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getAlbums()
		AppDB.sharedInstance.getPendingArtists()
		
		let navBarAppearance = UINavigationBar.appearance()
		navBarAppearance.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1.0)
		navBarAppearance.shadowImage = UIImage()
		navBarAppearance.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		navBarAppearance.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)
		navBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)]
		navBarAppearance.translucent = false
		
		print("Scheduled notifications: \(UIApplication.sharedApplication().scheduledLocalNotifications!.count)")
		print("App Controller loaded.")
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}
