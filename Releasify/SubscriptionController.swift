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
	var selectedIndexPath: NSIndexPath!
	
	@IBOutlet weak var artistsCollectionView: UICollectionView!
	@IBOutlet weak var searchBar: UISearchBar!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		searchBar.delegate = self
		searchBar.keyboardAppearance = .Dark
		searchBar.tintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
		
		filteredData = AppDB.sharedInstance.artists
		
		artistsCollectionView.registerNib(UINib(nibName: "SubscriptionCell", bundle: nil), forCellWithReuseIdentifier: subscriptionCellReuseIdentifier)
		
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
			self.filteredData = AppDB.sharedInstance.artists
			self.artistsCollectionView.reloadData()
			self.refreshControl.endRefreshing()
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
	
	func deleteArtist (sender: UIButton) {
		let rowIndex = sender.tag
		let alert = UIAlertController(title: "Remove Subscription?", message: "Please confirm that you want to unsubscribe from this artist.", preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Confirm", style: .Destructive, handler: { action in
			let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&artistUniqueID=\(self.filteredData[rowIndex].iTunesUniqueID)"
			API.sharedInstance.sendRequest(API.URL.removeArtist.rawValue, postString: postString, successHandler: { (statusCode, data) in
				if statusCode == 204 {
					AppDB.sharedInstance.deleteArtist(self.filteredData[rowIndex].ID, index: rowIndex, completion: { (albumIDs) in
						for ID in albumIDs {
							for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
								let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
								let notificationID = userInfoCurrent["AlbumID"]! as! Int
								if ID == notificationID {
									print("Canceled location notification with ID: \(ID)")
									UIApplication.sharedApplication().cancelLocalNotification(notification)
								}
							}
						}
						AppDB.sharedInstance.getArtists()
						AppDB.sharedInstance.getAlbums()
						self.filteredData = AppDB.sharedInstance.artists
						self.artistsCollectionView.reloadData()
						self.searchBar.text = ""
						self.searchBar.resignFirstResponder()
						print("Successfully unsubscribed.")
					})
//					UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
//						artistsCollectionView.cellForItemAtIndexPath(selectedIndexPath!)?.alpha = 0
//						}, completion: { (value: Bool) in
//							
//					})
				}
				},
				errorHandler: { (error) in
					AppDB.sharedInstance.addPendingArtist(self.filteredData[rowIndex].ID)
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
		}))
		presentViewController(alert, animated: true, completion: nil)
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
		cell.optionsBtn.tag = indexPath.row
		cell.optionsBtn.addTarget(self, action: "deleteArtist:", forControlEvents: .TouchUpInside)
		return cell
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
		filteredData = AppDB.sharedInstance.artists
		artistsCollectionView.reloadData()
		searchBar.text = ""
		searchBar.resignFirstResponder()
		searchBar.showsCancelButton = false
	}
}

// MARK: - UICollectionViewDelegate
extension SubscriptionController: UICollectionViewDelegate {
	func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
		selectedIndexPath = indexPath
	}
}
