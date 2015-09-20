//
//  AppPageController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 8/18/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class AppPageController: UIPageViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var responseArtists = [NSDictionary]()
	var mediaQuery = MPMediaQuery.artistsQuery()
	var identifiers: NSArray = ["AlbumsController", "SubscriptionsController"]
	var keyword: String!
	
	@IBOutlet weak var notificationsBtn: UIBarButtonItem!
	
	@IBAction func addSubscription(sender: AnyObject) {
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 {
			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
			let importAction = UIAlertAction(title: "Music Library", style: .Default, handler: { action in
				self.performSegueWithIdentifier("ArtistPickerSegue", sender: self)
			})
			let addAction = UIAlertAction(title: "Enter Artist Title", style: .Default, handler: { action in
				self.addSubscription()
			})
			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			controller.addAction(importAction)
			controller.addAction(addAction)
			controller.addAction(cancelAction)
			presentViewController(controller, animated: true, completion: nil)
		} else {
			addSubscription()
		}
	}
	
	override func viewDidLoad() {
		dataSource = self
		delegate = self
		let startingViewController = viewControllerAtIndex(0)
		setViewControllers([startingViewController!], direction: .Forward, animated: false, completion: nil)
		
		let gradient = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
		
		notificationsBtn.enabled = (UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false)
	}
	
	func viewControllerAtIndex(index: Int) -> UIViewController? {
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		if index == 0 { return storyBoard.instantiateViewControllerWithIdentifier("AlbumsController") }
		if index == 1 { return storyBoard.instantiateViewControllerWithIdentifier("SubscriptionsController") }
		return nil
	}
	
	func addSubscription () {
		responseArtists = [NSDictionary]()
		let prompt = "Please enter the name of the artist you would like to be subscribed to."
		let actionSheetController = UIAlertController(title: "New Subscription", message: prompt, preferredStyle: .Alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		actionSheetController.addAction(cancelAction)
		let addAction = UIAlertAction(title: "Confirm", style: .Default) { action in
			let textField = actionSheetController.textFields![0] 
			if !textField.text!.isEmpty {
				let artist = textField.text!.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
				let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&title[]=\(artist)"
				self.keyword = artist
				API.sharedInstance.sendRequest(API.URL.submitArtist.rawValue, postString: postString, successHandler: { (statusCode, data) in
					if statusCode == 202 {
						if let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as? NSDictionary {
							if let pendingArtists: [NSDictionary] = json["pending"] as? [NSDictionary] {
								for artist in pendingArtists {
									if let uniqueID = artist["iTunesUniqueID"] as? Int {
										if AppDB.sharedInstance.getArtistByUniqueID(uniqueID) == 0 {
											self.responseArtists.append(artist)
										}
									}
								}
							}
							if let successArtists: [NSDictionary] = json["success"] as? [NSDictionary] {
								for artist in successArtists {
									let artistID = artist["artistId"] as! Int
									let artistTitle = (artist["title"] as? String)!
									let artistUniqueID = artist["iTunesUniqueID"] as! Int
									if AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID) > 0 {
										AppDB.sharedInstance.getArtists()
										let startingViewController = self.viewControllerAtIndex(0)
										if startingViewController!.restorationIdentifier != "AlbumsController" {
											self.setViewControllers([startingViewController!], direction: .Reverse, animated: true, completion: { bool in
												NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
											})
										} else {
											NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
										}
										print("You've successfully subscribed to \(artistTitle).")
									}
								}
							}
							if let failedArtists: [NSDictionary] = json["failed"] as? [NSDictionary] {
								for artist in failedArtists {
									let title = (artist["title"] as? String)!
									print("Artist \(title) was not found on iTunes.")
								}
							}
						}
						AppDB.sharedInstance.getArtists()
						if self.responseArtists.count > 0 {
							self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
						}
					}
					},
					errorHandler: { (error) in
						let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
						switch (error) {
						case API.Error.BadRequest:
							alert.title = "400 Bad Request"
							alert.message = "Missing Parameter."
						case API.Error.Unauthorized:
							alert.title = "403 Forbidden"
							alert.message = "Invalid Credentials."
							alert.addAction(UIAlertAction(title: "Fix it!", style: .Default, handler: { action in
								// Request new ID from server.
							}))
						case API.Error.RequestEntityTooLarge:
							alert.title = "413 Request Entity Too Large"
							alert.message = "Received batch is too large."
						case API.Error.InternalServerError:
							alert.title = "500 Internal Server Error"
							alert.message = "An error on our end occured."
						default:
							alert.title = "Oops! Something went wrong."
							alert.message = "An unknown error occured."
						}
						alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
						self.presentViewController(alert, animated: true, completion: nil)
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
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = identifiers.indexOfObject(identifier!)
		if index == identifiers.count - 1 { return nil }
		index++
		return viewControllerAtIndex(index)
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let identifier = viewController.restorationIdentifier
		var index = identifiers.indexOfObject(identifier!)
		if index == 0 { return nil }
		index--
		return self.viewControllerAtIndex(index)
	}
}

// MARK: - UIPageViewControllerDelegate
extension AppPageController: UIPageViewControllerDelegate {
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		navigationController?.navigationBar.topItem?.title = "Music"
		if pageViewController.viewControllers![0].restorationIdentifier == "SubscriptionsController" { navigationController?.navigationBar.topItem?.title = "Subscriptions" }
	}
}
