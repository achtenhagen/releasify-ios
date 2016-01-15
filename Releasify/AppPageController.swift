//
//  AppPageController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 8/18/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

protocol AppPageControllerDelegate: class {
	func addNotificationView (notification: Notification)
}

class AppPageController: UIPageViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var albumController: AlbumController!
	var subscriptionsController: SubscriptionController!
	var segmentedControl: UISegmentedControl!
	var responseArtists: [NSDictionary]!
	var mediaQuery: MPMediaQuery!
	var identifiers: NSArray = ["AlbumController", "SubscriptionController"]
	var keyword: String!
	
	@IBOutlet weak var notificationsBtn: UIBarButtonItem!
	
	@IBAction func addSubscription(sender: AnyObject) {
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 {
			let controller = UIAlertController(title: "How would you like to add your subscription?", message: nil, preferredStyle: .ActionSheet)
			let importAction = UIAlertAction(title: "Music Library", style: .Default, handler: { action in
				self.performSegueWithIdentifier("ArtistPickerSegue", sender: self)
			})
			let addAction = UIAlertAction(title: "Enter Artist Title", style: .Default, handler: { action in
				self.addSubscription({ error in
					self.handleAddSubscriptionError(error)
				})
			})
			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			controller.addAction(addAction)
			controller.addAction(importAction)
			controller.addAction(cancelAction)
			presentViewController(controller, animated: true, completion: nil)
		} else {
			self.addSubscription({ error in
				self.handleAddSubscriptionError(error)
			})
		}
	}
	
	func changeView (sender: UISegmentedControl) {
		let viewControllers: NSArray
		if sender.selectedSegmentIndex == 0 {
			let startVC = viewControllerAtIndex(0) as! AlbumController
			viewControllers = NSArray(object: startVC)
			setViewControllers(viewControllers as? [UIViewController], direction: .Reverse, animated: true, completion: nil)
		} else {
			let startVC = viewControllerAtIndex(1) as! SubscriptionController
			viewControllers = NSArray(object: startVC)
			setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
		}
	}
	
	override func loadView() {
		super.loadView()
		
		let containerBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: 50))
		containerBar.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
		containerBar.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)
		containerBar.translucent = false
		
		segmentedControl = UISegmentedControl(items: ["Albums", "Subscriptions"])
		segmentedControl.frame = CGRect(x: 10, y: 10, width: containerBar.bounds.width - 20, height: 30)
		segmentedControl.backgroundColor = UIColor.clearColor()
		segmentedControl.layer.cornerRadius = 5.0
		segmentedControl.selectedSegmentIndex = 0
		segmentedControl.addTarget(self, action: "changeView:", forControlEvents: .ValueChanged)
		
		containerBar.addSubview(segmentedControl)
		view.addSubview(containerBar)
		
		albumController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AlbumController") as! AlbumController
		subscriptionsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SubscriptionController") as! SubscriptionController
	}
	
	override func viewDidLoad () {
		dataSource = self
		delegate = self
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"addSubscriptionFromShortcutItem", name: "addSubscriptionShortcutItem", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"updateNotificationButton", name: "updateNotificationButton", object: nil)
		
		let startingViewController = viewControllerAtIndex(0)
		setViewControllers([startingViewController!], direction: .Forward, animated: false, completion: nil)
		
		let gradient = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
		
		if let shortcutItem = appDelegate.shortcutKeyDescription {
			if shortcutItem == "add-subscription" {
				self.addSubscription({ error in
					self.handleAddSubscriptionError(error)
				})
			}
		}
		
		mediaQuery = MPMediaQuery.artistsQuery()
		notificationsBtn.enabled = (UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false)
	}
	
	func viewControllerAtIndex (index: Int) -> UIViewController? {
		if index == 0 {
			albumController.delegate = self
			return albumController
		}
		if index == 1 {
			return subscriptionsController
		}
		return nil
	}
	
	func updateNotificationButton () {
		notificationsBtn.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
	}
	
	func addSubscriptionFromShortcutItem () {
		addSubscription({ error in
			self.handleAddSubscriptionError(error)
		})
	}
	
	func addSubscription (errorHandler: ((error: ErrorType) -> Void)) {
		responseArtists = [NSDictionary]()
		let actionSheetController = UIAlertController(title: "New Subscription", message: "Please enter the name of the artist you would like to be subscribed to.", preferredStyle: .Alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		actionSheetController.addAction(cancelAction)
		let addAction = UIAlertAction(title: "Confirm", style: .Default) { action in
			let textField = actionSheetController.textFields![0] 
			if !textField.text!.isEmpty {
				let artist = textField.text!.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
				let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&title[]=\(artist)"
				self.keyword = artist
				API.sharedInstance.sendRequest(API.Endpoint.submitArtist.url(), postString: postString, successHandler: { (statusCode, data) in
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
					
					guard let successArtists: [NSDictionary] = json["success"] as? [NSDictionary] else {
						errorHandler(error: API.Error.FailedToParseJSON)
						return
					}
					
					guard let failedArtists: [NSDictionary] = json["failed"] as? [NSDictionary] else {
						errorHandler(error: API.Error.FailedToParseJSON)
						return
					}
					
					for artist in pendingArtists {
						if let uniqueID = artist["iTunesUniqueID"] as? Int {
							if AppDB.sharedInstance.getArtistByUniqueID(uniqueID) == 0 {
								self.responseArtists.append(artist)
							}
						}
					}
					
					for artist in successArtists {
						let artistID = artist["artistID"] as! Int
						let artistTitle = (artist["title"] as? String)!						
						let artistUniqueID = artist["iTunesUniqueID"] as! Int
						if AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID) > 0 {
							AppDB.sharedInstance.getArtists()
							NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
							NSNotificationCenter.defaultCenter().postNotificationName("refreshSubscriptions", object: nil, userInfo: nil)
							let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
							notification.title.text = "Subscribed to \(artistTitle)."
							notification.subtitle.text = "You will be notified of new content by this artist."
							self.view.addSubview(notification)
							NotificationQueue.sharedInstance.add(notification)
						}
					}
					
					for artist in failedArtists {
						let title = (artist["title"] as? String)!
						let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
						notification.title.text = title
						notification.subtitle.text = "was not found on iTunes."
						self.view.addSubview(notification)
						NotificationQueue.sharedInstance.add(notification)
					}
					
					
					if self.responseArtists.count > 0 {
						self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
					}
					
					},
					errorHandler: { (error) in
						self.handleAddSubscriptionError(error)
				})
			}
		}
		actionSheetController.addAction(addAction)
		actionSheetController.addTextFieldWithConfigurationHandler { textField in
			textField.keyboardAppearance = .Dark
			textField.autocapitalizationType = .Words
			textField.placeholder = "e.g., Armin van Buuren"
		}
		presentViewController(actionSheetController, animated: true, completion: nil)
	}
	
	func handleAddSubscriptionError (error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = "Unable to update!"
			alert.message = "Please try again later."
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	override func prepareForSegue (segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ArtistPickerSegue" {
			let artistPickerController = segue.destinationViewController as! ArtistsPicker
			artistPickerController.collection = mediaQuery.collections!
		} else if segue.identifier == "ArtistSelectionSegue" {
			let selectionController = segue.destinationViewController as! SearchResultsController
			selectionController.artists = responseArtists
			selectionController.keyword = keyword
		}
	}
}

// MARK: - UIPageViewControllerDataSource
extension AppPageController: UIPageViewControllerDataSource {
	func pageViewController (pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = identifiers.indexOfObject(identifier!)
		if index == identifiers.count - 1 { return nil }
		index++
		return viewControllerAtIndex(index)
	}
	
	func pageViewController (pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = identifiers.indexOfObject(identifier!)
		if index == 0 { return nil }
		index--
		return viewControllerAtIndex(index)
	}
}

// MARK: - UIPageViewControllerDelegate
extension AppPageController: UIPageViewControllerDelegate {
	func pageViewController (pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		segmentedControl.selectedSegmentIndex = 0
		if pageViewController.viewControllers![0].restorationIdentifier == "SubscriptionController" {
			segmentedControl.selectedSegmentIndex = 1
		}
	}
}

// MARK: - AppPageControllerDelegate
extension AppPageController: AppPageControllerDelegate {
	func addNotificationView (notification: Notification) {
		view.addSubview(notification)
	}
}
