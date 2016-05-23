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
	let debug = true
	var window: UIWindow?
	var backWindow: UIWindow?
	var theme: Theme!
	var userID = 0
	var userDeviceToken: String?
	var userUUID: String!
	var contentHash: String?
	var shortcutKeyDescription: String?
	var allowExplicitContent = true
	var removeExpiredAlbums = false
	var completedRefresh = false
	var firstRun = false
	var canAddToLibrary = false
	var lastUpdated = 0
	var notificationAlbumID: Int?
	var remoteNotificationPayload: NSDictionary?
	var localNotificationPayload: NSDictionary?
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		let versionString = (NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String) + " (" + (NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String) + ")"
		NSUserDefaults.standardUserDefaults().setValue(versionString, forKey: "appVersion")		
		
		// Handle reset case
		let reset = NSUserDefaults.standardUserDefaults().boolForKey("reset")
		if reset {
			AppDB.sharedInstance.reset()
			Favorites.sharedInstance.clearList()
			application.cancelAllLocalNotifications()
			NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "ID")
			NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "lastUpdated")
			NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "contentHash")
			NSUserDefaults.standardUserDefaults().setBool(false, forKey: "reset")
			NSUserDefaults.standardUserDefaults().setBool(false, forKey: "removeExpiredAlbums")
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "allowExplicit")
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "theme")
			NSUserDefaults.standardUserDefaults().removeObjectForKey("canAddToLibrary")
		}
		
		// Load App settings
		userID = NSUserDefaults.standardUserDefaults().integerForKey("ID")
		lastUpdated = NSUserDefaults.standardUserDefaults().integerForKey("lastUpdated")
		if let token = NSUserDefaults.standardUserDefaults().stringForKey("deviceToken") { userDeviceToken = token }
		if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("uuid") { userUUID = uuid }
		if let hash = NSUserDefaults.standardUserDefaults().valueForKey("contentHash") as? String { contentHash = hash }
		if let expiredAlbumVal = NSUserDefaults.standardUserDefaults().valueForKey("removeExpiredAlbums") as? Bool {
			removeExpiredAlbums = expiredAlbumVal
		} else {
			NSUserDefaults.standardUserDefaults().setBool(false, forKey: "removeExpiredAlbums")
		}
		if let explicitContentVal = NSUserDefaults.standardUserDefaults().valueForKey("allowExplicit") as? Bool {
			allowExplicitContent = explicitContentVal
		} else {
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "allowExplicit")
		}

		// Theme settings & customizations
		if let themeVal = NSUserDefaults.standardUserDefaults().valueForKey("theme") as? Bool {
			theme = Theme(style: themeVal == true ? .dark : .light)
		} else {
			NSUserDefaults.standardUserDefaults().setBool(true, forKey: "theme")
			theme = Theme(style: .dark)
		}
		UIApplication.sharedApplication().statusBarStyle = theme.statusBarStyle
		let navBarAppearance = UINavigationBar.appearance()		
		navBarAppearance.barStyle = theme.navBarStyle
		navBarAppearance.barTintColor = theme.navBarTintColor
		if theme.style == .dark {
			navBarAppearance.shadowImage = UIImage()
		} else {	
			navBarAppearance.shadowImage = UIImage(named: "navbar_shadow")
		}
		navBarAppearance.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		navBarAppearance.tintColor = theme.navTintColor
		navBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: theme.navTextColor]
		navBarAppearance.translucent = false
		let tabBarAppearance = UITabBar.appearance()
		tabBarAppearance.barTintColor = theme.tabBarTintColor
		tabBarAppearance.tintColor = theme.tabTintColor
		tabBarAppearance.backgroundColor = UIColor.clearColor()
		tabBarAppearance.shadowImage = UIImage()
		tabBarAppearance.backgroundImage = UIImage()

		// Launch options
		if let launchOpts = launchOptions {
			if let remotePayload = launchOpts[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
				remoteNotificationPayload = remotePayload
			}
			if let localNotification = launchOpts[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
				if let userInfo = localNotification.userInfo {
					localNotificationPayload = userInfo
				}
			}
			if #available(iOS 9.0, *) {
			    if let shortcutKey = launchOpts[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
    				shortcutKeyDescription = shortcutKey.type
    			}
			}
		}
		
		// Favorites list
		Favorites.sharedInstance.load()
		
		// Set initial view controller
		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		if userID == 0 {
			firstRun = true
			UIApplication.sharedApplication().cancelAllLocalNotifications()
			window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("IntroPageController") as! UIPageViewController
		} else {
			let back = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("favoritesList") as! UINavigationController
			self.backWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
			self.backWindow!.rootViewController = back
			backWindow?.makeKeyAndVisible()
			window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AppController") as! UINavigationController
		}
		window?.makeKeyAndVisible()
		
		return true
	}

	// MARK: - Callback when user allows push notifications
	func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
		var deviceTokenString = deviceToken.description
		deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(" ", withString: "", options: .LiteralSearch, range: nil)
		deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString("<", withString: "", options: .LiteralSearch, range: nil)
		deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(">", withString: "", options: .LiteralSearch, range: nil)
		userDeviceToken = deviceTokenString
		if userDeviceToken != nil {
			API.sharedInstance.register(deviceToken: userDeviceToken, allowExplicitContent, successHandler: { (userID, userUUID) in
				if self.debug { print(userID!) }
				self.userID = userID!
				self.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.userUUID, forKey: "uuid")
				NSUserDefaults.standardUserDefaults().setValue(self.userDeviceToken, forKey: "deviceToken")
				NSNotificationCenter.defaultCenter().postNotificationName("finishNotificationRegister", object: nil, userInfo: nil)
				},
				errorHandler: { (error) in
			})
		}
	}
	
	// MARK: - Callback when user does not give permission to use push notifications
	func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
		if userID == 0 {
			API.sharedInstance.register(allowExplicitContent, successHandler: { (userID, userUUID) in
				self.userID = userID!
				self.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.userUUID, forKey: "uuid")
				},
				errorHandler: { (error) in
			})
		}
	}
	
	// MARK: - Local Notification - Receiver | App is in the foreground or the notification itself is tapped
	func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
		if let userInfo = notification.userInfo {
			notificationAlbumID = userInfo["albumID"] as? Int
			if application.applicationState == .Inactive {
				NSNotificationCenter.defaultCenter().postNotificationName("showAlbum", object: nil, userInfo: userInfo)
			} else {
				NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
			}
		}
	}
	
	// MARK: - Local Notification - Handler
	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
		if identifier == "APP_ACTION" {
			NSNotificationCenter.defaultCenter().postNotificationName("showAlbum", object: nil, userInfo: notification.userInfo)
		} else {
			dispatch_async(dispatch_get_main_queue(), {
				if let userInfo = notification.userInfo {
					let iTunesURL = userInfo["iTunesUrl"]! as! String
					if UIApplication.sharedApplication().canOpenURL(NSURL(string: iTunesURL)!) {
						UIApplication.sharedApplication().openURL(NSURL(string: iTunesURL)!)
					}
				}
			})
		}
		completionHandler()
	}
	
	// MARK: - Remote Notification - Receiver
	func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
		if application.applicationState == .Inactive {
			NSNotificationCenter.defaultCenter().postNotificationName("appActionPressed", object: nil, userInfo: userInfo)
		} else {
			NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
		}
	}
	
	// MARK: - Remote Notification - Handler
	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
		if identifier == "APP_ACTION" {
			dispatch_async(dispatch_get_main_queue(), {
				NSNotificationCenter.defaultCenter().postNotificationName("appActionPressed", object: nil, userInfo: userInfo)
			})
		} else if identifier == "PREORDER_ACTION" {
			dispatch_async(dispatch_get_main_queue(), {
				if let iTunesURL = userInfo["aps"]?["iTunesUrl"]! as? String {
					if UIApplication.sharedApplication().canOpenURL(NSURL(string: iTunesURL)!) {
						UIApplication.sharedApplication().openURL(NSURL(string: iTunesURL)!)
					}
				}
			})
		}
		completionHandler()
	}
	
	// MARK: - 3D Touch Home Screen Quick Actions
	@available(iOS 9.0, *)
	func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
		if shortcutItem.type == "add-subscription" {
			NSNotificationCenter.defaultCenter().postNotificationName("addSubscriptionShortcutItem", object: nil, userInfo: nil)
			completionHandler(true)
		} else {
			completionHandler(false)
		}
	}

	func applicationDidBecomeActive(application: UIApplication) {}

	func applicationWillTerminate(application: UIApplication) {}
	
	func applicationWillResignActive(application: UIApplication) {}
	
	func applicationDidEnterBackground(application: UIApplication) {}
	
	func applicationWillEnterForeground(application: UIApplication) {}

}
