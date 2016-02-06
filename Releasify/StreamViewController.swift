//
//  StreamViewController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/4/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

protocol StreamViewControllerDelegate: class {
	func removeAlbum (album: Album, indexPath: NSIndexPath)
}

class StreamViewController: UITableViewController {
	
	weak var delegate: AppControllerDelegate?
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let reuseIdentifier = "streamCell"
	var searchController: UISearchController!
	var selectedAlbum: Album!
	var filteredData: [Artist]!
	var tmpArtwork: [String:UIImage]?
	var tmpUrl: [Int:String]?
	var responseArtists: [NSDictionary]!
	var mediaQuery: MPMediaQuery!
	var notificationAlbumID: Int?
	var keyword: String!
	var footerLabel: UILabel!

	@IBOutlet var albumTableView: UITableView!
	
	@IBAction func addSubscription(sender: AnyObject) {
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 {
			let controller = UIAlertController(title: "How would you like to add your subscription?", message: nil, preferredStyle: .ActionSheet)
			let importAction = UIAlertAction(title: "Music Library", style: .Default, handler: { action in
				self.performSegueWithIdentifier("ArtistPickerSegue", sender: self)
			})
			let addAction = UIAlertAction(title: "Enter Artist Title", style: .Default, handler: { action in
				self.addSubscription({ (error) in
					self.handleAddSubscriptionError(error)
				})
			})
			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			controller.addAction(addAction)
			controller.addAction(importAction)
			controller.addAction(cancelAction)
			self.presentViewController(controller, animated: true, completion: nil)
		} else {
			self.addSubscription({ (error) in
				self.handleAddSubscriptionError(error)
			})
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tmpArtwork = [String:UIImage]()
		
		if #available(iOS 9.0, *) {
			if traitCollection.forceTouchCapability == .Available {
				self.registerForPreviewingWithDelegate(self, sourceView: albumTableView)
			}
		}
		
		registerLongPressGesture()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromRemoteNotification:", name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshContent", object: nil)
		
		let logo = UIImage(named: "icon_navbar.png")
		let imageView = UIImageView(image:logo)
		self.navigationItem.titleView = imageView
		
		self.searchController = UISearchController(searchResultsController: nil)
		self.searchController.delegate = self
		self.searchController.searchResultsUpdater = self
		self.searchController.dimsBackgroundDuringPresentation = false
		self.searchController.hidesNavigationBarDuringPresentation = false
		self.searchController.searchBar.placeholder = "Search artists & albums"
		self.searchController.searchBar.searchBarStyle = .Minimal
		self.searchController.searchBar.barStyle = .Black
		self.searchController.searchBar.barTintColor = UIColor.clearColor()
		self.searchController.searchBar.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1.0)
		self.searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
		self.searchController.searchBar.layer.borderWidth = 1
		self.searchController.searchBar.translucent = false
		self.searchController.searchBar.autocapitalizationType = .Words
		self.searchController.searchBar.keyboardAppearance = .Dark
		self.searchController.searchBar.sizeToFit()
		self.albumTableView.tableHeaderView = self.searchController.searchBar
		
		if #available(iOS 9.0, *) {
			self.searchController.loadViewIfNeeded()
		} else {
			let _ = self.searchController.view
		}
		
		// Only applies to dark theme
//		let gradient = CAGradientLayer()
//		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
//		gradient.locations = [0.0 , 1.0]
//		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
//		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
//		gradient.frame = albumTableView.bounds
//		let backgroundView = UIView(frame: albumTableView.bounds)
//		backgroundView.layer.insertSublayer(gradient, atIndex: 0)
//		albumTableView.backgroundView = backgroundView
//		albumTableView.backgroundView?.layer.zPosition -= 1
		
		if let shortcutItem = appDelegate.shortcutKeyDescription {
			if shortcutItem == "add-subscription" {
				self.addSubscription({ (error) in
					self.handleAddSubscriptionError(error)
				})
			}
		}
		
		mediaQuery = MPMediaQuery.artistsQuery()
		
		refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl!.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		albumTableView.addSubview(refreshControl!)
		
		// Process remote notification payload
		if let remoteContent = appDelegate.remoteNotificationPayload {
			processRemoteNotificationPayload(remoteContent)
		}
		
		// Process local notification payload
		if let localContent = appDelegate.localNotificationPayload?["albumID"] as? Int {
			notificationAlbumID = localContent
			if AppDB.sharedInstance.albums != nil {
				for album in AppDB.sharedInstance.albums as[Album]! {
					if album.ID == notificationAlbumID! {
						selectedAlbum = album
						break
					}
				}
				if selectedAlbum.ID == notificationAlbumID! {
					self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
				}
			}
		}
		
		if !appDelegate.completedRefresh {
			refresh()
		}
		
		albumTableView.setContentOffset(CGPoint(x: 0, y: 44), animated: true)
		definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Refresh Content
	func refresh() {
		API.sharedInstance.refreshContent({ newItems in
			self.albumTableView.reloadData()
			self.refreshControl!.endRefreshing()
			if self.appDelegate.firstRun {
				let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
				notification.title.text = "Welcome to Releasify!"
				notification.subtitle.text = "Swipe left to manage your subscriptions."
				self.delegate?.addNotificationView(notification)
				NotificationQueue.sharedInstance.add(notification)
				self.appDelegate.firstRun = false
			}
			if newItems.count > 0 {
				self.albumTableView.hidden = false
				let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
				notification.title.text = "\(newItems.count) Album\(newItems.count == 1 ? "" : "s")"
				notification.subtitle.text = "\(newItems.count == 1 ? "has been added to your stream." : "have been added to your stream.")"
				let artwork = UIImageView(frame: CGRect(x: notification.frame.width - 50, y: 5, width: 45, height: 45))
				artwork.contentMode = .ScaleToFill
				artwork.layer.masksToBounds = true
				artwork.layer.cornerRadius = 2
				
				// Retrieve the artwork preview thumbnail
				self.fetchArtwork(newItems[0], successHandler: { thumb in
					artwork.image = thumb
					}, errorHandler: {
						artwork.image = UIImage(named: "icon_artwork_placeholder")
				})
				
				notification.notificationView.addSubview(artwork)
				if self.delegate != nil {
					self.delegate?.addNotificationView(notification)
				}
				NotificationQueue.sharedInstance.add(notification)
			}
			},
			errorHandler: { (error) in
				self.refreshControl!.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)
		})
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
		let addAction = UIAlertAction(title: "Confirm", style: .Default) { action in
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
					
					if artistFound && self.responseArtists.count == 0 {
						let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
						notification.title.text = "Unable to add subscription"
						notification.subtitle.text = "you are already subscribed to this artist."
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
		actionSheetController.addTextFieldWithConfigurationHandler { textField in
			textField.keyboardAppearance = .Dark
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
	
	// MARK: - Open album from a local notification
	func showAlbumFromNotification(notification: NSNotification) {
		if let AlbumID = notification.userInfo!["albumID"]! as? Int {
			notificationAlbumID = AlbumID
			for album in AppDB.sharedInstance.albums as [Album]! {
				if album.ID != notificationAlbumID! { continue }
				selectedAlbum = album
				break
			}
			guard let album = selectedAlbum else { return }
			if album.ID == notificationAlbumID! {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
	}
	
	// MARK: - Open album from a remote notification
	func showAlbumFromRemoteNotification(notification: NSNotification) {
		processRemoteNotificationPayload(notification.userInfo!)
	}
	
	// MARK: - Process remote notification payload
	func processRemoteNotificationPayload(userInfo: NSDictionary) {
		UIApplication.sharedApplication().applicationIconBadgeNumber--
		if let albumID = userInfo["aps"]?["albumID"] as? Int {
			API.sharedInstance.lookupAlbum(albumID, successHandler: { album in
				if AppDB.sharedInstance.addAlbum(album) == 0 {
					self.selectedAlbum = album
					self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
					return
				}
				self.fetchArtwork(album.artwork, successHandler: { artwork in
					if AppDB.sharedInstance.addArtwork(album.artwork, artwork: artwork!) {
						self.selectedAlbum = album
						self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
					}
					}, errorHandler: {
						self.handleError("Unable to download artwork!", message: "Please try again later.", error: API.Error.FailedToGetResource)
				})
				}, errorHandler: { (error) in
					self.handleError("Failed to lookup album!", message: "Please try again later.", error: error)
			})
		}
	}
	
	// MARK: - Error Message Handler
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = title
			alert.message = message
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// MARK: - Compute the floor of 2 numbers
	func component(x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	// MARK: - Register long press gesture if 3D Touch is unavailable
	func registerLongPressGesture() {
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 1.0
		albumTableView.addGestureRecognizer(longPressGesture)
	}
	
	// MARK: - Handle long press gesture
	func longPressGestureRecognized(gesture: UIGestureRecognizer) {
		let cellLocation = gesture.locationInView(albumTableView)
		let indexPath = albumTableView.indexPathForRowAtPoint(cellLocation)
		if indexPath == nil { return }
		if indexPath?.row == nil { return }
		if gesture.state == UIGestureRecognizerState.Began {
			let shareActivityItem = "Buy this album on iTunes:\n\(AppDB.sharedInstance.albums[indexPath!.row].iTunesUrl)"
			let activityViewController = UIActivityViewController(activityItems: [shareActivityItem], applicationActivities: nil)
			self.presentViewController(activityViewController, animated: true, completion: nil)
		}
	}
	
	// MARK: - Handle unsubscribe album
	func unsubscribe_album(iTunesUniqueID: Int, successHandler: () -> Void, errorHandler: (error: ErrorType) -> Void) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&iTunesUniqueID=\(iTunesUniqueID)"
		API.sharedInstance.sendRequest(API.Endpoint.removeAlbum.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 204 {
				errorHandler(error: API.Error.FailedRequest)
				return
			}
			successHandler()
			},
			errorHandler: { (error) in
				self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
		})
	}
	
	// MARK: - Fetch Artwork
	func fetchArtwork(hash: String, successHandler: ((image: UIImage?) -> Void), errorHandler: (() -> Void)) {
		if hash.isEmpty { errorHandler(); return }
		let subDir = (hash as NSString).substringWithRange(NSRange(location: 0, length: 2))
		let albumURL = "https://releasify.me/static/artwork/music/\(subDir)/\(hash)@2x.jpg"
		guard let checkedURL = NSURL(string: albumURL) else { errorHandler(); return }
		let request = NSURLRequest(URL: checkedURL)
		NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
			if error != nil { errorHandler(); return }
			guard let HTTPResponse = response as? NSHTTPURLResponse else { errorHandler(); return }
			if HTTPResponse.statusCode != 200 { errorHandler(); return }
			guard let imageData = UIImage(data: data!) else { errorHandler(); return }
			successHandler(image: imageData)
		})
	}
	
	// MARK: - Return artwork image for each collection view cell
	func getArtworkForCell(hash: String, completion: ((artwork: UIImage) -> Void)) {
		if AppDB.sharedInstance.checkArtwork(hash) {
			tmpArtwork![hash] = AppDB.sharedInstance.getArtwork(hash)
		} else {
			if tmpArtwork![hash] != nil {
				tmpArtwork?.removeValueForKey(hash)
			}
		}
		guard let tmpImage = tmpArtwork![hash] else {
			fetchArtwork(hash, successHandler: { artwork in
				AppDB.sharedInstance.addArtwork(hash, artwork: artwork!)
				self.tmpArtwork![hash] = artwork
				completion(artwork: artwork!)
				}, errorHandler: {
					completion(artwork: UIImage(named: "icon_artwork_placeholder")!)
			})
			return
		}
		completion(artwork: tmpImage)
	}
	
	// MARK: - Search function for UISearchResultsUpdating
	func filterContentForSearchText(searchText: String) {
		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({(artist: Artist) -> Bool in
			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
		})
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
		}
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return AppDB.sharedInstance.albums.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! StreamCell
		let album = AppDB.sharedInstance.albums[indexPath.row]
		let timeDiff = album.releaseDate - NSDate().timeIntervalSince1970
		
		cell.artwork.image = UIImage(named: "icon_artwork_placeholder")!
		getArtworkForCell(album.artwork, completion: { artwork in
			cell.artwork.image = artwork
		})
		
		cell.artistTitle.text = AppDB.sharedInstance.getAlbumArtist(album.ID)
		cell.albumTitle.text = album.title
		cell.albumTitle.userInteractionEnabled = false
		
		if timeDiff > 0 {
			let weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
			let days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
			let hours   = component(Double(timeDiff),      v: 60 * 60) % 24
			let minutes = component(Double(timeDiff),           v: 60) % 60
			let seconds = component(Double(timeDiff),            v: 1) % 60
			
			if Int(weeks) > 0 {
				cell.timeLabel.text = "\(Int(weeks)) weeks"
				if Int(weeks) == 1  {
					cell.timeLabel.text = "\(Int(weeks)) week"
				}
			} else if Int(days) > 0 && Int(days) <= 7 {
				cell.timeLabel.text = "\(Int(days)) days"
				if Int(days) == 1  {
					cell.timeLabel.text = "\(Int(days)) day"
				}
			} else if Int(hours) > 0 && Int(hours) <= 24 {
				if Int(hours) >= 12 {
					cell.timeLabel.text = "Today"
				} else {
					cell.timeLabel.text = "\(Int(hours)) hours"
					if Int(hours) == 1  {
						cell.timeLabel.text = "\(Int(hours)) hour"
					}
				}
			} else if Int(minutes) > 0 && Int(minutes) <= 60 {
				cell.timeLabel.text = "\(Int(minutes)) minute"
			} else if Int(seconds) > 0 && Int(seconds) <= 60 {
				cell.timeLabel.text = "\(Int(seconds)) second"
			}
		} else {
			cell.timeLabel.text = "Feb 4"
		}
		
		if tmpUrl == nil {
			tmpUrl = [Int: String]()
		}
		
		if tmpUrl![album.ID] == nil {
			tmpUrl![album.ID] = album.iTunesUrl
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedAlbum = AppDB.sharedInstance.albums[indexPath.row]
		self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
	}
	
	override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
		// albumTableView.cellForRowAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
		// albumTableView.cellForRowAtIndexPath(indexPath)?.alpha = 1.0
	}
	
	override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let starAction = UITableViewRowAction(style: .Normal, title: "        ", handler: { (action, indexPath) -> Void in
			// Add to favorites...
		})
		starAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_star")!)
		let buyAction = UITableViewRowAction(style: .Normal, title: "        ", handler: { (action, indexPath) -> Void in
			let albumID = AppDB.sharedInstance.albums[indexPath.row].ID
			guard let albumUrl = self.tmpUrl![albumID] else { return }
			if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumUrl)!) {
				UIApplication.sharedApplication().openURL(NSURL(string: albumUrl)!)
			}
		})
		buyAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_buy")!)
		let removeAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "        ", handler: { (action, indexPath) -> Void in
			let albumID = AppDB.sharedInstance.albums[indexPath.row].ID
			if !AppDB.sharedInstance.albums[indexPath.row].isAvailable() {
				for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
					let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
					let ID = userInfoCurrent["albumID"]! as! Int
					if ID == albumID {
						UIApplication.sharedApplication().cancelLocalNotification(notification)
						break
					}
				}
			}
			let iTunesUniqueID = AppDB.sharedInstance.albums[indexPath.row].iTunesUniqueID
			let hash = AppDB.sharedInstance.albums[indexPath.row].artwork
			self.unsubscribe_album(iTunesUniqueID, successHandler: {
				AppDB.sharedInstance.deleteAlbum(albumID, index: indexPath.row)
				AppDB.sharedInstance.deleteArtwork(hash)
				if AppDB.sharedInstance.albums.count == 0 {
					if self.numberOfSectionsInTableView(self.albumTableView) > 0 {
						self.albumTableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
					}
				} else {
					self.albumTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
				}
				self.tmpArtwork?.removeValueForKey(hash)
				self.albumTableView.reloadData()
				}, errorHandler: { (error) in
					self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
			})
		})
		removeAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_delete")!)
		return [starAction, buyAction, removeAction]
	}
	
	override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 40))
		footerView.backgroundColor = UIColor.clearColor()
		footerLabel = UILabel()
		footerLabel.alpha = 0
		footerLabel.font = UIFont(name: footerLabel.font.fontName, size: 14)
		// footerLabel.textColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.2)
		footerLabel.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
		footerLabel.text = "\(AppDB.sharedInstance.albums.count) albums, \(AppDB.sharedInstance.artists.count) artists"
		footerLabel.textAlignment = NSTextAlignment.Center
		footerLabel.adjustsFontSizeToFitWidth = true
		footerLabel.sizeToFit()
		footerLabel.center = CGPoint(x: self.view.frame.size.width / 2, y: (footerView.frame.size.height / 2) - 1)
		footerView.addSubview(footerLabel)
		return footerView
	}
	
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		if footerLabel != nil && albumTableView.contentOffset.y >= (albumTableView.contentSize.height - albumTableView.bounds.size.height) {
			footerLabel.fadeIn()
		} else if footerLabel != nil && footerLabel.alpha == 1.0 {
			footerLabel.fadeOut()
		}
	}
}

// MARK: - StreamViewControllerDelegate
extension StreamViewController: StreamViewControllerDelegate {
	func removeAlbum(album: Album, indexPath: NSIndexPath) {
		self.unsubscribe_album(album.iTunesUniqueID, successHandler: {
			AppDB.sharedInstance.deleteAlbum(album.ID, index: indexPath.row)
			AppDB.sharedInstance.deleteArtwork(album.artwork)
			if AppDB.sharedInstance.albums.count == 0 {
				if self.numberOfSectionsInTableView(self.albumTableView) > 0 {
					self.albumTableView.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
				}
			} else {
				self.albumTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
			}
			self.tmpArtwork?.removeValueForKey(album.artwork)
			self.albumTableView.reloadData()
			}, errorHandler: { (error) in
				self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
		})
	}
}

// MARK: - UISearchControllerDelegate
extension StreamViewController: UISearchControllerDelegate {
	func willPresentSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = UIColor.whiteColor()
	}
	
	func willDismissSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = UIColor.clearColor()
	}
}

// MARK: - UISearchResultsUpdating
extension StreamViewController: UISearchResultsUpdating {
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
		albumTableView.reloadData()
	}
}

// MARK: - UIViewControllerPreviewingDelegate
@available(iOS 9.0, *)
extension StreamViewController: UIViewControllerPreviewingDelegate {
	func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = albumTableView.indexPathForRowAtPoint(location), cell = albumTableView.cellForRowAtIndexPath(indexPath) else { return nil }
		guard let albumDetailVC = storyboard?.instantiateViewControllerWithIdentifier("AlbumView") as? AlbumDetailController else { return nil }
		let album = AppDB.sharedInstance.albums[indexPath.row]
		albumDetailVC.delegate = self
		albumDetailVC.album = album
		albumDetailVC.indexPath = indexPath
		albumDetailVC.preferredContentSize = CGSize(width: 0.0, height: 0.0)
		previewingContext.sourceRect = cell.frame
		return albumDetailVC
	}
	
	func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
		self.showViewController(viewControllerToCommit, sender: self)
	}
}
