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
	
	private let theme = StreamViewControllerTheme()
	weak var delegate: AppControllerDelegate?
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let reuseIdentifier = "streamCell"
	var selectedAlbum: Album!
	var filteredData: [Artist]!
	var notificationAlbumID: Int?
	var tmpArtwork: [String:UIImage]?
	var tmpUrl: [Int:String]?
	var footerLabel: UILabel!
	var favListBarBtn: UIBarButtonItem!

	@IBOutlet var streamTabBarItem: UITabBarItem!
	@IBOutlet var streamTable: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tmpArtwork = [String:UIImage]()
		tmpUrl = [Int:String]()
		
		favListBarBtn = self.navigationController?.navigationBar.items![0].leftBarButtonItem
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshContent", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromRemoteNotification:", name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
		
		self.streamTable.backgroundColor = theme.streamTableBackgroundColor
		self.streamTable.backgroundView = UIView(frame: self.streamTable.bounds)
		self.streamTable.backgroundView?.userInteractionEnabled = false
		
		if #available(iOS 9.0, *) {
			if traitCollection.forceTouchCapability == .Available {
				self.registerForPreviewingWithDelegate(self, sourceView: self.streamTable)
			}
		}
		
		registerLongPressGesture()
		
		refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl!.tintColor = Theme.sharedInstance.refreshControlTintColor
		self.streamTable.addSubview(refreshControl!)
		
		// Handle first run
		if self.appDelegate.firstRun {
			self.appDelegate.firstRun = false
		}
		
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
	}
	
	override func viewDidAppear(animated: Bool) {
		AppDB.sharedInstance.getAlbums()
		self.streamTable.reloadData()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Refresh Content
	func refresh() {
		API.sharedInstance.refreshContent({ (newItems) in
			self.streamTable.reloadData()
			self.refreshControl!.endRefreshing()
			if newItems.count > 0 {
				let notificationTitle = "\(newItems.count) Album\(newItems.count == 1 ? "" : "s")"
				let notification = Notification(frame: CGRect(x: 0, y: 0, width: 140, height: 140), title: notificationTitle, icon: .notify)
				notification.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 50)
				self.delegate?.addNotificationView(notification)
				NotificationQueue.sharedInstance.add(notification)
			}
			},
			errorHandler: { (error) in
				self.refreshControl!.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)	
		})
	}
	
	// MARK: - Register long press gesture if 3D Touch is unavailable
	func registerLongPressGesture() {
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 1.0
		self.streamTable.addGestureRecognizer(longPressGesture)
	}
	
	// MARK: - Handle long press gesture
	func longPressGestureRecognized(gesture: UIGestureRecognizer) {
		let cellLocation = gesture.locationInView(streamTable)
		let indexPath = streamTable.indexPathForRowAtPoint(cellLocation)
		if indexPath == nil { return }
		if indexPath?.row == nil { return }
		if gesture.state == UIGestureRecognizerState.Began {
			let shareActivityItem = "Buy this album on iTunes:\n\(AppDB.sharedInstance.albums[indexPath!.row].iTunesUrl)"
			let activityViewController = UIActivityViewController(activityItems: [shareActivityItem], applicationActivities: nil)
			self.presentViewController(activityViewController, animated: true, completion: nil)
		}
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
				API.sharedInstance.fetchArtwork(album.artwork, successHandler: { artwork in
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
	
	// MARK: - Return artwork image for each collection view cell
	func getArtworkForCell(hash: String, completion: ((artwork: UIImage) -> Void)) {
		
		// Artwork is cached in dictionary, return it
		if tmpArtwork![hash] != nil {
			completion(artwork: tmpArtwork![hash]!)
			return
		}
		
		// Artwork is either not yet cached or needs to be downloaded first
		if AppDB.sharedInstance.checkArtwork(hash) {
			tmpArtwork![hash] = AppDB.sharedInstance.getArtwork(hash)
			completion(artwork: tmpArtwork![hash]!)
			return
		}
		
		// Artwork was not found, so download it
		API.sharedInstance.fetchArtwork(hash, successHandler: { artwork in
			AppDB.sharedInstance.addArtwork(hash, artwork: artwork!)
			self.tmpArtwork![hash] = artwork
			completion(artwork: self.tmpArtwork![hash]!)
			}, errorHandler: {
				completion(artwork: UIImage(named: "icon_artwork_placeholder")!)
		})
	}
	
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		if scrollView == self.streamTable {
			if let visibleCells = self.streamTable.indexPathsForVisibleRows {
				for indexPath in visibleCells {
					if let cell = self.streamTable.cellForRowAtIndexPath(indexPath) as? StreamCell {
						self.setCellImageOffset(cell, indexPath: indexPath)
					}
				}
			}
		}
		if footerLabel != nil && self.streamTable.contentOffset.y >= (self.streamTable.contentSize.height - self.streamTable.bounds.size.height) {
			footerLabel.fadeIn()
		} else if footerLabel != nil && footerLabel.alpha == 1.0 {
			footerLabel.fadeOut()
		}
	}
	
	// MARK: - Parallax scrolling effect
	func setCellImageOffset(cell: StreamCell, indexPath: NSIndexPath) {
		let cellFrame = self.streamTable.rectForRowAtIndexPath(indexPath)
		let cellFrameInTable = self.streamTable.convertRect(cellFrame, toView:self.streamTable.superview)
		let cellOffset = cellFrameInTable.origin.y + cellFrameInTable.size.height
		let tableHeight = self.streamTable.bounds.size.height + cellFrameInTable.size.height
		let cellOffsetFactor = cellOffset / tableHeight
		cell.setBackgroundOffset(cellOffsetFactor)
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
		let posted = album.getFormattedDatePosted(album.created)
		
		cell.containerView.backgroundColor = theme.streamCellBackgroundColor
		cell.albumTitle.textColor = theme.streamCellAlbumTitleColor
		cell.artistTitle.textColor = theme.streamCellArtistTitleColor
		
		getArtworkForCell(album.artwork, completion: { (artwork) in
			cell.artwork.image = artwork
		})
		
		cell.albumTitle.text = album.title
		cell.artistTitle.text = "By \(AppDB.sharedInstance.getAlbumArtist(album.ID)!), \(posted)"
		cell.albumTitle.userInteractionEnabled = false
		cell.timeLabel.text = album.getFormattedReleaseDate()
		
		if Int(NSDate().timeIntervalSince1970) - album.created <= 86400 {
			cell.addNewItemLabel()
		} else {
			cell.removeNewItemLabel()
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
		tableView.cellForRowAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
		tableView.cellForRowAtIndexPath(indexPath)?.alpha = 1.0
	}
	
	override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let starAction = UITableViewRowAction(style: .Normal, title: "        ", handler: { (action, indexPath) -> Void in
			// AppDB.sharedInstance.addFavorite(AppDB.sharedInstance.albums[indexPath.row].iTunesUniqueID)
		})
		starAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_star")!)
		let buyAction = UITableViewRowAction(style: .Normal, title: "         ", handler: { (action, indexPath) -> Void in
			let albumID = AppDB.sharedInstance.albums[indexPath.row].ID
			guard let albumUrl = self.tmpUrl![albumID] else { return }
			if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumUrl)!) {
				UIApplication.sharedApplication().openURL(NSURL(string: albumUrl)!)
			}
		})
		buyAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_buy")!)
		let removeAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "         ", handler: { (action, indexPath) -> Void in
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
					if self.numberOfSectionsInTableView(self.streamTable) > 0 {
						tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
					}
				} else {
					tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
				}
				self.tmpArtwork?.removeValueForKey(hash)
				tableView.reloadData()
				}, errorHandler: { (error) in
					self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
			})
		})
		removeAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_delete")!)
		return [starAction, buyAction, removeAction]
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		let imageCell = cell as! StreamCell
		self.setCellImageOffset(imageCell, indexPath: indexPath)
	}
	
	override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 40))
		footerView.backgroundColor = UIColor.clearColor()
		footerLabel = UILabel()
		footerLabel.alpha = 0
		footerLabel.font = UIFont(name: footerLabel.font.fontName, size: 14)
		footerLabel.textColor = theme.streamCellFooterLabelColor
		footerLabel.text = "\(AppDB.sharedInstance.albums.count) albums, \(AppDB.sharedInstance.artists.count) artists"
		footerLabel.textAlignment = NSTextAlignment.Center
		footerLabel.adjustsFontSizeToFitWidth = true
		footerLabel.sizeToFit()
		footerLabel.center = CGPoint(x: self.view.frame.size.width / 2, y: 15)
		footerView.addSubview(footerLabel)
		return footerView
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
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
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
				if self.numberOfSectionsInTableView(self.streamTable) > 0 {
					self.streamTable.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
				}
			} else {
				self.streamTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
			}
			self.tmpArtwork?.removeValueForKey(album.artwork)
			self.streamTable.reloadData()
			}, errorHandler: { (error) in
				self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
		})
	}
}

// MARK: - UIViewControllerPreviewingDelegate
@available(iOS 9.0, *)
extension StreamViewController: UIViewControllerPreviewingDelegate {
	func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = streamTable.indexPathForRowAtPoint(location), cell = streamTable.cellForRowAtIndexPath(indexPath) else { return nil }
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

// MARK: - Theme Extension
private class StreamViewControllerTheme: Theme {
	
	var streamTableBackgroundColor: UIColor!
	var streamCellBackgroundColor: UIColor!
	var streamCellAlbumTitleColor: UIColor!
	var streamCellArtistTitleColor: UIColor!
	var streamCellFooterLabelColor: UIColor!
	
	override init () {
		switch Theme.sharedInstance.style {
		case .dark:
			streamTableBackgroundColor = UIColor.clearColor()
			streamCellBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
			streamCellAlbumTitleColor = UIColor.whiteColor()
			streamCellArtistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			streamCellFooterLabelColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.2)
		case .light:
			streamTableBackgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1.0)
			streamCellBackgroundColor = UIColor.whiteColor()
			streamCellFooterLabelColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
		}
	}
}
