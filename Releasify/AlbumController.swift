//
//  AlbumController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 8/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

protocol AlbumControllerDelegate: class {
	func removeAlbum (album: Album, indexPath: NSIndexPath)
}

class AlbumController: UIViewController {
	
	weak var delegate: AppPageControllerDelegate?
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let albumCellReuseIdentifier = "AlbumCell"
	var notificationBarItem: UIBarButtonItem?
	var albumCollectionLayout: UICollectionViewFlowLayout!
	var selectedAlbum: Album!
	var tmpArtwork: [String:UIImage]?
	var tmpUrl: [Int:String]?
	var notificationAlbumID: Int?
	var refreshControl: UIRefreshControl!
	
	@IBOutlet weak var emptySubtitle: UILabel!
	@IBOutlet weak var emptyTitle: UILabel!
	@IBOutlet weak var albumCollectionView: UICollectionView!
	
	override func viewDidLoad () {
		super.viewDidLoad()
		tmpArtwork = [String:UIImage]()
		notificationBarItem = navigationController?.navigationBar.items![0].leftBarButtonItem
		
		if #available(iOS 9.0, *) {
		    if traitCollection.forceTouchCapability == .Available {
    			registerForPreviewingWithDelegate(self, sourceView: albumCollectionView)
			} else {
				registerLongPressGesture()
			}
		} else {
			registerLongPressGesture()
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromRemoteNotification:", name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshContent", object: nil)
		
		albumCollectionView.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)
		
		let defaultItemSize = CGSize(width: 145, height: 190)
		albumCollectionLayout = UICollectionViewFlowLayout()
		albumCollectionLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		albumCollectionLayout.itemSize = defaultItemSize
		albumCollectionLayout.minimumLineSpacing = 10
		albumCollectionLayout.minimumInteritemSpacing = 10
		
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			albumCollectionLayout.itemSize = defaultItemSize
		case 375:
			albumCollectionLayout.itemSize = CGSize(width: 172.5, height: 217.5)
		case 414:
			albumCollectionLayout.itemSize = CGSize(width: 192, height: 237)
		default:
			albumCollectionLayout.itemSize = defaultItemSize
		}
		
		albumCollectionView.setCollectionViewLayout(albumCollectionLayout, animated: false)
		
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		albumCollectionView.addSubview(refreshControl)				
		
		// Process remote notification payload
		if let remoteContent = appDelegate.remoteNotificationPayload {
			processRemoteNotificationPayload(remoteContent)
		}
		
		// Process local notification payload
		if let localContent = appDelegate.localNotificationPayload?["albumID"] as? Int {
			notificationAlbumID = localContent
			if AppDB.sharedInstance.albums[1] != nil {
				for album in AppDB.sharedInstance.albums[1] as[Album]! {
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
		
		if AppDB.sharedInstance.albums[0]?.count == 0 && AppDB.sharedInstance.albums[1]?.count == 0 {
			albumCollectionView.hidden = true
			emptyTitle.hidden = false
			emptySubtitle.hidden = false
		}
		
		if !appDelegate.completedRefresh {
			refresh()
		}
	}
	
	override func viewDidAppear (animated: Bool) {
		AppDB.sharedInstance.getAlbums()
		albumCollectionView.reloadData()
		if AppDB.sharedInstance.albums[0]?.count == 0 && AppDB.sharedInstance.albums[1]?.count == 0 && AppDB.sharedInstance.artists.count > 0 {
			emptyTitle.text = "You have no albums yet."
			emptySubtitle.text = "Check back soon for new content!"
		} else {
			emptyTitle.text = "You have no subscriptions yet."
			emptySubtitle.text = "Tap the "+" button above to add one."
		}
	}
	
	override func viewWillAppear (animated: Bool) {
		albumCollectionView.scrollsToTop = true
		notificationBarItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
	}
	
	override func viewWillDisappear (animated: Bool) {
		albumCollectionView.scrollsToTop = false
	}
	
	// MARK: - Refresh Content
	func refresh () {
		API.sharedInstance.refreshContent({ newItems in
			self.albumCollectionView.reloadData()
			self.refreshControl.endRefreshing()
			if self.appDelegate.firstRun {
				let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
				notification.title.text = "Welcome to Releasify!"
				notification.subtitle.text = "Swipe left to manage your subscriptions."
				self.delegate?.addNotificationView(notification)
				NotificationQueue.sharedInstance.add(notification)
				self.appDelegate.firstRun = false
			}
			if newItems.count > 0 {
				self.albumCollectionView.hidden = false
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
			self.notificationBarItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
			},
			errorHandler: { error in
				self.refreshControl.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)
		})
	}
	
	// MARK: - Open album from a local notification
	func showAlbumFromNotification (notification: NSNotification) {
		if let AlbumID = notification.userInfo!["albumID"]! as? Int {
			notificationAlbumID = AlbumID
			for album in AppDB.sharedInstance.albums[1] as [Album]! {
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
	func showAlbumFromRemoteNotification (notification: NSNotification) {
		processRemoteNotificationPayload(notification.userInfo!)
	}
	
	// MARK: - Process remote notification payload
	func processRemoteNotificationPayload (userInfo: NSDictionary) {
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
				}, errorHandler: { error in
					self.handleError("Failed to lookup album!", message: "Please try again later.", error: error)
			})
		}
	}
	
	// MARK: - Error Message Handler
	func handleError (title: String, message: String, error: ErrorType) {
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
	func component (x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	// MARK: - Handle purchase album
	func purchaseAlbum (sender: UIButton) {
		let albumID = sender.tag
		guard let albumUrl = tmpUrl![albumID] else { return }
		if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumUrl)!) {
			UIApplication.sharedApplication().openURL(NSURL(string: albumUrl)!)
		}
	}
	
	// MARK: - Register long press gesture if 3D Touch is unavailable
	func registerLongPressGesture () {
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 0.5
		albumCollectionView.addGestureRecognizer(longPressGesture)
	}
	
	// MARK: - Handle long press gesture
	func longPressGestureRecognized (gesture: UIGestureRecognizer) {
		let cellLocation = gesture.locationInView(albumCollectionView)
		let indexPath = albumCollectionView.indexPathForItemAtPoint(cellLocation)
		if indexPath == nil { return }
		var section = indexPath!.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
			section = sectionAtIndex()
		}
		if indexPath?.row == nil { return }
		if gesture.state == UIGestureRecognizerState.Began {
			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
			var buyTitle = "Pre-Order"
			if section == 1 {
				buyTitle = "Purchase"
			}
			let buyAction = UIAlertAction(title: buyTitle, style: .Default, handler: { action in
				let albumUrl = AppDB.sharedInstance.albums[section]![indexPath!.row].iTunesUrl
				if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumUrl)!) {
					UIApplication.sharedApplication().openURL(NSURL(string: albumUrl)!)
				}
			})
			controller.addAction(buyAction)
			if AppDB.sharedInstance.albums[section]![indexPath!.row].releaseDate - NSDate().timeIntervalSince1970 > 0 {
				let deleteAction = UIAlertAction(title: "Don't Notify", style: .Destructive, handler: { action in
					let albumID = AppDB.sharedInstance.albums[section]![indexPath!.row].ID
					for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
						let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
						let ID = userInfoCurrent["albumID"]! as! Int
						if ID == albumID {
							UIApplication.sharedApplication().cancelLocalNotification(notification)
							self.notificationBarItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
							break
						}
					}
				})
				controller.addAction(deleteAction)
			} else {
				let removeAction = UIAlertAction(title: "Remove Album", style: .Destructive, handler: { action in
					let albumID = AppDB.sharedInstance.albums[section]![indexPath!.row].ID
					let iTunesUniqueID = AppDB.sharedInstance.albums[section]![indexPath!.row].iTunesUniqueID
					let hash = AppDB.sharedInstance.albums[section]![indexPath!.row].artwork
					self.unsubscribe_album(iTunesUniqueID, successHandler: {
						AppDB.sharedInstance.deleteAlbum(albumID, section: section, index: indexPath?.row)
						AppDB.sharedInstance.deleteArtwork(hash)
						if AppDB.sharedInstance.albums[section]!.count == 0 {
							if self.numberOfSectionsInCollectionView(self.albumCollectionView) > 0 {
								self.albumCollectionView.deleteSections(NSIndexSet(index: section))
							}
						} else {
							self.albumCollectionView.deleteItemsAtIndexPaths([indexPath!])
						}
						self.tmpArtwork?.removeValueForKey(hash)
						self.albumCollectionView.reloadData()
						}, errorHandler: { error in
							self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
					})
				})
				controller.addAction(removeAction)
			}
			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			controller.addAction(cancelAction)
			presentViewController(controller, animated: true, completion: nil)
		}
	}
	
	// MARK: - Handle unsubscribe album
	func unsubscribe_album (iTunesUniqueID: Int, successHandler: () -> Void, errorHandler: (error: ErrorType) -> Void) {
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
	func fetchArtwork (hash: String, successHandler: ((image: UIImage?) -> Void), errorHandler: (() -> Void)) {
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
	func getArtworkForCell (hash: String, completion: ((artwork: UIImage) -> Void)) {
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
	
	override func didReceiveMemoryWarning () {
		super.didReceiveMemoryWarning()
	}
	
	override func prepareForSegue (segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
		}
	}
	
	// MARK: - Determine current collection view section (only called when there is a single section)
	func sectionAtIndex () -> Int {
		return AppDB.sharedInstance.albums[0]!.count > 0 ? 0 : 1
	}
}

// MARK: - UICollectionViewDataSource
extension AlbumController: UICollectionViewDataSource {
	func numberOfSectionsInCollectionView (collectionView: UICollectionView) -> Int {
		var sections = 0
		if AppDB.sharedInstance.albums[0]!.count > 0 {
			sections++
		}
		if AppDB.sharedInstance.albums[1]!.count > 0 {
			sections++
		}
		if sections == 0 {
			if !albumCollectionView.hidden {
				albumCollectionView.hidden = true
				emptyTitle.alpha = 0
				emptySubtitle.alpha = 0
				emptyTitle.hidden = false
				emptySubtitle.hidden = false
				UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseOut, animations: {
					self.emptyTitle.alpha = 1
					self.emptySubtitle.alpha = 1
					}, completion: nil)
			}
		} else {
			UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseOut, animations: {
				self.emptyTitle.alpha = 0
				self.emptySubtitle.alpha = 0
				}, completion: { value in
					self.emptyTitle.hidden = true
					self.emptySubtitle.hidden = true
					self.albumCollectionView.hidden = false
			})
		}
		return sections
	}
	
	func collectionView (collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
			return AppDB.sharedInstance.albums[sectionAtIndex()]!.count
		}
		return AppDB.sharedInstance.albums[section]!.count
	}
	
	func collectionView (collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(albumCellReuseIdentifier, forIndexPath: indexPath) as! AlbumCell
		var section = indexPath.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 { section = sectionAtIndex() }
		let album = AppDB.sharedInstance.albums[section]![indexPath.row]
		let timeDiff = album.releaseDate - NSDate().timeIntervalSince1970
		
		cell.albumArtwork.image = UIImage(named: "icon_artwork_placeholder")!
		getArtworkForCell(album.artwork, completion: { artwork in
			cell.albumArtwork.image = artwork
		})
		
		cell.artistTitle.text = AppDB.sharedInstance.getAlbumArtist(album.ID)
		cell.albumTitle.text = album.title
		cell.albumTitle.userInteractionEnabled = false
		cell.containerView.hidden = true
		
		if timeDiff > 0 {
			cell.containerView.hidden = false
		}
		
		let weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
		let days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
		let hours   = component(Double(timeDiff),      v: 60 * 60) % 24
		let minutes = component(Double(timeDiff),           v: 60) % 60
		let seconds = component(Double(timeDiff),            v: 1) % 60
		
		if Int(weeks) > 0 {
			cell.timeLeft.text = "\(Int(weeks)) weeks"
			if Int(weeks) == 1  {
				cell.timeLeft.text = "\(Int(weeks)) week"
			}
		} else if Int(days) > 0 && Int(days) <= 7 {
			cell.timeLeft.text = "\(Int(days)) days"
			if Int(days) == 1  {
				cell.timeLeft.text = "\(Int(days)) day"
			}
		} else if Int(hours) > 0 && Int(hours) <= 24 {
			if Int(hours) >= 12 {
				cell.timeLeft.text = "Today"
			} else {
				cell.timeLeft.text = "\(Int(hours)) hours"
				if Int(hours) == 1  {
					cell.timeLeft.text = "\(Int(days)) hour"
				}
			}
		} else if Int(minutes) > 0 && Int(minutes) <= 60 {
			cell.timeLeft.text = "\(Int(minutes)) minute"
		} else if Int(seconds) > 0 && Int(seconds) <= 60 {
			cell.timeLeft.text = "\(Int(seconds)) second"
		}
		
		if tmpUrl == nil {
			tmpUrl = [Int: String]()
		}
		
		if tmpUrl![album.ID] == nil {
			tmpUrl![album.ID] = album.iTunesUrl
		}
		
		cell.purchaseButton.tag = album.ID
		cell.purchaseButton.addTarget(self, action: "purchaseAlbum:", forControlEvents: .TouchUpInside)
		
		switch UIScreen.mainScreen().bounds.width {
		case 375:
			cell.containerViewTopConstraint.constant = 132.5
		case 414:
			cell.containerViewTopConstraint.constant = 152
		default:
			cell.containerViewTopConstraint.constant = 105
		}
		
		cell.updateConstraintsIfNeeded()		
		return cell
	}
}

// MARK: - UICollectionViewDelegate
extension AlbumController: UICollectionViewDelegate {
	func collectionView (collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		var section = indexPath.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 { section = sectionAtIndex() }
		selectedAlbum = AppDB.sharedInstance.albums[section]![indexPath.row]
		performSegueWithIdentifier("AlbumViewSegue", sender: self)
	}
	
	func collectionView (collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
		albumCollectionView.cellForItemAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	func collectionView (collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
		albumCollectionView.cellForItemAtIndexPath(indexPath)?.alpha = 1.0
	}
}

// MARK: - AlbumControllerDelegate
extension AlbumController: AlbumControllerDelegate {
	func removeAlbum(album: Album, indexPath: NSIndexPath) {
		self.unsubscribe_album(album.iTunesUniqueID, successHandler: {
			AppDB.sharedInstance.deleteAlbum(album.ID, section: 1, index: indexPath.row)
			AppDB.sharedInstance.deleteArtwork(album.artwork)
			if AppDB.sharedInstance.albums[1]!.count == 0 {
				if self.numberOfSectionsInCollectionView(self.albumCollectionView) > 0 {
					self.albumCollectionView.deleteSections(NSIndexSet(index: 1))
				}
			} else {
				self.albumCollectionView.deleteItemsAtIndexPaths([indexPath])
			}
			self.tmpArtwork?.removeValueForKey(album.artwork)
			self.albumCollectionView.reloadData()
			}, errorHandler: { error in
				self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
		})
	}
}

// MARK: - UIViewControllerPreviewingDelegate
@available(iOS 9.0, *)
extension AlbumController: UIViewControllerPreviewingDelegate {
	func previewingContext (previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = albumCollectionView.indexPathForItemAtPoint(location), cell = albumCollectionView.cellForItemAtIndexPath(indexPath) else { return nil }
		guard let albumDetailVC = storyboard?.instantiateViewControllerWithIdentifier("AlbumView") as? AlbumDetailController else { return nil }
		var section = indexPath.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 { section = sectionAtIndex() }
		let album = AppDB.sharedInstance.albums[section]![indexPath.row]
		albumDetailVC.delegate = self
		albumDetailVC.album = album
		albumDetailVC.indexPath = indexPath
		albumDetailVC.preferredContentSize = CGSize(width: 0.0, height: 0.0)
		previewingContext.sourceRect = cell.frame
		return albumDetailVC
	}
	
	func previewingContext (previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
		showViewController(viewControllerToCommit, sender: self)
	}
}
