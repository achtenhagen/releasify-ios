//
//  AlbumController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 8/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AlbumController: UIViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let albumCellReuseIdentifier = "AlbumCell"
	let albumHeaderViewReuseIdentifier = "albumCollectionHeader"
	let albumFooterViewReuseIdentifier = "albumCollectionFooter"
	var albumCollectionLayout: UICollectionViewFlowLayout!
	var selectedAlbum: Album!
	var artwork = [String:UIImage]()
	var notificationAlbumID: Int!
	var refreshControl: UIRefreshControl!	
	
	@IBOutlet weak var emptySubtitle: UILabel!
	@IBOutlet weak var emptyTitle: UILabel!
	@IBOutlet weak var albumCollectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromRemoteNotification:", name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshContent", object: nil)
		
		albumCollectionView.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)
		
		// Collection view layout settings.
		let defaultItemSize = CGSize(width: 145, height: 190)
		albumCollectionLayout = UICollectionViewFlowLayout()
		albumCollectionLayout.headerReferenceSize = CGSize(width: 50, height: 50)
		albumCollectionLayout.footerReferenceSize = CGSize(width: 50, height: 10)
		albumCollectionLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		albumCollectionLayout.itemSize = defaultItemSize
		albumCollectionLayout.minimumLineSpacing = 10
		albumCollectionLayout.minimumInteritemSpacing = 10
		
		switch UIScreen.mainScreen().bounds.width {
			// iPhone 4S, 5, 5C & 5S
		case 320:
			albumCollectionLayout.itemSize = defaultItemSize
			// iPhone 6S
		case 375:
			albumCollectionLayout.itemSize = CGSize(width: 172, height: 217)
			// iPhone 6S Plus
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
		
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 0.5
		albumCollectionView.addGestureRecognizer(longPressGesture)
		
		// Notification payload processing
		if let remoteContent = appDelegate.remoteNotificationPayload?["aps"]?["content-available"] as? Int {
			if remoteContent == 1 {
				refresh()
			}
		}
		
		if let localContent = appDelegate.localNotificationPayload?["AlbumID"] as? Int {
			notificationAlbumID = localContent
			for album in AppDB.sharedInstance.albums[1] as[Album]! {
				if album.ID == notificationAlbumID {
					selectedAlbum = album
					break
				}
			}
			if selectedAlbum.ID == notificationAlbumID {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
		
		// Refresh the App's content only when launched.
		if appDelegate.userID > 0 && !appDelegate.completedRefresh {
			refresh()
		}
		
		if AppDB.sharedInstance.albums[0]?.count == 0 && AppDB.sharedInstance.albums[1]?.count == 0 {
			albumCollectionView.hidden = true
			emptyTitle.hidden = false
			emptySubtitle.hidden = false
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		albumCollectionView.reloadData()
		albumCollectionView.scrollsToTop = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		albumCollectionView.scrollsToTop = false
	}
	
	func refresh() {
		API.sharedInstance.refreshContent({ (newItems) in			
			self.albumCollectionView.reloadData()
			self.refreshControl.endRefreshing()
			if newItems.count > 0 {
				// Todo: Show updates...
				self.albumCollectionView.hidden = false
			}
			NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
			},
			errorHandler: { (error) in
				self.refreshControl.endRefreshing()
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
				case API.Error.FailedToParseJSON:
					alert.title = "Oops! Something went wrong."
					alert.message = "Failed to parse response data."
				case API.Error.InternalServerError:
					alert.title = "500 Internal Server Error"
					alert.message = "An error occured on our end."
				case API.Error.NoInternetConnection:
					alert.title = "Unable to connect"
					alert.message = "Please make sure you are connected to the internet."
					alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
						UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
					}))
				default:
					alert.title = "Oops! Something went wrong."
					alert.message = "An unknown error occured."
				}
				alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	func showAlbumFromNotification(notification: NSNotification) {
		if let AlbumID = notification.userInfo!["AlbumID"]! as? Int {
			notificationAlbumID = AlbumID
			for album in AppDB.sharedInstance.albums[1] as[Album]! {
				if album.ID == notificationAlbumID {
					selectedAlbum = album
					break
				}
			}
			if selectedAlbum.ID == notificationAlbumID {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
	}
	
	// Search the array in reverse for better performance.
	func showAlbumFromRemoteNotification(notification: NSNotification) {
		UIApplication.sharedApplication().applicationIconBadgeNumber--
		if let AlbumID = notification.userInfo?["aps"]?["AlbumID"] as? Int {
			notificationAlbumID = AlbumID
			for album in AppDB.sharedInstance.albums[0] as[Album]! {
				if album.ID == notificationAlbumID {
					selectedAlbum = album
					break
				}
			}
			if selectedAlbum == nil {
				refresh()
				for album in AppDB.sharedInstance.albums[0] as[Album]! {
					if album.ID == notificationAlbumID {
						selectedAlbum = album
						break
					}
				}
			} else if selectedAlbum.ID == notificationAlbumID {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
	}
	
	// Determines current section (`upcoming` or `recently released`).
	// This function is called when there is only one section.
	func sectionAtIndex () -> Int {
		return AppDB.sharedInstance.albums[0]!.count > 0 ? 0 : 1
	}
	
	func component (x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	func longPressGestureRecognized(gesture: UIGestureRecognizer) {
		let cellLocation = gesture.locationInView(albumCollectionView)
		let indexPath = albumCollectionView.indexPathForItemAtPoint(cellLocation)
		if indexPath == nil { return }
		var section = indexPath!.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
			section = sectionAtIndex()
		}
		if indexPath?.row != nil {
			if gesture.state == UIGestureRecognizerState.Began {
				let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
				let buyAction = UIAlertAction(title: "Open in iTunes Store", style: .Default, handler: { action in
					let albumURL = AppDB.sharedInstance.albums[section]![indexPath!.row].iTunesURL
					if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumURL)!) {
						UIApplication.sharedApplication().openURL(NSURL(string: albumURL)!)
					}
				})
				controller.addAction(buyAction)
				
//				// Implement for final release.
//				let reportAction = UIAlertAction(title: "Report a problem", style: .Default, handler: { action in
//				// Todo: implement...
//				})
//				controller.addAction(reportAction)
				
				if AppDB.sharedInstance.albums[section]![indexPath!.row].releaseDate - NSDate().timeIntervalSince1970 > 0 {
					let deleteAction = UIAlertAction(title: "Remove", style: .Destructive, handler: { action in
						let albumID = AppDB.sharedInstance.albums[section]![indexPath!.row].ID
						let albumArtwork = AppDB.sharedInstance.albums[section]![indexPath!.row].artwork
						for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
							let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
							let ID = userInfoCurrent["AlbumID"]! as! Int
							if ID == albumID {
								print("Canceled location notification with ID: \(ID)")
								UIApplication.sharedApplication().cancelLocalNotification(notification)
								NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
								break
							}
						}
						UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
							self.albumCollectionView.cellForItemAtIndexPath(indexPath!)?.alpha = 0
							}, completion: { (value: Bool) in
								AppDB.sharedInstance.deleteAlbum(albumID, section: section, index: indexPath!.row)
								AppDB.sharedInstance.deleteArtwork(albumArtwork as String)
								self.albumCollectionView.reloadData()
						})
					})
					controller.addAction(deleteAction)
				} else {
//					let hideAction = UIAlertAction(title: "Hide Album", style: .Destructive, handler: { action in
//						// let albumID = AppDB.sharedInstance.albums[section]![indexPath!.row].ID
//						UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
//							albumCollectionView.cellForItemAtIndexPath(indexPath!)?.alpha = 0
//							}, completion: { (value: Bool) in
//								// Todo: implement...
//						})
//					})
//					controller.addAction(hideAction)
				}
				
				let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
				controller.addAction(cancelAction)
				presentViewController(controller, animated: true, completion: nil)
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
		}
	}
}

// MARK: - UICollectionViewDataSource
extension AlbumController: UICollectionViewDataSource {
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		var sections = 0
		if AppDB.sharedInstance.albums[0]!.count > 0 {
			sections++
		}
		if AppDB.sharedInstance.albums[1]!.count > 0 {
			sections++
		}
		if sections == 0 {
			albumCollectionView.hidden = true
			emptyTitle.hidden = false
			emptySubtitle.hidden = false
		} else {
			albumCollectionView.hidden = false
			emptyTitle.hidden = true
			emptySubtitle.hidden = true
		}
		return sections
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
			return AppDB.sharedInstance.albums[sectionAtIndex()]!.count
		}
		return AppDB.sharedInstance.albums[section]!.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(albumCellReuseIdentifier, forIndexPath: indexPath) as! AlbumCell
		var section = indexPath.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
			section = sectionAtIndex()
		}
		let album = AppDB.sharedInstance.albums[section]![indexPath.row]
		let hash = album.artwork
		let timeDiff = album.releaseDate - NSDate().timeIntervalSince1970
		cell.albumArtwork.contentMode = .Center
		cell.albumArtwork.image = UIImage(named: "icon_album_placeholder")
		// If an album is removed, but the image data is still stored in the artwork array, it WILL NOT re-download!!!
		if AppDB.sharedInstance.checkArtwork(hash) {
			artwork[hash] = AppDB.sharedInstance.getArtwork(hash)
		} else {
			artwork.removeValueForKey(hash)
		}
		if let image = artwork[hash] {
			cell.albumArtwork.contentMode = .ScaleToFill
			cell.albumArtwork.image = image
		} else {
			let subDir = (album.artwork as NSString).substringWithRange(NSRange(location: 0, length: 2))
			let albumURL = "https://releasify.me/static/artwork/music/\(subDir)/\(hash)@2x.jpg"
			if let checkedURL = NSURL(string: albumURL) {
				let request = NSURLRequest(URL: checkedURL)
				let mainQueue = NSOperationQueue.mainQueue()
				NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) in
					if error != nil {
						cell.albumArtwork.contentMode = .Center
						cell.albumArtwork.image = UIImage(named: "icon_album_placeholder")
						print("Failed to download artwork!")
						return
					}
					if let HTTPResponse = response as? NSHTTPURLResponse {
						if HTTPResponse.statusCode != 200 {
							cell.albumArtwork.contentMode = .Center
							cell.albumArtwork.image = UIImage(named: "icon_album_placeholder")
							print("Failed to download artwork!")
							return
						}
						let image = UIImage(data: data!)
						cell.albumArtwork.alpha = 0
						self.artwork[hash] = image
						dispatch_async(dispatch_get_main_queue(), {
							if let cell = self.albumCollectionView.cellForItemAtIndexPath((indexPath)) as? AlbumCell {
								AppDB.sharedInstance.addArtwork(hash, artwork: image!)
								cell.albumArtwork.contentMode = .ScaleToFill
								cell.albumArtwork.image = image
								UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
									cell.albumArtwork.alpha = 1.0
								}, completion: nil)
							}
						})
					}
				})
			}
		}
		
		cell.artistTitle.text = AppDB.sharedInstance.getAlbumArtist(album.ID)
		cell.albumTitle.text = album.title
		cell.albumTitle.userInteractionEnabled = false
		cell.containerView.hidden = true
		if timeDiff > 0 {
			let dateAdded = AppDB.sharedInstance.getAlbumDateAdded(album.ID)
			cell.containerView.hidden = false
			cell.progressBar.setProgress(album.getProgress(dateAdded!), animated: false)
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
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		if kind == UICollectionElementKindSectionHeader {
			let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: albumHeaderViewReuseIdentifier, forIndexPath: indexPath) as! AlbumCollectionHeader
			var section = indexPath.section
			if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
				section = sectionAtIndex()
			}
			if section == 0 {
				headerView.headerLabel.text = "UPCOMING"
			} else {
				headerView.headerLabel.text = "RECENTLY RELEASED"
			}
			return headerView
		}
		let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: albumFooterViewReuseIdentifier, forIndexPath: indexPath) 
		return footerView
	}
}

// MARK: - UICollectionViewDelegate
extension AlbumController: UICollectionViewDelegate {
	func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		var section = indexPath.section
		if numberOfSectionsInCollectionView(albumCollectionView) == 1 {
			section = sectionAtIndex()
		}
		selectedAlbum = AppDB.sharedInstance.albums[section]![indexPath.row]
		performSegueWithIdentifier("AlbumViewSegue", sender: self)
		return true
	}
	
	func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
		albumCollectionView.cellForItemAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
		albumCollectionView.cellForItemAtIndexPath(indexPath)?.alpha = 1.0
	}
}
