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
		let title = NSLocalizedString("Remove Subscription?", comment: "")
		let message = NSLocalizedString("Please confirm that you want to unsubscribe from this artist.", comment: "")
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let firstActionTitle = NSLocalizedString("Cancel", comment: "")
		let secondActionTitle = NSLocalizedString("Remove", comment: "")
		alert.addAction(UIAlertAction(title: firstActionTitle, style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: secondActionTitle, style: .Destructive, handler: { (action) in
			let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&artistUniqueID=\(self.artist!.iTunesUniqueID)"
			API.sharedInstance.sendRequest(API.Endpoint.removeArtist.url(), postString: postString, successHandler: { (statusCode, data) in
				if statusCode != 204 {
					let title = NSLocalizedString("Unable to remove subscription!", comment: "")
					let message = NSLocalizedString("Please try again later.", comment: "")
					self.handleError(title, message: message, error: API.Error.FailedRequest)
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
						if Favorites.sharedInstance.removeFavoriteIfExists(ID) {
							NSNotificationCenter.defaultCenter().postNotificationName("reloadFavList", object: nil, userInfo: nil)
						}
						UnreadItems.sharedInstance.removeItem(ID)
					}
					UnreadItems.sharedInstance.save()
					NSNotificationCenter.defaultCenter().postNotificationName("reloadStream", object: nil, userInfo: nil)
					self.appDelegate.contentHash = nil
					self.performSegueWithIdentifier("UnwindToSubscriptionsSegue", sender: self)
				})
				},
				errorHandler: { (error) in
					AppDB.sharedInstance.addPendingArtist(self.artist!.ID)
					let title = NSLocalizedString("Unable to remove subscription!", comment: "")
					let message = NSLocalizedString("Please try again later.", comment: "")
					self.handleError(title, message: message, error: error)
			})
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

		theme = SubscriptionDetailControllerTheme(style: appDelegate.theme.style)
		
		self.navigationItem.title = artist!.title
		
		// Theme customizations
		self.navigationItem.rightBarButtonItem?.tintColor = theme.style == .Dark ? theme.redColor : theme.globalTintColor
		self.view.backgroundColor = theme.viewBackgroundColor
		if theme.style == .Dark {
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
			label.textColor = theme.emptyStateLabelColor
			label.text = NSLocalizedString("No albums here yet!", comment: "")
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
			alert.title = NSLocalizedString("You're Offline!", comment: "")
			alert.message = NSLocalizedString("Please make sure you are connected to the internet, then try again.", comment: "")
			let alertActionTitle = NSLocalizedString("Settings", comment: "")
			alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		case API.Error.ServerDownForMaintenance:
			alert.title = NSLocalizedString("Service Unavailable", comment: "")
			alert.message = NSLocalizedString("We'll be back shortly, our servers are currently undergoing maintenance.", comment: "")
		default:
			alert.title = title
			alert.message = message
		}
		let title = NSLocalizedString("OK", comment: "")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "SubscriptionDetailCellSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
			detailController.artist = AppDB.sharedInstance.getAlbumArtist(selectedAlbum.ID)!
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
			let filename = theme.style == .Dark ? "icon_artwork_dark" : "icon_artwork"
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
	var emptyStateLabelColor: UIColor!
	
	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			viewBackgroundColor = UIColor.clearColor()
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			emptyStateLabelColor = globalTintColor
		case .Light:
			viewBackgroundColor = UIColor.whiteColor()
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			artistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			emptyStateLabelColor = globalTintColor
		}
	}
}
