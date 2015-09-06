//
//  SubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionController: UICollectionViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let subscriptionCellReuseIdentifier = "subscriptionCell"
	var artistCollectionLayout: UICollectionViewFlowLayout!
	var refreshControl: UIRefreshControl!
	
	@IBOutlet var artistsCollectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Register CollectionView Cell Nib.
		artistsCollectionView.registerNib(UINib(nibName: "SubscriptionCell", bundle: nil), forCellWithReuseIdentifier: subscriptionCellReuseIdentifier)
		
		// Add Edge insets to compensate for navigation bar.
		artistsCollectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		artistsCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		
		// Collection view layout settings.
		let defaultItemSize = CGSize(width: 145, height: 180)
		artistCollectionLayout = UICollectionViewFlowLayout()
		artistCollectionLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		artistCollectionLayout.itemSize = defaultItemSize
		artistCollectionLayout.minimumLineSpacing = 10
		artistCollectionLayout.minimumInteritemSpacing = 10
		
		switch UIScreen.mainScreen().bounds.width {
			// iPhone 4S, 5, 5C & 5S
		case 320:
			artistCollectionLayout.itemSize = defaultItemSize
			// iPhone 6
		case 375:
			artistCollectionLayout.itemSize = CGSize(width: 172, height: 207)
			// iPhone 6 Plus
		case 414:
			artistCollectionLayout.itemSize = CGSize(width: 192, height: 227)
		default:
			artistCollectionLayout.itemSize = defaultItemSize
		}
		
		artistsCollectionView.setCollectionViewLayout(artistCollectionLayout, animated: false)
		
		// Pull-to-refresh Control.
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		artistsCollectionView.addSubview(refreshControl)
		
		AppDB.sharedInstance.getArtists()
		artistsCollectionView.reloadData()
	}
	
	override func viewWillAppear(animated: Bool) {
		artistsCollectionView.reloadData()
		artistsCollectionView.scrollsToTop = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		artistsCollectionView.scrollsToTop = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func refresh() {
		API.sharedInstance.refreshSubscriptions({
			self.artistsCollectionView.reloadData()
			self.refreshControl.endRefreshing()
			},
			errorHandler: { (error) in
				self.refreshControl.endRefreshing()
				var alert = UIAlertController(title: "Oops! Something went wrong.", message: error.localizedDescription, preferredStyle: .Alert)
				if error.code == 403 {
					alert.addAction(UIAlertAction(title: "Fix it!", style: .Default, handler: { action in
						// Todo: implement...
					}))
				} else {
					alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
						UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
					}))
				}
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = artistsCollectionView.dequeueReusableCellWithReuseIdentifier(subscriptionCellReuseIdentifier, forIndexPath: indexPath) as! SubscriptionCell
		let artistImage = "artist_0" + String(arc4random_uniform(5) + 1)
		cell.subscriptionArtwork.image = UIImage(named: artistImage)
		cell.subscriptionTitle.text = AppDB.sharedInstance.artists[indexPath.row].title as String
		cell.optionsBtn.tag = indexPath.row
		cell.optionsBtn.addTarget(self, action: "deleteArtist:", forControlEvents: .TouchUpInside)
		return cell
	}
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return AppDB.sharedInstance.artists.count
	}
	
	func deleteArtist (sender: UIButton) {
		let rowIndex = sender.tag
		var alert = UIAlertController(title: "Remove Subscription?", message: "Please confirm that you want to unsubscribe from this artist.", preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Confirm", style: .Destructive, handler: { action in
			let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&artistUniqueID=\(AppDB.sharedInstance.artists[rowIndex].iTunesUniqueID)"
			API.sharedInstance.sendRequest(APIURL.removeArtist.rawValue, postString: postString, successHandler: { (response, data) in
				if let HTTPResponse = response as? NSHTTPURLResponse {
					println("HTTP status code: \(HTTPResponse.statusCode)")
					if HTTPResponse.statusCode == 204 {
						AppDB.sharedInstance.getAlbums()
						println("Successfully unsubscribed.")
					}
				}
				},
				errorHandler: { (error) in
					AppDB.sharedInstance.addPendingArtist(AppDB.sharedInstance.artists[rowIndex].ID)
					var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: .Alert)
					alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
						UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
					}))
					alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
					self.presentViewController(alert, animated: true, completion: nil)
			})
			AppDB.sharedInstance.deleteArtist(AppDB.sharedInstance.artists[rowIndex].ID, index: rowIndex, completion: { (albumIDs) in
				for ID in albumIDs {
					for n in UIApplication.sharedApplication().scheduledLocalNotifications {
						var notification = n as! UILocalNotification
						let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
						let notificationID = userInfoCurrent["AlbumID"]! as! Int
						if ID == notificationID {
							println("Canceled location notification with ID: \(ID)")
							UIApplication.sharedApplication().cancelLocalNotification(notification)
						}
					}
				}
			})
			self.artistsCollectionView.reloadData()
		}))
		presentViewController(alert, animated: true, completion: nil)
	}
}
