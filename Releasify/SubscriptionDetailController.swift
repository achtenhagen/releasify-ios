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
	let albumCellReuseIdentifier = "AlbumCell"
	var artist: Artist?
	var albums: [Album]?
	var selectedAlbum: Album!

	@IBOutlet weak var subscriptionAlbumCollectionView: UICollectionView!
	@IBOutlet weak var detailFlowLayout: UICollectionViewFlowLayout!
	
	@IBAction func removeArtist(sender: AnyObject) {
		let alert = UIAlertController(title: "Remove Subscription?", message: "Please confirm that you want to unsubscribe from this artist.", preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Remove", style: .Destructive, handler: { action in
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
					self.navigationController?.navigationBar.items![0].leftBarButtonItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
					self.appDelegate.contentHash = nil
					self.performSegueWithIdentifier("UnwindToSubscriptionsSegue", sender: self)
				})
				},
				errorHandler: { (error) in
					AppDB.sharedInstance.addPendingArtist(self.artist!.ID)
					self.handleError("Unable to remove subscription!", message: "Please try again later.", error: error)
			})
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = artist!.title
		subscriptionAlbumCollectionView.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)
		let itemSize = CGPoint(x: 172, y: 190)
		detailFlowLayout.itemSize = CGSize(width: itemSize.x, height: itemSize.y)
		subscriptionAlbumCollectionView.setCollectionViewLayout(detailFlowLayout, animated: false)
		albums = AppDB.sharedInstance.getAlbumsByArtist(artist!.ID)
		if albums == nil || albums?.count == 0 {
			let label = UILabel()
			label.font = UIFont(name: label.font.fontName, size: 18)
			label.textColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)
			label.text = "No albums here yet!"
			label.textAlignment = NSTextAlignment.Center
			label.adjustsFontSizeToFitWidth = true
			label.sizeToFit()
			label.center = CGPoint(x: view.frame.size.width / 2, y: (view.frame.size.height / 2) - (label.frame.size.height))
			self.view.addSubview(label)
		}
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		self.view.layer.insertSublayer(gradient, atIndex: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Error message handler
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
		if segue.identifier == "SubscriptionDetailCellSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
		}
	}
}

// MARK: - UICollectionViewDataSource
extension SubscriptionDetailController: UICollectionViewDataSource {
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return albums == nil ? 0 : albums!.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(albumCellReuseIdentifier, forIndexPath: indexPath) as! AlbumCell		
		cell.albumArtwork.image = AppDB.sharedInstance.getArtwork(albums![indexPath.row].artwork)
		cell.albumTitle.text = "Album Title"
		cell.artistTitle.text = artist!.title
		return cell
	}
}

// MARK: - UICollectionViewDelegate
extension SubscriptionDetailController: UICollectionViewDelegate {
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		selectedAlbum = albums![indexPath.row]
		self.performSegueWithIdentifier("SubscriptionDetailCellSegue", sender: self)
	}
}
