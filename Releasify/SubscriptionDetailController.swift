//
//  SubscriptionDetailController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 12/6/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionDetailController: UIViewController {
	
	private var theme: SubscriptionDetailControllerTheme!
	private let albumCellReuseIdentifier = "AlbumCell"
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var artist: Artist?
	var albums: [Album]?
	var selectedAlbum: Album!

	@IBOutlet weak var subscriptionAlbumCollectionView: UICollectionView!
	@IBOutlet var detailFlowLayout: UICollectionViewFlowLayout!
	
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
				AppDB.sharedInstance.deleteArtist(self.artist!.ID, completion: { (albumIDs) in
					for ID in albumIDs {
						for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
							let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
							let notificationID = userInfoCurrent["albumID"]! as! Int
							if ID == notificationID {
								UIApplication.sharedApplication().cancelLocalNotification(notification)
							}
						}
					}
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

		theme = SubscriptionDetailControllerTheme(style: appDelegate.theme.style)
		
		self.navigationItem.title = artist!.title
		
		// Theme customizations
		self.navigationItem.rightBarButtonItem?.tintColor = theme.style == .dark ? theme.redColor : theme.globalTintColor
		self.view.backgroundColor = theme.viewBackgroundColor
		if theme.style == .dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}
		
		// Collection view customizations
		subscriptionAlbumCollectionView.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)
		subscriptionAlbumCollectionView.setCollectionViewLayout(AlbumCollectionViewLayout(), animated: false)

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
		if let artwork = AppDB.sharedInstance.getArtwork(albums![indexPath.row].artwork) {
			cell.albumArtwork.image = artwork
		} else {
			let filename = theme.style == .dark ? "icon_artwork_dark" : "icon_artwork_light"
			cell.albumArtwork.image = UIImage(named: filename)!
		}
		cell.timeLeft.text = albums![indexPath.row].getFormattedReleaseDate()
		cell.albumTitle.text = albums![indexPath.row].title
		cell.artistTitle.text = artist!.title
		cell.albumTitle.textColor = theme.albumTitleColor
		cell.artistTitle.textColor = theme.artistTitleColor
		return cell
	}
}

// MARK: - UICollectionViewDelegate
extension SubscriptionDetailController: UICollectionViewDelegate {
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		selectedAlbum = albums![indexPath.row]
		self.performSegueWithIdentifier("SubscriptionDetailCellSegue", sender: self)
	}
	
	func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
		collectionView.cellForItemAtIndexPath(indexPath)?.alpha = 0.8
	}
	
	func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
		collectionView.cellForItemAtIndexPath(indexPath)?.alpha = 1.0
	}
}

private class SubscriptionDetailControllerTheme: Theme {
	var viewBackgroundColor: UIColor!
	var albumTitleColor: UIColor!
	var artistTitleColor: UIColor!
	
	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .dark:
			viewBackgroundColor = UIColor.clearColor()
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		case .light:
			viewBackgroundColor = UIColor.whiteColor()
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			artistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
		}
	}
}
