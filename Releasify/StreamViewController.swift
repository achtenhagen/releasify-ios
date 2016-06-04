//
//  StreamViewController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/4/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit

protocol StreamViewControllerDelegate: class {
	func removeAlbum(album: Album, indexPath: NSIndexPath)
}

class StreamViewController: UITableViewController {
	
	weak var delegate: AppControllerDelegate?
	private var theme: StreamViewControllerTheme!
	private var appEmptyStateView: UIView!
	private let reuseIdentifier = "streamCell"
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var cellArtworkContainerSize: CGRect!
	var selectedAlbum: Album!
	var filteredData: [Artist]!
	var notificationAlbumID: Int?
	var tmpArtwork: [String:UIImage]?
	var tmpUrl: [Int:String]?
	var footerLabel: UILabel!
	var favListBarBtn: UIBarButtonItem!

	@IBOutlet var streamTabBarItem: UITabBarItem!
	@IBOutlet var streamTable: UITableView!

	@IBAction func UnwindToStreamViewSegue(sender: UIStoryboardSegue) {}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Initialize
		cellArtworkContainerSize = CGRect(x: 0, y: 134, width: UIScreen.mainScreen().bounds.width - 40, height: 100)
		tmpArtwork = [String:UIImage]()
		tmpUrl = [Int:String]()
		theme = StreamViewControllerTheme(style: appDelegate.theme.style)
		AppDB.sharedInstance.getAlbums()
		
		favListBarBtn = self.navigationController?.navigationBar.items![0].leftBarButtonItem
		
		// Observers
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(refresh), name: "refreshContent", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadStream), name: "reloadStream", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(showAlbumFromRemoteNotification(_:)), name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(showAlbumFromNotification(_:)), name: "showAlbum", object: nil)

		// Theme customization
		streamTable.backgroundColor = theme.tableViewBackgroundColor
		streamTable.backgroundView = UIView(frame: self.streamTable.bounds)
		streamTable.backgroundView?.userInteractionEnabled = false
		streamTable.separatorStyle = theme.style == .Dark ? .None : .SingleLine
		streamTable.separatorColor = theme.cellSeparatorColor
		
		// Check for 3D Touch availability
		if #available(iOS 9.0, *) {
			if traitCollection.forceTouchCapability == .Available {
				self.registerForPreviewingWithDelegate(self, sourceView: streamTable)
			}
		}
		
		registerLongPressGesture()
		
		// Refresh control
		refreshControl!.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
		refreshControl!.tintColor = theme.refreshControlTintColor
		streamTable.addSubview(refreshControl!)

		// Double tap gesture on tab bar
		let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(scrollListToTop))
		doubleTapGesture.numberOfTapsRequired = 2
		self.tabBarController?.tabBar.addGestureRecognizer(doubleTapGesture)
		
		// Handle first run
		if appDelegate.firstRun {
			appDelegate.firstRun = false
		}
		
		// Process remote notification payload
		if let remoteContent = appDelegate.remoteNotificationPayload {
			processRemoteNotificationPayload(remoteContent)
		}
		
		// Process local notification payload
		if let notificationAlbumID = appDelegate.localNotificationPayload?["albumID"] as? Int {
			if let album = AppDB.sharedInstance.getAlbum(notificationAlbumID) {
				selectedAlbum = album
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
		
		// Update content when app is launched
		if !appDelegate.completedRefresh {
			refresh()
		}

		// Set tab bar item badge count
		updateTabBarItemBadgeCount()
	}

	override func viewWillAppear(animated: Bool) {
		if theme.style == .Light {
			self.navigationController?.navigationBar.shadowImage = UIImage(named: "navbar_shadow")
		}
		if AppDB.sharedInstance.albums.count == 0 {
			showAppEmptyState()
		} else {
			hideAppEmptyState()
		}
	}

	func reloadStream() {
		AppDB.sharedInstance.getAlbums()
		updateTabBarItemBadgeCount()
		if AppDB.sharedInstance.albums.count == 0 {
			showAppEmptyState()
		} else {
			hideAppEmptyState()
		}
		self.streamTable.reloadData()
	}

	// MARK: - Update tab bar item badge count
	func updateTabBarItemBadge(albumID: Int) {
		if UnreadItems.sharedInstance.removeItem(albumID) {
			updateTabBarItemBadgeCount()
			UnreadItems.sharedInstance.save()
		}
	}

	// MARK: - Update tab bar item badge count
	func updateTabBarItemBadgeCount() {
		let count = UnreadItems.sharedInstance.list.count
		self.tabBarItem.badgeValue = count == 0 ? nil : String(count)
	}

	// MARK: - Show App empty state
	func showAppEmptyState() {
		if appEmptyStateView == nil {
			let appEmptyState = AppEmptyState(theme: theme, refView: self.view, imageName: "stream_empty_state", title: "No Content",
			                                  subtitle: "Start by adding a new subscription", buttonTitle: "Add Subscription")
			appEmptyStateView = appEmptyState.view()
			appEmptyState.placeholderButton.addTarget(self, action: #selector(self.addSubscriptionFromPlaceholder), forControlEvents: .TouchUpInside)
			self.view.addSubview(appEmptyStateView)
		}
	}

	// MARK: - Hide App empty state
	func hideAppEmptyState() {
		if appEmptyStateView != nil {
			appEmptyStateView.removeFromSuperview()
			appEmptyStateView = nil
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Refresh Content
	func refresh() {
		API.sharedInstance.refreshContent({ (processedAlbums, contentHash) in
			var newContentAvailable = false
			for album in processedAlbums {
				let newAlbumID = AppDB.sharedInstance.addAlbum(album)
				if newAlbumID > 0 { newContentAvailable = true }
				if newAlbumID > 0 && UIApplication.sharedApplication().scheduledLocalNotifications!.count < 64 {
					UnreadItems.sharedInstance.list.append(newAlbumID)
					let remaining = Double(album.releaseDate) - Double(NSDate().timeIntervalSince1970)
					if remaining > 0 {
						let notification = UILocalNotification()
						if #available(iOS 8.2, *) { notification.alertTitle = "New Album Released" }
						notification.category = "DEFAULT_CATEGORY"
						notification.timeZone = NSTimeZone.localTimeZone()
						notification.alertBody = "\(album.title) is now available."
						notification.fireDate = NSDate(timeIntervalSince1970: album.releaseDate)
						notification.applicationIconBadgeNumber += 1
						notification.soundName = UILocalNotificationDefaultSoundName
						notification.userInfo = ["albumID": newAlbumID, "iTunesUrl": album.iTunesUrl]
						UIApplication.sharedApplication().scheduleLocalNotification(notification)
					}
				}
			}

			// Reload data if new content is available
			if newContentAvailable {
				AppDB.sharedInstance.getArtists()
				AppDB.sharedInstance.getAlbums()
				self.streamTable.reloadData()
				UnreadItems.sharedInstance.save()
			}

			// Show / hide empty state placeholder
			if AppDB.sharedInstance.albums.count == 0 {
				self.showAppEmptyState()
			} else {
				self.hideAppEmptyState()
			}

			// Update content hash
			NSUserDefaults.standardUserDefaults().setValue(contentHash, forKey: "contentHash")
			self.appDelegate.contentHash = contentHash

			// Set last updated
			self.appDelegate.completedRefresh = true
			NSUserDefaults.standardUserDefaults().setInteger(Int(NSDate().timeIntervalSince1970), forKey: "lastUpdated")

			// Update tab bar item badge value
			self.updateTabBarItemBadgeCount()
			UnreadItems.sharedInstance.save()

			// Complete refresh
			self.refreshControl!.endRefreshing()
			},
			errorHandler: { (error) in
				self.refreshControl!.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)	
		})
	}

	// MARK: - Gesture recognizer to scroll list to top
	func scrollListToTop() {
		if self.tabBarController?.tabBar.selectedItem?.tag == 0 {
			self.streamTable.setContentOffset(CGPointZero, animated: true)
		}
	}
	
	// MARK: - Fallback if 3D Touch is unavailable
	func registerLongPressGesture() {
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(StreamViewController.longPressGestureRecognized(_:)))
		longPressGesture.minimumPressDuration = 1
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
		if let notificationAlbumID = notification.userInfo!["albumID"] as? Int {
			if let album = AppDB.sharedInstance.getAlbum(notificationAlbumID) {
				selectedAlbum = album
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
		UIApplication.sharedApplication().applicationIconBadgeNumber -= 1
		if let albumID = userInfo["aps"]?["albumID"] as? Int {
			API.sharedInstance.lookupAlbum(albumID, successHandler: { album in
				AppDB.sharedInstance.addAlbum(album)
				self.selectedAlbum = album
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
				}, errorHandler: { (error) in
					self.handleError("Failed to lookup album!", message: "Please try again later.", error: error)
			})
		}
	}
	
	// MARK: - Return artwork image for each collection view cell
	func getArtworkForCell(url: String, hash: String, completion: ((artwork: UIImage) -> Void)) {
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
		API.sharedInstance.fetchArtwork(url, successHandler: { (artwork) in
			AppDB.sharedInstance.addArtwork(hash, artwork: artwork!)
			self.tmpArtwork![hash] = artwork
			completion(artwork: self.tmpArtwork![hash]!)
			}, errorHandler: {				
				let filename = self.theme.style == .Dark ? "icon_artwork_dark" : "icon_artwork_light"
				completion(artwork: UIImage(named: filename)!)
		})
	}
	
	// MARK: - Unsubscribe from an album
	func unsubscribeFromAlbum(album: Album, indexPath: NSIndexPath) {
		AppDB.sharedInstance.deleteAlbum(album.ID, index: indexPath.row)
		AppDB.sharedInstance.deleteArtwork(album.artwork)
		self.tmpArtwork?.removeValueForKey(album.artwork)
		self.tmpUrl?.removeValueForKey(album.ID)
		if Favorites.sharedInstance.removeFavoriteIfExists(album) {
			NSNotificationCenter.defaultCenter().postNotificationName("reloadFavList", object: nil, userInfo: nil)
		}
		self.streamTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		API.sharedInstance.unsubscribeAlbum(album.iTunesUniqueID, successHandler: nil, errorHandler: { (error) in
			self.handleError("Unable to remove album!", message: "Please try again later.", error: error)
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
		} else if footerLabel != nil && footerLabel.alpha == 1 {
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

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
			detailController.artist = AppDB.sharedInstance.getAlbumArtist(selectedAlbum.ID)!
		}
	}

	// MARK: - Add new subscription from empty state
	func addSubscriptionFromPlaceholder() {
		self.performSegueWithIdentifier("AddSubscriptionSegue", sender: self)
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return AppDB.sharedInstance.albums.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! StreamCell
		let album = AppDB.sharedInstance.albums[indexPath.row]
		let posted = album.getFormattedDatePosted(album.created)
		let albumWillFadeIn = tmpArtwork![album.artwork] == nil ? true : false
		cell.alpha = 0
		cell.containerView.backgroundColor = theme.streamCellBackgroundColor
		cell.albumTitle.textColor = theme.streamCellAlbumTitleColor
		cell.artistTitle.textColor = theme.streamCellArtistTitleColor
		cell.artwork.image = UIImage()
		getArtworkForCell(album.artworkUrl!, hash: album.artwork, completion: { (artwork) in
			cell.artwork.image = artwork
			if albumWillFadeIn {
				cell.fadeIn()
			} else {
				cell.alpha = 1
			}
		})
		cell.albumTitle.text = album.title
		cell.artistTitle.text = "By \(AppDB.sharedInstance.getAlbumArtist(album.ID)!), \(posted)"
		cell.albumTitle.userInteractionEnabled = false
		cell.timeLabel.text = album.getFormattedReleaseDate()
		if tmpUrl![album.ID] == nil {
			tmpUrl![album.ID] = album.iTunesUrl
		}
		cell.addOverlay(cellArtworkContainerSize)
		cell.removeNewItemLabel()
		if UnreadItems.sharedInstance.list.contains(album.ID) {
			cell.addNewItemLabel()
			cell.label.textColor = theme.orangeColor
			cell.label.layer.borderColor = theme.orangeColor.CGColor
		}
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let cell = tableView.cellForRowAtIndexPath(indexPath) as! StreamCell
		let albumID = AppDB.sharedInstance.albums[indexPath.row].ID
		updateTabBarItemBadge(albumID)
		cell.removeNewItemLabel()
		selectedAlbum = AppDB.sharedInstance.albums[indexPath.row]
		self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
	}
	
	override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
		tableView.cellForRowAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
		tableView.cellForRowAtIndexPath(indexPath)?.alpha = 1
	}
	
	override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let removeAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "         ", handler: { (action, indexPath) -> Void in
			let alert = UIAlertController(title: "Remove Album?", message: "Please confirm that you want to remove this album.", preferredStyle: .Alert)
			alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
			alert.addAction(UIAlertAction(title: "Remove", style: .Destructive, handler: { action in
				let album = AppDB.sharedInstance.albums[indexPath.row]
				if !album.isReleased() {
					for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
						let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
						let ID = userInfoCurrent["albumID"]! as! Int
						if ID == album.ID {
							UIApplication.sharedApplication().cancelLocalNotification(notification)
							break
						}
					}
				}
				self.unsubscribeFromAlbum(album, indexPath: indexPath)
				self.updateTabBarItemBadge(album.ID)
			}))
			self.presentViewController(alert, animated: true, completion: nil)
		})
		let action_img = UIImage(named: "row_action_delete")
		let action_img_dark = UIImage(named: "row_action_delete_dark")
		removeAction.backgroundColor = theme.style == .Dark ? UIColor(patternImage: action_img_dark!) : UIColor(patternImage: action_img!)
		return [removeAction]
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		let imageCell = cell as! StreamCell
		self.setCellImageOffset(imageCell, indexPath: indexPath)
		cell.layoutIfNeeded()
	}
	
	override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if AppDB.sharedInstance.albums.count == 0 { return UIView() }
		let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 40))
		footerView.backgroundColor = UIColor.clearColor()
		footerLabel = UILabel()
		footerLabel.alpha = 0
		footerLabel.font = UIFont(name: footerLabel.font.fontName, size: 14)
		footerLabel.textColor = theme.streamCellFooterLabelColor
		let s1 = AppDB.sharedInstance.albums.count == 1 ? "album" : "albums"
		let s2 = AppDB.sharedInstance.artists.count == 1 ? "artist" : "artists"
		footerLabel.text = "\(AppDB.sharedInstance.albums.count) \(s1), \(AppDB.sharedInstance.artists.count) \(s2)"
		footerLabel.textAlignment = NSTextAlignment.Center
		footerLabel.adjustsFontSizeToFitWidth = true
		footerLabel.sizeToFit()
		footerLabel.center = CGPoint(x: self.view.frame.size.width / 2, y: 18)
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

// MARK: - StreamViewControllerDelegate
extension StreamViewController: StreamViewControllerDelegate {
	func removeAlbum(album: Album, indexPath: NSIndexPath) {
		self.unsubscribeFromAlbum(album, indexPath: indexPath)
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
		albumDetailVC.artist = AppDB.sharedInstance.getAlbumArtist(album.ID)!
		albumDetailVC.indexPath = indexPath
		albumDetailVC.preferredContentSize = CGSizeZero
		previewingContext.sourceRect = cell.frame
		return albumDetailVC
	}
	
	func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
		self.showViewController(viewControllerToCommit, sender: self)
	}
}

// MARK: - Theme Subclass
private class StreamViewControllerTheme: Theme {
	var streamCellBackgroundColor: UIColor!
	var streamCellAlbumTitleColor: UIColor!
	var streamCellArtistTitleColor: UIColor!
	var streamCellFooterLabelColor: UIColor!

	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			streamCellBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
			streamCellAlbumTitleColor = UIColor.whiteColor()
			streamCellArtistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			streamCellFooterLabelColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
		case .Light:
			streamCellBackgroundColor = UIColor.clearColor()
			streamCellAlbumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			streamCellArtistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			streamCellFooterLabelColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
		}
	}
}
