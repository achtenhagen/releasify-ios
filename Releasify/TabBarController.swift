//
//  TabBarController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/12/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit

class TabBarController: UITabBarController {
	
	weak var notificationDelegate: AppControllerDelegate?
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var navController: AppController!
	var theme: Theme!
	var streamController: StreamViewController!
	var subscriptionController: SubscriptionController!
	var mediaQuery: MPMediaQuery!	
	var responseArtists: [NSDictionary]!
	var keyword: String!
	var favListBarBtn: UIBarButtonItem!
	var addBarBtn: UIBarButtonItem!
	
	@IBAction func showFavoritesList(sender: UIBarButtonItem) {
		Favorites.sharedInstance.load()
		menuPressed()
	}

	@IBAction func addSubscription(sender: AnyObject) {
		self.performSegueWithIdentifier("AddSubscriptionSegue", sender: self)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

		theme = appDelegate.theme
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(addSubscriptionFromShortcutItem), name: "addSubscriptionShortcutItem", object: nil)
		mediaQuery = MPMediaQuery.artistsQuery()

		// StoreKit API | Check for user store front
		if let storeFront = NSUserDefaults.standardUserDefaults().valueForKey("userStoreFront") as? String {
			appDelegate.userStoreFront = storeFront
		} else {
			StorefrontAssistant.countryCode { (countryCode, error) in
				if let error = error {
					if self.appDelegate.debug { print("An error occured setting the store front (\(error))") }
					return
				}
				if let countryCode = countryCode {
					NSUserDefaults.standardUserDefaults().setValue(countryCode, forKey: "userStoreFront")
					if self.appDelegate.debug { print("Store front has been set (\(countryCode))") }
				}
			}
		}

		// StoreKit API | Check users media library capabilities
		if let canAddToLibrary = NSUserDefaults.standardUserDefaults().valueForKey("canAddToLibrary") as? Bool {
			self.appDelegate.canAddToLibrary = canAddToLibrary
		} else {
			if #available(iOS 9.3, *) {
				if SKCloudServiceController.authorizationStatus() == .Authorized {
					let controller = SKCloudServiceController()
					controller.requestCapabilitiesWithCompletionHandler { (capability, error) in
						if capability.rawValue >= 256 {
							self.appDelegate.canAddToLibrary = true
							NSUserDefaults.standardUserDefaults().setBool(true, forKey: "canAddToLibrary")
							if self.appDelegate.debug { print("User can add to music library.") }
						}
					}
				}
			} else {
				NSUserDefaults.standardUserDefaults().setBool(false, forKey: "canAddToLibrary")
			}
		}

		// Navigation bar setup
		navController = self.navigationController as! AppController

		// Navigation bar items
		favListBarBtn = self.navigationController?.navigationBar.items![0].leftBarButtonItem
		favListBarBtn.tintColor = theme.globalTintColor
		addBarBtn = self.navigationController?.navigationBar.items![0].rightBarButtonItem
		addBarBtn.tintColor = theme.globalTintColor

		// Prevent both bar button items from being pressed at the same time
		for view in (self.navigationController?.navigationBar.subviews)! {
			view.exclusiveTouch = true
		}

		// Navigation item title view
		let titleImageName = theme.style == .Dark ? "icon_navbar" : "icon_navbar_alt"
		let titleImage = UIImageView(image: UIImage(named: titleImageName))
		titleImage.sizeToFit()
		self.navigationItem.titleView = titleImage

		// Theme customizations
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		} else {
			self.view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1)
		}

		// Add 1px border to top of tab bar
		let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: self.tabBar.frame.size.width, height: 1))
		topBorder.backgroundColor = theme.tabBarTopBorderColor
		self.tabBar.addSubview(topBorder)

		// Initialize view controllers
		if streamController == nil {
			streamController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("StreamController") as! StreamViewController
			streamController.delegate = notificationDelegate
		}
		if subscriptionController == nil {
			subscriptionController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SubscriptionController") as! SubscriptionController
		}
		self.setViewControllers([streamController, subscriptionController], animated: true)

		// Handle 3D Touch quick action while app is not running
		if let shortcutItem = appDelegate.shortcutKeyDescription {
			if shortcutItem == "add-subscription" {
				addSubscriptionFromShortcutItem()
			}
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func menuPressed() {		
		navController.openAndCloseMenu()
	}

	// MARK: - Handle 3D Touch quick action
	func addSubscriptionFromShortcutItem() {
		self.performSegueWithIdentifier("AddSubscriptionSegue", sender: self)
	}
	
	// MARK: - Handle failed subscription
	func handleAddSubscriptionError(error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = NSLocalizedString("ALERT_OFFLINE_TITLE", comment: "The title for the alert controller")
			alert.message = NSLocalizedString("ALERT_OFFLINE_MESSAGE", comment: "The message for the alert controller")
			let alertActionTitle = NSLocalizedString("ALERT_ACTION_SETTINGS", comment: "The title for the alert controller action")
			alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		case API.Error.ServerDownForMaintenance:
			alert.title = NSLocalizedString("ALERT_MAINTENANCE_TITLE", comment: "The title for the alert controller")
			alert.message = NSLocalizedString("ALERT_MAINTENANCE_MESSAGE", comment: "The message for the alert controller")
		default:
			alert.title = NSLocalizedString("ALERT_UPDATE_FAILED_TITLE", comment: "The title for the alert controller")
			alert.message = NSLocalizedString("ALERT_UPDATE_FAILED_MESSAGE", comment: "The message for the alert controller")
		}
		let title = NSLocalizedString("ALERT_ACTION_OK", comment: "The title for the alert controller action")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// MARK: - Error Message Handler
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = NSLocalizedString("ALERT_OFFLINE_TITLE", comment: "The title for the alert controller")
			alert.message = NSLocalizedString("ALERT_OFFLINE_MESSAGE", comment: "The message for the alert controller")
			let alertActionTitle = NSLocalizedString("ALERT_ACTION_SETTINGS", comment: "The title for the alert controller action")
			alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = title
			alert.message = message
		}
		let title = NSLocalizedString("ALERT_ACTION_OK", comment: "The title for the alert controller action")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}

	// Create 1px image from color component
	func onePixelImageFromColor(color: UIColor) -> UIImage {
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let context = CGBitmapContextCreate(nil, 1, 1, 8, 0, colorSpace, bitmapInfo.rawValue)
		CGContextSetFillColorWithColor(context, color.CGColor)
		CGContextFillRect(context, CGRectMake(0, 0, 1, 1))
		let image = UIImage(CGImage: CGBitmapContextCreateImage(context)!)
		return image
	}
}
