//
//  TabBarController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/12/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class TabBarController: UITabBarController {
	
	weak var notificationDelegate: AppControllerDelegate?
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var streamController: StreamViewController!
	var subscriptionController: SubscriptionController!
	var mediaQuery: MPMediaQuery!	
	var responseArtists: [NSDictionary]!
	var keyword: String!
	var favListBarBtn: UIBarButtonItem!
	var addBarBtn: UIBarButtonItem!
	
	@IBAction func addSubscription(sender: AnyObject) {
		self.performSegueWithIdentifier("AddSubscriptionSegue", sender: self)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(TabBarController.addSubscriptionFromShortcutItem), name: "addSubscriptionShortcutItem", object: nil)
		mediaQuery = MPMediaQuery.artistsQuery()
		
		favListBarBtn = self.navigationController?.navigationBar.items![0].leftBarButtonItem
		favListBarBtn.tintColor = Theme.sharedInstance.globalTintColor
		addBarBtn = self.navigationController?.navigationBar.items![0].rightBarButtonItem
		addBarBtn.tintColor = Theme.sharedInstance.globalTintColor
		
		let logo = UIImage(named: Theme.sharedInstance.style == .dark ? "icon_navbar.png" : "icon_navbar_alt.png")
		let imageView = UIImageView(image:logo)
		self.navigationItem.titleView = imageView
		
		if Theme.sharedInstance.style == .dark {
			let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: self.tabBar.frame.size.width, height: 2))
			topBorder.backgroundColor = Theme.sharedInstance.tabBarTopBorderColor
			self.tabBar.addSubview(topBorder)
			let gradient = Theme.sharedInstance.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		} else {
			self.view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1.0)
		}

		if streamController == nil {
			streamController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("StreamController") as! StreamViewController
			streamController.delegate = notificationDelegate
		}
		
		if  subscriptionController == nil {
			subscriptionController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SubscriptionController") as! SubscriptionController
		}
		
		self.setViewControllers([streamController, subscriptionController], animated: true)
		
		// 3D Touch quick action while app is not running
		if let shortcutItem = appDelegate.shortcutKeyDescription {
			if shortcutItem == "add-subscription" {
				self.addSubscription({ (error) in
					self.handleAddSubscriptionError(error)
				})
			}
		}
		
		for item in self.tabBar.items! {
			item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Handle 3D Touch quick action
	func addSubscriptionFromShortcutItem() {
		addSubscription({ (error) in
			self.handleAddSubscriptionError(error)
		})
	}
	
	// MARK: - Show new subscription alert controller
	func addSubscription(errorHandler: ((error: ErrorType) -> Void)) {
		responseArtists = [NSDictionary]()
		var artistFound = false
		let actionSheetController = UIAlertController(title: "New Subscription", message: "Please enter the name of the artist you would like to be subscribed to.", preferredStyle: .Alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		actionSheetController.addAction(cancelAction)
		let addAction = UIAlertAction(title: "Confirm", style: .Default) { (action) in
			let textField = actionSheetController.textFields![0]
			if !textField.text!.isEmpty {
				let artist = textField.text!.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
				let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&title[]=\(artist)"
				self.keyword = artist
				API.sharedInstance.sendRequest(API.Endpoint.searchArtist.url(), postString: postString, successHandler: { (statusCode, data) in
					if statusCode != 202 {
						errorHandler(error: API.Error.BadRequest)
						return
					}
					
					guard let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as? NSDictionary else {
						errorHandler(error: API.Error.FailedToParseJSON)
						return
					}
					
					guard let pendingArtists: [NSDictionary] = json["pending"] as? [NSDictionary] else {
						errorHandler(error: API.Error.FailedToParseJSON)
						return
					}
					
					guard let failedArtists: [NSDictionary] = json["failed"] as? [NSDictionary] else {
						errorHandler(error: API.Error.FailedToParseJSON)
						return
					}
					
					for artist in pendingArtists {
						if let uniqueID = artist["iTunesUniqueID"] as? Int {
							if AppDB.sharedInstance.getArtistByUniqueID(uniqueID) > 0 {
								artistFound = true
								continue
							}
							self.responseArtists.append(artist)
						}
					}
					
					if failedArtists.count > 0 {
						let notificationTitle = "Not Found!"
						let notification = Notification(frame: CGRect(x: 0, y: 0, width: 140, height: 140), title: notificationTitle, icon: .error)
						notification.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 50)
						self.view.addSubview(notification)
						NotificationQueue.sharedInstance.add(notification)
					}
					
					if self.responseArtists.count > 0 {
						self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
					}
					
					if artistFound && self.responseArtists.count == 0 {
						let notificationTitle = "Already Subscribed"
						let notification = Notification(frame: CGRect(x: 0, y: 0, width: 140, height: 140), title: notificationTitle, icon: .warning)
						notification.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 50)
						self.view.addSubview(notification)
						NotificationQueue.sharedInstance.add(notification)
					}
					
					},
					errorHandler: { (error) in
						self.handleAddSubscriptionError(error)
				})
			}
		}
		actionSheetController.addAction(addAction)
		actionSheetController.addTextFieldWithConfigurationHandler { (textField) in
			textField.keyboardAppearance = Theme.sharedInstance.keyboardStyle
			textField.autocapitalizationType = .Words
			textField.placeholder = "e.g., Armin van Buuren"
		}
		self.presentViewController(actionSheetController, animated: true, completion: nil)
	}
	
	// MARK: - Handle failed subscription
	func handleAddSubscriptionError(error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = "Unable to update!"
			alert.message = "Please try again later."
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// MARK: - Error Message Handler
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = title
			alert.message = message
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
}
