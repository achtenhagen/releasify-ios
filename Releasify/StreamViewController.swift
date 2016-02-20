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
	// var searchController: UISearchController!
	var selectedAlbum: Album!
	var filteredData: [Artist]!
	var tmpArtwork: [String:UIImage]?
	var tmpUrl: [Int:String]?
	var footerLabel: UILabel!

	@IBOutlet var streamTabBarItem: UITabBarItem!
	@IBOutlet var streamTable: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tmpArtwork = [String:UIImage]()
		
		streamTable.backgroundColor = theme.streamTableBackgroundColor
		streamTable.backgroundView = UIView(frame: self.streamTable.bounds)
		streamTable.backgroundView?.userInteractionEnabled = false
		
		if #available(iOS 9.0, *) {
			if traitCollection.forceTouchCapability == .Available {
				self.registerForPreviewingWithDelegate(self, sourceView: streamTable)
			}
		}
		
		registerLongPressGesture()
		
//		self.searchController = UISearchController(searchResultsController: nil)
//		self.searchController.delegate = self
//		self.searchController.searchResultsUpdater = self
//		self.searchController.dimsBackgroundDuringPresentation = false
//		self.searchController.hidesNavigationBarDuringPresentation = false
//		self.searchController.searchBar.placeholder = "Search artists & albums"
//		self.searchController.searchBar.searchBarStyle = .Minimal
//		self.searchController.searchBar.barStyle = Theme.sharedInstance.searchBarStyle
//		self.searchController.searchBar.barTintColor = UIColor.clearColor()
//		self.searchController.searchBar.tintColor = Theme.sharedInstance.searchBarTintColor
//		self.searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
//		self.searchController.searchBar.layer.borderWidth = 1
//		self.searchController.searchBar.translucent = false
//		self.searchController.searchBar.autocapitalizationType = .Words
//		self.searchController.searchBar.keyboardAppearance = Theme.sharedInstance.keyboardStyle
//		self.searchController.searchBar.sizeToFit()
//		self.streamTable.tableHeaderView = self.searchController.searchBar
		
//		if #available(iOS 9.0, *) {
//			self.searchController.loadViewIfNeeded()
//		} else {
//			let _ = self.searchController.view
//		}
		
		refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl!.tintColor = Theme.sharedInstance.refreshControlTintColor
		streamTable.addSubview(refreshControl!)
		
		if !appDelegate.completedRefresh {
			refresh()
		}
		
//		definesPresentationContext = true
		
//		let notification = Notification(frame: CGRect(x: 0, y: -64, width: self.view.bounds.width, height: 64))
//		notification.title.text = "Notification Title"
//		notification.subtitle.text = "Notification body text"
//		delegate?.addNotificationView(notification)
//		NotificationQueue.sharedInstance.add(notification)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Refresh Content
	func refresh() {
		API.sharedInstance.refreshContent({ newItems in
			self.streamTable.reloadData()
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
				self.streamTable.hidden = false
				let notification = Notification(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 55))
				notification.title.text = "\(newItems.count) Album\(newItems.count == 1 ? "" : "s")"
				notification.subtitle.text = "\(newItems.count == 1 ? "has been added to your stream." : "have been added to your stream.")"
				let artwork = UIImageView(frame: CGRect(x: notification.frame.width - 50, y: 5, width: 45, height: 45))
				artwork.contentMode = .ScaleToFill
				artwork.layer.masksToBounds = true
				artwork.layer.cornerRadius = 2
				// Retrieve the artwork preview thumbnail
				API.sharedInstance.fetchArtwork(newItems[0], successHandler: { thumb in
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
	
	// MARK: - Compute the floor of 2 numbers
	func component(x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	// MARK: - Register long press gesture if 3D Touch is unavailable
	func registerLongPressGesture() {
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 1.0
		streamTable.addGestureRecognizer(longPressGesture)
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
		if AppDB.sharedInstance.checkArtwork(hash) {
			tmpArtwork![hash] = AppDB.sharedInstance.getArtwork(hash)
		} else {
			if tmpArtwork![hash] != nil {
				tmpArtwork?.removeValueForKey(hash)
			}
		}
		guard let tmpImage = tmpArtwork![hash] else {
			API.sharedInstance.fetchArtwork(hash, successHandler: { artwork in
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
//	func filterContentForSearchText(searchText: String) {
//		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({(artist: Artist) -> Bool in
//			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
//		})
//	}
	
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
	
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		if (scrollView == self.streamTable) {
			if let visibleCells = self.streamTable.indexPathsForVisibleRows {
				for indexPath in visibleCells {
					self.setCellImageOffset(self.streamTable.cellForRowAtIndexPath(indexPath) as! StreamCell, indexPath: indexPath)
				}
			}
		}
		if footerLabel != nil && streamTable.contentOffset.y >= (streamTable.contentSize.height - streamTable.bounds.size.height) {
			footerLabel.fadeIn()
		} else if footerLabel != nil && footerLabel.alpha == 1.0 {
			footerLabel.fadeOut()
		}
	}
	
	func setCellImageOffset(cell: StreamCell, indexPath: NSIndexPath) {
		let cellFrame = self.streamTable.rectForRowAtIndexPath(indexPath)
		let cellFrameInTable = self.streamTable.convertRect(cellFrame, toView:self.streamTable.superview)
		let cellOffset = cellFrameInTable.origin.y + cellFrameInTable.size.height
		let tableHeight = self.streamTable.bounds.size.height + cellFrameInTable.size.height
		let cellOffsetFactor = cellOffset / tableHeight
		cell.setBackgroundOffset(cellOffsetFactor)
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		let imageCell = cell as! StreamCell
		self.setCellImageOffset(imageCell, indexPath: indexPath)
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
		
		cell.containerView.backgroundColor = theme.streamCellBackgroundColor
		cell.albumTitle.textColor = theme.streamCellAlbumTitleColor
		cell.artistTitle.textColor = theme.streamCellArtistTitleColor
		
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
			let dateFormat = NSDateFormatter()
			dateFormat.dateFormat = "MMM dd"
			cell.timeLabel.text = dateFormat.stringFromDate(NSDate(timeIntervalSince1970: album.releaseDate))
		}
		
		if Int(NSDate().timeIntervalSince1970) - album.created <= 86400 {
			cell.addNewItemLabel()
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
		streamTable.cellForRowAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
		streamTable.cellForRowAtIndexPath(indexPath)?.alpha = 1.0
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
					if self.numberOfSectionsInTableView(self.streamTable) > 0 {
						self.streamTable.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
					}
				} else {
					self.streamTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
				}
				self.tmpArtwork?.removeValueForKey(hash)
				self.streamTable.reloadData()
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
		footerLabel.textColor = theme.streamCellFooterLabelColor
		footerLabel.text = "\(AppDB.sharedInstance.albums.count) albums, \(AppDB.sharedInstance.artists.count) artists"
		footerLabel.textAlignment = NSTextAlignment.Center
		footerLabel.adjustsFontSizeToFitWidth = true
		footerLabel.sizeToFit()
		footerLabel.center = CGPoint(x: self.view.frame.size.width / 2, y: 15)
		footerView.addSubview(footerLabel)
		return footerView
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

// MARK: - UISearchControllerDelegate
//extension StreamViewController: UISearchControllerDelegate {
//	func willPresentSearchController(searchController: UISearchController) {
//		searchController.searchBar.backgroundColor = Theme.sharedInstance.navBarTintColor
//	}
//	
//	func willDismissSearchController(searchController: UISearchController) {
//		searchController.searchBar.backgroundColor = UIColor.clearColor()
//	}
//}

// MARK: - UISearchResultsUpdating
//extension StreamViewController: UISearchResultsUpdating {
//	func updateSearchResultsForSearchController(searchController: UISearchController) {
//		filterContentForSearchText(searchController.searchBar.text!)
//		streamTable.reloadData()
//	}
//}

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
