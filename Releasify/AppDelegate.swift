
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let defaults = NSUserDefaults.standardUserDefaults()
    var userID = 0
    var userDeviceToken = String()
    var userUUID = String()
    var allowExplicitContent = true
    var notificationAlbumID = Int()
    var remoteNotificationPayload = NSDictionary()
    var localNotificationPayload  = NSDictionary()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        self.defaults.setValue(NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"], forKey: "appVersion")
        
        // Notification settings & categories
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            var appAction = UIMutableUserNotificationAction()
            appAction.identifier = "APP_ACTION"
            appAction.title = "Open in App"
            appAction.activationMode = .Foreground
            appAction.destructive = false
            appAction.authenticationRequired = false
            
            var storeAction = UIMutableUserNotificationAction()
            storeAction.identifier = "STORE_ACTION"
            storeAction.title = "Buy on iTunes"
            storeAction.activationMode = .Foreground
            storeAction.destructive = false
            storeAction.authenticationRequired = false
            
            var preorderAction = UIMutableUserNotificationAction()
            preorderAction.identifier = "PREORDER_ACTION"
            preorderAction.title = "Pre-order on iTunes"
            preorderAction.activationMode = .Foreground
            preorderAction.destructive = false
            preorderAction.authenticationRequired = false
            
            var defaultCategory = UIMutableUserNotificationCategory()
            defaultCategory.identifier = "DEFAULT_CATEGORY"
            var remoteCategory = UIMutableUserNotificationCategory()
            remoteCategory.identifier = "REMOTE_CATEGORY"
            
            let defaultActions = [appAction, storeAction]
            let remoteActions  = [appAction, preorderAction]
            
            defaultCategory.setActions(defaultActions, forContext: .Default)
            defaultCategory.setActions(defaultActions, forContext: .Minimal)
            remoteCategory.setActions(remoteActions, forContext: .Default)
            remoteCategory.setActions(remoteActions, forContext: .Minimal)
            
            let categories = NSSet(objects: defaultCategory, remoteCategory)
            let types:UIUserNotificationType = (.Alert | .Badge | .Sound)
            let settings = UIUserNotificationSettings(forTypes: types, categories: categories as Set<NSObject>)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        // In case the user has chosen to reset the app.
        let reset = defaults.boolForKey("reset")
        if reset {
            println("The application will be reset to default settings.")
            application.cancelAllLocalNotifications()
            AppDB.sharedInstance.truncate("artists")
            AppDB.sharedInstance.truncate("albums")
            AppDB.sharedInstance.truncate("album_artists")
            defaults.setInteger(0, forKey: "ID")
            defaults.setBool(false, forKey: "reset")
            defaults.setBool(true, forKey: "allowExplicit")
            defaults.setInteger(0, forKey: "lastUpdated")
        }
        
        // Read in user settings.
        userID = defaults.integerForKey("ID")
        if let token = defaults.stringForKey("deviceToken") {
            userDeviceToken = token
        }
        if let uuid = defaults.stringForKey("uuid") {
            userUUID = uuid
        }
        if let explicit = defaults.valueForKey("allowExplicit") as? Bool {
            allowExplicitContent = explicit
            if allowExplicitContent {
                println("User allows explicit content.")
            } else {
                println("User does not allow explicit content.")
            }
        } else {
            defaults.setBool(true, forKey: "allowExplicit")
        }
        
        // Initialize the database.
        AppDB.sharedInstance.create()
        
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
    
    private func register (deviceToken: String? = nil) {
        let uuid = NSUUID().UUIDString
        var appVersion = "Unknown"
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
        let systemVersion = UIDevice.currentDevice().systemVersion
        let deviceName = UIDevice().deviceType.rawValue
        let userAgent = "Releasify/\(appVersion) (iOS/\(systemVersion); \(deviceName))"
        let apiUrl = NSURL(string: APIURL.register.rawValue)
        var explicitValue = 1
        if !allowExplicitContent { explicitValue = 0 }
        var postString = "uuid=\(uuid)&explicit=\(explicitValue)"
        if deviceToken != nil {
            postString += "&deviceToken=\(deviceToken!)"
        }
        let request = NSMutableURLRequest(URL:apiUrl!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        request.timeoutInterval = 30
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) in
            if error == nil {
                if let HTTPResponse = response as? NSHTTPURLResponse {
                    println("HTTP status code: \(HTTPResponse.statusCode)")
                    if HTTPResponse.statusCode == 201 {
                        var error: NSError?
                        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary {
                            if error != nil { return }
                            let receivedUserID = json["id"] as? Int
                            if receivedUserID > 0 {
                                self.userID = receivedUserID!
                                self.userUUID = uuid
                                self.defaults.setInteger(receivedUserID!, forKey: "ID")
                                self.defaults.setValue(self.userUUID, forKey: "uuid")
                                if deviceToken != nil {
                                    self.userDeviceToken = deviceToken!
                                    self.defaults.setValue(self.userDeviceToken, forKey: "deviceToken")
                                    println("Device token was set successfully.")
                                }
                                println("UUID was set successfully.")
                                println("Received user ID: \(self.userID)")
                            }
                        }
                    }
                }
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("User allows notifications.")
        var deviceTokenString = deviceToken.description
        deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString("<", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        deviceTokenString = deviceTokenString.stringByReplacingOccurrencesOfString(">", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        if userID == 0 {
            register(deviceToken: deviceTokenString)
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println(error.localizedDescription)
        if userID == 0 {
            register()
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            notificationAlbumID = userInfo["ID"] as! Int
            println("Received notification with ID: \(notificationAlbumID)")
            // Called when the notification is tapped if the app is inactive or in the background
            if application.applicationState == .Inactive || application.applicationState == .Background {
                NSNotificationCenter.defaultCenter().postNotificationName("showAlbum", object: nil, userInfo: userInfo)
            }
        }
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        if identifier == "APP_ACTION" {
            NSNotificationCenter.defaultCenter().postNotificationName("appActionPressed", object: nil, userInfo: notification.userInfo)
            if let userInfo = notification.userInfo {
                localNotificationPayload = userInfo
            }
        } else {
            delay(0) {
                if let userInfo = notification.userInfo {
                    let url = userInfo["url"]! as! String
                    if UIApplication.sharedApplication().canOpenURL(NSURL(string: url)!) {
                        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
                    }
                }
            }
        }
        completionHandler()
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        if identifier == "APP_ACTION" {
            
        } else {
            
        }
        completionHandler()
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Received remote notification while the app was running.")
        NSNotificationCenter.defaultCenter().postNotificationName("refreshApp", object: nil)
        completionHandler(UIBackgroundFetchResult.NoData)
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        // -- Background fetch -- //
        completionHandler(UIBackgroundFetchResult.NoData)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        // -- Background App Refresh -- //
        
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
}
