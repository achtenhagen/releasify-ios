
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var userID = 0
    var userDeviceToken: String?
	var userUUID: String!
    var allowExplicitContent = true
	var lastUpdated = 0
	var notificationAlbumID: Int!
	var remoteNotificationPayload: NSDictionary?
	var localNotificationPayload: NSDictionary?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let versionString = (NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String)! + " (Clairvoyant)"
        NSUserDefaults.standardUserDefaults().setValue(versionString, forKey: "appVersion")
        
        // Notification settings & categories (UPDATE: move to tutorial screen).
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
			var appAction = UIMutableUserNotificationAction()
            appAction.identifier = "APP_ACTION"
            appAction.title = "View in App"
            appAction.activationMode = .Foreground
            appAction.destructive = false
            appAction.authenticationRequired = false
            
			var storeAction = UIMutableUserNotificationAction()
            storeAction.identifier = "STORE_ACTION"
			switch UIDevice.currentDevice().systemVersion.compare("8.4.0", options: NSStringCompareOptions.NumericSearch) {
			case .OrderedSame, .OrderedDescending:
				storeAction.title = " MUSIC"
			case .OrderedAscending:
				storeAction.title = "Buy on iTunes"
			}
            storeAction.activationMode = .Foreground
            storeAction.destructive = false
            storeAction.authenticationRequired = false
            
            var defaultCategory = UIMutableUserNotificationCategory()
            defaultCategory.identifier = "DEFAULT_CATEGORY"
            var remoteCategory = UIMutableUserNotificationCategory()
            remoteCategory.identifier = "REMOTE_CATEGORY"
            
            let defaultActions = [appAction, storeAction]
            let remoteActions  = [appAction]
            
            defaultCategory.setActions(defaultActions, forContext: .Default)
            defaultCategory.setActions(defaultActions, forContext: .Minimal)
            remoteCategory.setActions(remoteActions, forContext: .Default)
            remoteCategory.setActions(remoteActions, forContext: .Minimal)
            
            let categories = NSSet(objects: defaultCategory, remoteCategory)
            let types: UIUserNotificationType = (.Alert | .Badge | .Sound)
            let settings = UIUserNotificationSettings(forTypes: types, categories: categories as Set<NSObject>)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        // In case the user has chosen to reset the app.
        let reset = NSUserDefaults.standardUserDefaults().boolForKey("reset")
        if reset {
            println("The application will be reset to default settings.")
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
        
        // Read in user settings.
        userID = NSUserDefaults.standardUserDefaults().integerForKey("ID")
		lastUpdated = NSUserDefaults.standardUserDefaults().integerForKey("lastUpdated")
        if let token = NSUserDefaults.standardUserDefaults().stringForKey("deviceToken") {
            userDeviceToken = token
        }
        if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("uuid") {
            userUUID = uuid
        }
        if let explicit = NSUserDefaults.standardUserDefaults().valueForKey("allowExplicit") as? Bool {
            allowExplicitContent = explicit
            if allowExplicitContent {
                println("User allows explicit content.")
            } else {
                println("User does not allow explicit content.")
            }
        } else {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "allowExplicit")
        }
        
        // Check for notification payload when app is launched.
        if let launchOpts = launchOptions {
            if let remotePayload = launchOpts[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
                remoteNotificationPayload = remotePayload
            }
            if let localNotification = launchOpts[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
                if let userInfo = localNotification.userInfo {
                    localNotificationPayload = userInfo
                }
            }
        }
		
        return true
    }
	
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("User allows notifications.")
        var deviceTokenString = deviceToken.description
        deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString("<", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(">", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
		self.userDeviceToken = deviceTokenString
        if userID == 0 {
			API.sharedInstance.register(deviceToken: deviceTokenString, allowExplicitContent: allowExplicitContent, successHandler: { (userID, userUUID) in
				self.userID = userID!
				self.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.userUUID, forKey: "uuid")
				NSUserDefaults.standardUserDefaults().setValue(self.userDeviceToken, forKey: "deviceToken")
				println("UUID was set successfully.")
				println("APNS Device token was set successfully.")
			},
			errorHandler: { (error) in
				println("Error: \(error.localizedDescription)")
			})
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
		println("Error: \(error.localizedDescription)")
        if userID == 0 {
			API.sharedInstance.register(allowExplicitContent: allowExplicitContent, successHandler: { (userID, userUUID) in
				self.userID = userID!
				self.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.userUUID, forKey: "uuid")
				println("UUID was set successfully.")
			},
			errorHandler: { (error) in
				println("Error: \(error.localizedDescription)")
			})
        }
    }
    
	// Local Notification - Receiver (Called when app is in the foreground or the notification itself is tapped)
	func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            notificationAlbumID = userInfo["AlbumID"] as! Int
            println("Received a local notification with ID: \(notificationAlbumID).")
            // Called when the notification is tapped if the app is inactive or in the background.
            if application.applicationState == .Inactive || application.applicationState == .Background {
                NSNotificationCenter.defaultCenter().postNotificationName("showAlbum", object: nil, userInfo: userInfo)
			} else {
				// If the app is active, refresh the contents.
				NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: userInfo)
			}
        }
    }
    
	// Local Notification - Handler
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
	
	// Remote Notification - Receiver + Background fetch
	func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		println("Received remote call to refresh.")
		API.sharedInstance.refreshContent(nil, errorHandler: { (error) in
			completionHandler(UIBackgroundFetchResult.Failed)
		})
		completionHandler(UIBackgroundFetchResult.NewData)
	}
	
	// Remote Notification - Handler
	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
		if identifier == "APP_ACTION" {
			println("app action pressed.")
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
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
	
	func delay(delay:Double, closure:() -> Void) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
	}
}
