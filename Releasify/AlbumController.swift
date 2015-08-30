
import UIKit

class AlbumController: UICollectionViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let albumCellReuseIdentifier = "AlbumCell"
	let albumCollectionHeaderViewReuseIdentifier = "albumCollectionHeader"
	let albumCollectionFooterViewReuseIdentifier = "albumCollectionFooter"
	var albumCollectionLayout: UICollectionViewFlowLayout!
	var selectedAlbum: Album!
	var artwork = [String:UIImage]()
	var notificationAlbumID: Int!
	var refreshControl: UIRefreshControl!

	@IBOutlet var albumCollectionView: UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromRemoteNotification:", name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshContent", object: nil)
		
		// Register CollectionView Cell Nib.
		albumCollectionView.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)
		
		// Add Edge insets to compensate for navigation bar.
		albumCollectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		albumCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		
		// Collection view layout settings.
		let defaultItemSize = CGSize(width: 145, height: 190)
		albumCollectionLayout = UICollectionViewFlowLayout()
		albumCollectionLayout.headerReferenceSize = CGSize(width: 50, height: 50)
		albumCollectionLayout.footerReferenceSize = CGSize(width: 50, height: 10)
		albumCollectionLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		albumCollectionLayout.itemSize = defaultItemSize
		albumCollectionLayout.minimumLineSpacing = 10
		albumCollectionLayout.minimumInteritemSpacing = 10
		
		switch UIScreen.mainScreen().bounds.width {
		// iPhone 4S, 5, 5C & 5S
		case 320:
			albumCollectionLayout.itemSize = defaultItemSize
		// iPhone 6
		case 375:
			albumCollectionLayout.itemSize = CGSize(width: 172, height: 217)
		// iPhone 6 Plus
		case 414:
			albumCollectionLayout.itemSize = CGSize(width: 192, height: 147)
		default:
			albumCollectionLayout.itemSize = defaultItemSize
		}
		
		albumCollectionView.setCollectionViewLayout(albumCollectionLayout, animated: false)
		
		// Pull-to-refresh Control.
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		albumCollectionView.addSubview(refreshControl)
		
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 0.5
		albumCollectionView.addGestureRecognizer(longPressGesture)
		
		// Notification payload processing
		// The remote notification payload will return 'content-available: 1' if there is new content.
		if let remoteContent = appDelegate.remoteNotificationPayload?["aps"]?["content-available"] as? Int {
			if remoteContent == 1 {
				refresh()
			}
		}
		
		if let localContent = appDelegate.localNotificationPayload?["AlbumID"] as? Int {
			notificationAlbumID = localContent
			for album in AppDB.sharedInstance.albums[1] as[Album]! {
				if album.ID == notificationAlbumID {
					selectedAlbum = album
					break
				}
			}
			if selectedAlbum.ID == notificationAlbumID {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
		
		/*
			var notification = UILocalNotification()
			notification.category = "DEFAULT_CATEGORY"
			notification.timeZone = NSTimeZone.localTimeZone()
			notification.alertTitle = "New Album Released"
			notification.alertBody = "\"Album\" is now available!"
			notification.fireDate = NSDate().dateByAddingTimeInterval(5)
			notification.applicationIconBadgeNumber = 1
			notification.soundName = UILocalNotificationDefaultSoundName
			notification.userInfo = ["AlbumID": 3127, "iTunesURL": "https://itunes.apple.com/us/album/long-walk-to-freedom-fuego/id1015003602?uo=4"]
			UIApplication.sharedApplication().scheduleLocalNotification(notification)
		*/
		
		// Refresh the App's content only once per day.
		// println(appDelegate.lastUpdated)
		if appDelegate.userID > 0 && (Int(NSDate().timeIntervalSince1970) - appDelegate.lastUpdated >= 86400) {
			println("Starting daily refresh.")
			refresh()
		}		
	}
	
	override func viewWillAppear(animated: Bool) {
		// AppDB.sharedInstance.getAlbums() -> move to different location !!!
		albumCollectionView.reloadData()
		albumCollectionView.scrollsToTop = true
		if AppDB.sharedInstance.artists.count > 0 && AppDB.sharedInstance.albums[0]!.count == 0 && AppDB.sharedInstance.albums[1]!.count == 0 {
			refresh()
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		albumCollectionView.scrollsToTop = false
	}
	
	func refresh() {
		if AppDB.sharedInstance.artists.count == 0 {
			API.sharedInstance.refreshSubscriptions(nil, errorHandler: nil)
		}
		API.sharedInstance.refreshContent({ (newItems) in
			self.albumCollectionView.reloadData()
			self.refreshControl.endRefreshing()
			if newItems.count > 0 {
				// Show updates...
			}
		},
		errorHandler: { (error) in
			self.refreshControl.endRefreshing()
			var alert = UIAlertController(title: "Oops! Something went wrong.", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
			if error.code == 403 {
				alert.addAction(UIAlertAction(title: "Fix it!", style: UIAlertActionStyle.Default, handler: { action in
					// Todo: implement...
				}))
			}
			alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
			self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	func showAlbumFromNotification(notification: NSNotification) {
		if let AlbumID = notification.userInfo!["AlbumID"]! as? Int {
			notificationAlbumID = AlbumID
			for album in AppDB.sharedInstance.albums[1] as[Album]! {
				if album.ID == notificationAlbumID {
					selectedAlbum = album
					break
				}
			}
			if selectedAlbum.ID == notificationAlbumID {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
	}
	
	// Search the array in reverse for better performance.
	func showAlbumFromRemoteNotification(notification: NSNotification) {
		if let AlbumID = notification.userInfo?["aps"]?["AlbumID"]! as? Int {
			notificationAlbumID = AlbumID
			for album in AppDB.sharedInstance.albums[0] as[Album]! {
				if album.ID == notificationAlbumID {
					selectedAlbum = album
					break
				}
			}
			if selectedAlbum.ID == notificationAlbumID {
				self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
			}
		}
	}
	
	// Determines current section ('upcoming' or 'recently released').
	// This function is only called when there is one section.
	func sectionAtIndex () -> Int {
		return AppDB.sharedInstance.albums[0]!.count > 0 ? 0 : 1
	}

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		var sections = 0
		if AppDB.sharedInstance.albums[0]!.count > 0 {
			sections++
		}
		if AppDB.sharedInstance.albums[1]!.count > 0 {
			sections++
		}
        return sections
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AppDB.sharedInstance.albums[section]!.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(albumCellReuseIdentifier, forIndexPath: indexPath) as! AlbumCell
		let album = AppDB.sharedInstance.albums[indexPath.section]![indexPath.row]
		cell.albumArtwork.image = UIImage()
		let hash = album.artwork as String
		let timeDiff = album.releaseDate - NSDate().timeIntervalSince1970
		let dbArtwork = AppDB.sharedInstance.checkArtwork(hash)
		if dbArtwork {
			artwork[hash] = AppDB.sharedInstance.getArtwork(hash)
		}
		if let image = artwork[hash] {
			cell.albumArtwork.image = image
		} else {
			cell.albumArtwork.alpha = 0
			let albumURL = "https://releasify.me/static/artwork/music/\(hash)@2x.jpg"
			if let checkedURL = NSURL(string: albumURL) {
				let request = NSURLRequest(URL: checkedURL)
				let mainQueue = NSOperationQueue.mainQueue()
				NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) in
					if error != nil {
						return
					}
					if let HTTPResponse = response as? NSHTTPURLResponse {
						println("HTTP status code: \(HTTPResponse.statusCode)")
						if HTTPResponse.statusCode == 200 {
							let image = UIImage(data: data)
							self.artwork[hash] = image
							dispatch_async(dispatch_get_main_queue(), {
								if let cellToUpdate = self.albumCollectionView.cellForItemAtIndexPath((indexPath)) as? AlbumCell {
									AppDB.sharedInstance.addArtwork(hash, artwork: image!)
									cell.albumArtwork.image = image
									UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
										cell.albumArtwork.alpha = 1.0
									}, completion: nil)
								}
							})
						}
					}
					
				})
			}
		}
		
		cell.artistTitle.text = AppDB.sharedInstance.getAlbumArtist(album.ID)
		cell.albumTitle.text = album.title
		cell.albumTitle.userInteractionEnabled = false
		
		if timeDiff > 0 {
			let dateAdded = AppDB.sharedInstance.getAlbumDateAdded(album.ID)
			cell.containerView.hidden = false
			cell.progressBar.setProgress(album.getProgress(dateAdded), animated: false)
		} else {
			cell.containerView.hidden = true
		}
		
		var weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
		var days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
		var hours   = component(Double(timeDiff),      v: 60 * 60) % 24
		var minutes = component(Double(timeDiff),           v: 60) % 60
		var seconds = component(Double(timeDiff),            v: 1) % 60
		
		if Int(weeks) > 0 {
			cell.timeLeft.text = "\(Int(weeks)) weeks"
			if Int(weeks) == 1  {
				cell.timeLeft.text = "\(Int(weeks)) week"
			}
		} else if Int(days) > 0 && Int(days) <= 7 {
			cell.timeLeft.text = "\(Int(days)) days"
			if Int(days) == 1  {
				cell.timeLeft.text = "\(Int(days)) day"
			}
		} else if Int(hours) > 0 && Int(hours) <= 24 {
			if Int(hours) >= 12 {
				cell.timeLeft.text = "Today"
			} else {
				cell.timeLeft.text = "\(Int(hours)) hours"
				if Int(hours) == 1  {
					cell.timeLeft.text = "\(Int(days)) hour"
				}
			}
		} else if Int(minutes) > 0 && Int(minutes) <= 60 {
			cell.timeLeft.text = "\(Int(minutes)) minute"
		} else if Int(seconds) > 0 && Int(seconds) <= 60 {
			cell.timeLeft.text = "\(Int(seconds)) second"
		}
		
		return cell
    }
	
	func component (x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		if kind == UICollectionElementKindSectionHeader {
			let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: albumCollectionHeaderViewReuseIdentifier, forIndexPath: indexPath) as! AlbumCollectionHeader
			if indexPath.section == 0 {
				headerView.headerLabel.text = "UPCOMING"
			} else {
				headerView.headerLabel.text = "RECENTLY RELEASED"
			}
			return headerView
		}
		let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: albumCollectionFooterViewReuseIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
		return footerView
	}
	
	override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		selectedAlbum = AppDB.sharedInstance.albums[indexPath.section]![indexPath.row]
		performSegueWithIdentifier("AlbumViewSegue", sender: self)
		return true
	}
	
	func longPressGestureRecognized(gesture: UIGestureRecognizer) {
		var cellLocation = gesture.locationInView(albumCollectionView)
		let indexPath = albumCollectionView.indexPathForItemAtPoint(cellLocation)
		
		if indexPath?.row != nil {
			if gesture.state == UIGestureRecognizerState.Began {
				let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
				let buyAction = UIAlertAction(title: "Open in iTunes Store", style: .Default, handler: { action in
					let albumURL = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].iTunesURL
					if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumURL)!) {
						UIApplication.sharedApplication().openURL(NSURL(string: albumURL)!)
					}
				})
				controller.addAction(buyAction)
				
				let reportAction = UIAlertAction(title: "Report a problem", style: .Default, handler: { action in
					// Todo: implement...
				})
				controller.addAction(reportAction)
				
				if AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].releaseDate - NSDate().timeIntervalSince1970 > 0 {
					let deleteAction = UIAlertAction(title: "Don't Notify", style: .Destructive, handler: { action in
						let albumID = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].ID
						let albumArtwork = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].artwork
						for n in UIApplication.sharedApplication().scheduledLocalNotifications {
							var notification = n as! UILocalNotification
							let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
							let ID = userInfoCurrent["AlbumID"]! as! Int
							if ID == albumID {
								println("Canceled location notification with ID: \(ID)")
								UIApplication.sharedApplication().cancelLocalNotification(notification)
								break
							}
						}
						UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
							albumCollectionView.cellForItemAtIndexPath(indexPath!)?.alpha = 0
							}, completion: { (value: Bool) in
								AppDB.sharedInstance.deleteAlbum(albumID, section: indexPath!.section, index: indexPath!.row)
								AppDB.sharedInstance.deleteArtwork(albumArtwork as String)
								self.albumCollectionView.reloadData()
						})
					})
					controller.addAction(deleteAction)
				} else {
					let hideAction = UIAlertAction(title: "Hide Album", style: .Destructive, handler: { action in
						let albumID = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].ID
						UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
							albumCollectionView.cellForItemAtIndexPath(indexPath!)?.alpha = 0
							}, completion: { (value: Bool) in
								// Todo: implement...
						})
					})
					controller.addAction(hideAction)
				}
				
				let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
				controller.addAction(cancelAction)
				presentViewController(controller, animated: true, completion: nil)
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			var detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
		}
	}
	
	func delay(delay:Double, closure: ()->()) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
	}
}
