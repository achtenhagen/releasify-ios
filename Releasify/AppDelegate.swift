//
//  AppDelegate.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var userID = 0
	var userDeviceToken: String?
	var userUUID: String!
	var contentHash: String?
	var allowExplicitContent = true
	var lastUpdated = 0
	var notificationAlbumID: Int!
	var remoteNotificationPayload: NSDictionary?
	var localNotificationPayload: NSDictionary?
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		let versionString = (NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String) + " (" + (NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String) + ")"
		NSUserDefaults.standardUserDefaults().setValue(versionString, forKey: "appVersion")
		
		// MARK: - Notification settings
		// Move to tutorial screen.
		if application.respondsToSelector("registerUserNotificationSettings:") {
			
			let appAction = UIMutableUserNotificationAction()
			appAction.identifier = "APP_ACTION"
			appAction.title = "View in App"
			appAction.activationMode = .Foreground
			appAction.destructive = false
			appAction.authenticationRequired = false
			
			let storeAction = UIMutableUserNotificationAction()
			storeAction.identifier = "STORE_ACTION"
			switch UIDevice.currentDevice().systemVersion.compare("8.4.0", options: .NumericSearch) {
			case .OrderedSame, .OrderedDescending:
				storeAction.title = " MUSIC"
			case .OrderedAscending:
				storeAction.title = "Buy on iTunes"
			}
			storeAction.activationMode = .Foreground
			storeAction.destructive = false
			storeAction.authenticationRequired = false
			
			let defaultCategory = UIMutableUserNotificationCategory()
			defaultCategory.identifier = "DEFAULT_CATEGORY"
			let remoteCategory = UIMutableUserNotificationCategory()
			remoteCategory.identifier = "REMOTE_CATEGORY"
			
			let defaultActions = [appAction, storeAction]
			let remoteActions  = [appAction]
			
			defaultCategory.setActions(defaultActions, forContext: .Default)
			defaultCategory.setActions(defaultActions, forContext: .Minimal)
			remoteCategory.setActions(remoteActions, forContext: .Default)
			remoteCategory.setActions(remoteActions, forContext: .Minimal)
			
			let categories = NSSet(objects: defaultCategory, remoteCategory)
			let types: UIUserNotificationType = ([.Alert, .Badge, .Sound])
			let settings = UIUserNotificationSettings(forTypes: types, categories: categories as? Set<UIUserNotificationCategory>)
			
			application.registerUserNotificationSettings(settings)
			application.registerForRemoteNotifications()
		}
		
		// MARK: - App reset setting
		let reset = NSUserDefaults.standardUserDefaults().boolForKey("reset")
		if reset {
			print("The application will be reset to default settings.")
			application.cancelAllLocalNotifications()
			AppDB.sharedInstance.truncate("artists")
			AppDB.sharedInstance.truncate("pending_artists")
			AppDB.sharedInstance.truncate("albums")
			AppDB.sharedInstance.truncate("album_artists")
			NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "ID")
			NSUserDefaults.standardUserDefaults().setBool(false, forKey: "reset")
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "allowExplicit")
			NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "lastUpdated")
		}
		
		// MARK: - App settings
		userID = NSUserDefaults.standardUserDefaults().integerForKey("ID")
		lastUpdated = NSUserDefaults.standardUserDefaults().integerForKey("lastUpdated")
		if let token = NSUserDefaults.standardUserDefaults().stringForKey("deviceToken") { userDeviceToken = token }
		if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("uuid") { userUUID = uuid }
		if let hash = NSUserDefaults.standardUserDefaults().valueForKey("contentHash") as? String {
			contentHash = hash
			print("Content hash has been set (\(contentHash!)).")
		} else {
			print("No content hash has been set.")
		}
		if let explicit = NSUserDefaults.standardUserDefaults().valueForKey("allowExplicit") as? Bool {
			allowExplicitContent = explicit
			if allowExplicitContent {
				print("User allows explicit content.")
			} else {
				print("User does not allow explicit content.")
			}
		} else {
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "allowExplicit")
		}
		
		// Check for notification payload when app is launched.
		if let launchOpts = launchOptions {
			if let remotePayload = launchOpts[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary { remoteNotificationPayload = remotePayload }
			if let localNotification = launchOpts[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
				if let userInfo = localNotification.userInfo { localNotificationPayload = userInfo }
			}
		}
		
		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AppController") as! UINavigationController
		window?.makeKeyAndVisible()
		
		return true
	}

	func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
		print("User allows notifications (\(deviceToken.description)).")
		var deviceTokenString = deviceToken.description
		deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(" ", withString: "", options: .LiteralSearch, range: nil)
		deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString("<", withString: "", options: .LiteralSearch, range: nil)
		deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(">", withString: "", options: .LiteralSearch, range: nil)
		self.userDeviceToken = deviceTokenString
		if userID == 0 {
			API.sharedInstance.register(deviceToken: deviceTokenString, allowExplicitContent, successHandler: { (userID, userUUID) in
				self.userID = userID!
				self.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.userUUID, forKey: "uuid")
				NSUserDefaults.standardUserDefaults().setValue(self.userDeviceToken, forKey: "deviceToken")
				print("UUID was set successfully.")
				print("APNS Device token was set successfully.")
				},
				errorHandler: { (error) in
					// print("Error: \(error.localizedDescription)")
			})
		}
	}
	
	func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
		print("Error: \(error.localizedDescription)")
		if userID == 0 {
			API.sharedInstance.register(allowExplicitContent, successHandler: { (userID, userUUID) in
				self.userID = userID!
				self.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.userUUID, forKey: "uuid")
				print("UUID was set successfully.")
				},
				errorHandler: { (error) in
					// print("Error: \(error.localizedDescription)")
			})
		}
	}
	
	// MARK: - Local Notification - Receiver
	// Called when app is in the foreground or the notification itself is tapped.
	func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
		if let userInfo = notification.userInfo {
			notificationAlbumID = userInfo["AlbumID"] as! Int
			print("Received a local notification with ID: \(notificationAlbumID).")
			// Called when the notification is tapped if the app is inactive or in the background.
			if application.applicationState == .Inactive || application.applicationState == .Background {
				NSNotificationCenter.defaultCenter().postNotificationName("showAlbum", object: nil, userInfo: userInfo)
			} else {
				// If the app is active, refresh its content.
				NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: userInfo)
			}
		}
	}
	
	// MARK: - Local Notification - Handler
	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
		if identifier == "APP_ACTION" {
			delay(0) {
				NSNotificationCenter.defaultCenter().postNotificationName("showAlbum", object: nil, userInfo: notification.userInfo)
			}
		} else {
			delay(0) {
				if let userInfo = notification.userInfo {
					let iTunesURL = userInfo["iTunesURL"]! as! String
					if UIApplication.sharedApplication().canOpenURL(NSURL(string: iTunesURL)!) {
						UIApplication.sharedApplication().openURL(NSURL(string: iTunesURL)!)
					}
				}
			}
		}
		completionHandler()
	}
	
	// MARK: - Remote Notification - Receiver + Background fetch
	func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		print("Received remote call to refresh.")
		API.sharedInstance.refreshContent(nil, errorHandler: { (error) in
			completionHandler(.Failed)
		})
		completionHandler(.NewData)
	}
	
	// MARK: - Remote Notification - Handler
	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
		if identifier == "APP_ACTION" {
			print("app action pressed.")
			delay(0) {
				NSNotificationCenter.defaultCenter().postNotificationName("appActionPressed", object: nil, userInfo: userInfo)
			}
		}
		completionHandler()
	}
	
	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(application: UIApplication) {
		// Move to Album Controller
		application.applicationIconBadgeNumber = 0
	}
	
	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func delay(delay:Double, closure:() -> Void) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
	}
}
