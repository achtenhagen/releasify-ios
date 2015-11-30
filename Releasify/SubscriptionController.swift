//
//  SubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionController: UIViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let subscriptionCellReuseIdentifier = "subscriptionCell"
	var artistCollectionLayout: UICollectionViewFlowLayout!
	var refreshControl: UIRefreshControl!
	var filteredData: [Artist]!
	var selectedIndexPath: NSIndexPath?
	
	@IBOutlet weak var artistsCollectionView: UICollectionView!
	@IBOutlet weak var searchBar: UISearchBar!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadSubscriptions", name: "refreshSubscriptions", object: nil)
		
		searchBar.delegate = self
		searchBar.placeholder = "Search Artists"
		searchBar.searchBarStyle = .Default
		searchBar.barStyle = .Black
		searchBar.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
		searchBar.tintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
		searchBar.layer.borderColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1).CGColor
		searchBar.layer.borderWidth = 1
		searchBar.translucent = false
		searchBar.autocapitalizationType = .Words
		searchBar.keyboardAppearance = .Dark
		searchBar.sizeToFit()
		
		filteredData = AppDB.sharedInstance.artists
		
		artistsCollectionView.registerNib(UINib(nibName: "SubscriptionCell", bundle: nil), forCellWithReuseIdentifier: subscriptionCellReuseIdentifier)
		
		let defaultItemSize = CGSize(width: 120, height: 150)
		artistCollectionLayout = UICollectionViewFlowLayout()
		artistCollectionLayout.sectionInset = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
		artistCollectionLayout.itemSize = defaultItemSize
		artistCollectionLayout.minimumLineSpacing = 25
		artistCollectionLayout.minimumInteritemSpacing = 0
		
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			artistCollectionLayout.itemSize = defaultItemSize
		case 375:
			artistCollectionLayout.itemSize = CGSize(width: 150, height: 180)
		case 414:
			artistCollectionLayout.itemSize = CGSize(width: 170, height: 200)
		default:
			artistCollectionLayout.itemSize = defaultItemSize
		}
		
		artistsCollectionView.setCollectionViewLayout(artistCollectionLayout, animated: false)			
		
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		artistsCollectionView.addSubview(refreshControl)
		
		AppDB.sharedInstance.getArtists()
		artistsCollectionView.reloadData()
	}
	
	override func viewWillAppear(animated: Bool) {
		reloadSubscriptions()
		artistsCollectionView.scrollsToTop = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		artistsCollectionView.scrollsToTop = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func reloadSubscriptions() {
		filteredData = AppDB.sharedInstance.artists
		artistsCollectionView.reloadData()
	}
	
	func refresh() {
		API.sharedInstance.refreshContent({ newItems in
			self.reloadSubscriptions()
			self.refreshControl.endRefreshing()
			NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
			},
			errorHandler: { error in
				self.refreshControl.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)
		})
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
}

// MARK: - UICollectionViewDataSource
extension SubscriptionController: UICollectionViewDataSource {
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return filteredData.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = artistsCollectionView.dequeueReusableCellWithReuseIdentifier(subscriptionCellReuseIdentifier, forIndexPath: indexPath) as! SubscriptionCell
		cell.subscriptionArtwork.image = UIImage(named: filteredData[indexPath.row].avatar)
		cell.subscriptionTitle.text = filteredData[indexPath.row].title as String
		return cell
	}
}

// MARK: - UICollectionViewDelegate
extension SubscriptionController: UICollectionViewDelegate {
	func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		selectedIndexPath = NSIndexPath(forItem: indexPath.row, inSection: 0)
		let alert = UIAlertController(title: "Remove Subscription?", message: "Please confirm that you want to unsubscribe from this artist.", preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
			let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&artistUniqueID=\(self.filteredData[indexPath.row].iTunesUniqueID)"
			API.sharedInstance.sendRequest(API.URL.removeArtist.rawValue, postString: postString, successHandler: { (statusCode, data) in
				if statusCode != 204 {
					self.handleError("Unable to update!", message: "Please try again later.", error: API.Error.FailedRequest)
					return
				}
				AppDB.sharedInstance.deleteArtist(self.filteredData[indexPath.row].ID, index: indexPath.row, completion: { albumIDs in
					for ID in albumIDs {
						for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
							let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
							let notificationID = userInfoCurrent["albumID"]! as! Int
							if ID == notificationID {
								UIApplication.sharedApplication().cancelLocalNotification(notification)
							}
						}
					}
					self.filteredData.removeAtIndex(indexPath.row)
					
					self.artistsCollectionView.performBatchUpdates({
						self.artistsCollectionView.deleteItemsAtIndexPaths([self.selectedIndexPath!])
						}, completion: { finished in
							self.artistsCollectionView.reloadItemsAtIndexPaths(self.artistsCollectionView.indexPathsForVisibleItems())
					})
					self.searchBar.text = ""
					self.searchBar.resignFirstResponder()
					NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
					self.appDelegate.contentHash = nil
				})
				},
				errorHandler: { error in
					AppDB.sharedInstance.addPendingArtist(self.filteredData[indexPath.row].ID)
					self.handleError("Unable to remove subscription!", message: "Please try again later.", error: error)
			})
		}))
		presentViewController(alert, animated: true, completion: nil)
		return true
	}
	func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
		artistsCollectionView.cellForItemAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
		artistsCollectionView.cellForItemAtIndexPath(indexPath)?.alpha = 1.0
	}
}

// MARK: - UISearchBarDelegate
extension SubscriptionController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchBar.showsCancelButton = true
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({(artist: Artist) -> Bool in
			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
		})
		artistsCollectionView.reloadData()
	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		reloadSubscriptions()
		searchBar.text = ""
		searchBar.resignFirstResponder()
		searchBar.showsCancelButton = false
	}
}
