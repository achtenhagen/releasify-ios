//
//  SubscriptionDetailController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 12/6/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionDetailController: UIViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var artist: Artist?
	var albums: [Album]?

	@IBOutlet weak var subscriptionAlbumCollectionView: UICollectionView!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var detailFlowLayout: UICollectionViewFlowLayout!
	
	@IBAction func removeArtist(sender: AnyObject) {
		let alert = UIAlertController(title: "Remove Subscription?", message: "Please confirm that you want to unsubscribe from this artist.", preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
			let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&artistUniqueID=\(self.artist!.iTunesUniqueID)"
			API.sharedInstance.sendRequest(API.Endpoint.removeArtist.url(), postString: postString, successHandler: { (statusCode, data) in
				if statusCode != 204 {
					self.handleError("Failed to remove subscription!", message: "Please try again later.", error: API.Error.FailedRequest)
					return
				}
				AppDB.sharedInstance.deleteArtist(self.artist!.ID, completion: { albumIDs in
					for ID in albumIDs {
						for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
							let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
							let notificationID = userInfoCurrent["albumID"]! as! Int
							if ID == notificationID {
								UIApplication.sharedApplication().cancelLocalNotification(notification)
							}
						}
					}
					NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
					self.appDelegate.contentHash = nil
					self.performSegueWithIdentifier("UnwindToSubscriptionsSegue", sender: self)
				})
				},
				errorHandler: { error in
					AppDB.sharedInstance.addPendingArtist(self.artist!.ID)
					self.handleError("Unable to remove subscription!", message: "Please try again later.", error: error)
			})
		}))
		presentViewController(alert, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = artist!.title
		let itemSize = view.bounds.width / 2
		detailFlowLayout.itemSize = CGSize(width: itemSize, height: itemSize)
		subscriptionAlbumCollectionView.setCollectionViewLayout(detailFlowLayout, animated: false)
		albums = AppDB.sharedInstance.getAlbumsByArtist(artist!.ID)
		setupSearchBar()
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func setupSearchBar () {
		searchBar.delegate = self
		searchBar.searchBarStyle = .Default
		searchBar.barStyle = .Black
		searchBar.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
		searchBar.tintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1)
		searchBar.layer.borderColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1).CGColor
		searchBar.layer.borderWidth = 1
		searchBar.translucent = false
		searchBar.sizeToFit()
	}
	
	// MARK: - Error message handler
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
extension SubscriptionDetailController: UICollectionViewDataSource {
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return albums!.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = subscriptionAlbumCollectionView.dequeueReusableCellWithReuseIdentifier("SubscriptionDetailCell", forIndexPath: indexPath) as! SubscriptionDetailCell
		cell.albumArtwork.image = AppDB.sharedInstance.getArtwork(albums![indexPath.row].artwork)
		return cell
	}
}

// MARK: - UICollectionViewDelegate
extension SubscriptionDetailController: UICollectionViewDelegate {
	
}

// MARK: - UISearchBarDelegate
extension SubscriptionDetailController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchBar.showsCancelButton = true
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		
	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.text = ""
		searchBar.resignFirstResponder()
		searchBar.showsCancelButton = false
	}
}

// MARK: - UISearchControllerDelegate
extension SubscriptionDetailController: UISearchControllerDelegate {
	
}
