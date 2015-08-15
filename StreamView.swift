
import UIKit

class StreamView: UITableViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var selectedAlbum: Album!
	var artwork = [String:UIImage]()
	var notificationAlbumID: Int!
	
	@IBOutlet weak var streamTable: UITableView!
	
	@IBAction func OpenAppSettings(sender: AnyObject) {
		UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromRemoteNotification:", name: "appActionPressed", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshContent", object: nil)
		
		// Register Tableview cell nib.
		streamTable.registerNib(UINib(nibName: "StreamCell", bundle: nil), forCellReuseIdentifier: "streamCell")
		
		// Pull-to-refresh Control
		self.refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl?.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
		
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
		longPressGesture.minimumPressDuration = 0.5
		streamTable.addGestureRecognizer(longPressGesture)
		
		// Load data from database.
		AppDB.sharedInstance.getArtists()
		AppDB.sharedInstance.getAlbums()
		
		// Check for any pending artists waiting to be removed.
		let pendingArtists = AppDB.sharedInstance.getPendingArtists()
		
		// Notification payload processing
		// The remote notification payload will return 'content-available: 1' if there is new content.
		if let remoteContent = appDelegate.remoteNotificationPayload["aps"]?["content-available"] as? Int {
			println("ok")
			if remoteContent == 1 {
				refresh()
			}
		}
		if let localContent = appDelegate.localNotificationPayload["AlbumID"] as? Int {
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
		
		// For Notifications Test
		/*var notification = UILocalNotification()
		notification.category = "DEFAULT_CATEGORY"
		notification.timeZone = NSTimeZone.localTimeZone()
		notification.alertTitle = "New Album Released"
		notification.alertBody = "\"Album\" is now available!"
		notification.fireDate = NSDate().dateByAddingTimeInterval(5)
		notification.applicationIconBadgeNumber = 1
		notification.soundName = UILocalNotificationDefaultSoundName
		notification.userInfo = ["AlbumID": 3127, "iTunesURL": "https://itunes.apple.com/us/album/long-walk-to-freedom-fuego/id1015003602?uo=4"]
		UIApplication.sharedApplication().scheduleLocalNotification(notification)*/
		
		// Refresh the App's content only once per day.
		if appDelegate.userID > 0 && Int(NSDate().timeIntervalSince1970) - appDelegate.lastUpdated >= 86400 {
			println("Starting daily refresh.")
			refresh()
		}
    }
	
	override func viewWillAppear(animated: Bool) {
		if AppDB.sharedInstance.artists.count > 0 && AppDB.sharedInstance.albums[0]!.count == 0 && AppDB.sharedInstance.albums[1]!.count == 0 {
			refresh()
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func refresh() {
		if AppDB.sharedInstance.artists.count == 0 {
			API.sharedInstance.refreshSubscriptions(nil, errorHandler: nil)
		}
		API.sharedInstance.refreshContent({ (newItems) in
			self.streamTable.reloadData()
			self.refreshControl?.endRefreshing()
			if newItems.count > 0 {
				let albumsTabBarItem = self.tabBarController?.tabBar.items?[0] as! UITabBarItem
				albumsTabBarItem.badgeValue = String(newItems.count)
			}
		},
			errorHandler: { (error) in
			self.refreshControl?.endRefreshing()
			var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
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
	
	func delay(delay:Double, closure: ()->()) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
	}

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return AppDB.sharedInstance.albums.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppDB.sharedInstance.albums[section]!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("streamCell", forIndexPath: indexPath) as! StreamCell
		cell.preservesSuperviewLayoutMargins = false
		// For Dark Theme
		/*var selectedView = UIView()
		selectedView.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1.0)
		cell.selectedBackgroundView = selectedView*/
		
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
					if error == nil {
						if let HTTPResponse = response as? NSHTTPURLResponse {
							println("HTTP status code: \(HTTPResponse.statusCode)")
							if HTTPResponse.statusCode == 200 {
								let image = UIImage(data: data)
								self.artwork[hash] = image
								dispatch_async(dispatch_get_main_queue(), {
									if let cellToUpdate = self.streamTable.cellForRowAtIndexPath((indexPath)) as? StreamCell {
										AppDB.sharedInstance.addArtwork(hash, artwork: image!)
										cell.albumArtwork.image = image
										UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
											cell.albumArtwork.alpha = 1.0
										}, completion: nil)
									}
								})
							}
						}
					}
				})
			}
		}
		
		cell.artistLabel.text = AppDB.sharedInstance.getAlbumArtist(Int32(album.ID))
		cell.albumTitle.text = album.title
		cell.albumTitle.userInteractionEnabled = false
		cell.albumTitle.textContainerInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0);
		cell.albumTitle.textContainer.lineFragmentPadding = 0;
		
		if timeDiff > 0 {
			let dateAdded = AppDB.sharedInstance.getAlbumDateAdded(Int32(album.ID))
			cell.timeRemainingLabel.hidden = false
			cell.progressBar.hidden = false
			cell.progressBar.setProgress(album.getProgress(dateAdded), animated: false)
		} else {
			cell.timeRemainingLabel.hidden = true
			cell.progressBar.hidden = true
		}
		
		var weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
		var days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
		var hours   = component(Double(timeDiff),      v: 60 * 60) % 24
		var minutes = component(Double(timeDiff),           v: 60) % 60
		var seconds = component(Double(timeDiff),            v: 1) % 60
		
		if Int(weeks) > 0 {
			cell.timeRemainingLabel.text = "\(Int(weeks)) wks"
			if Int(weeks) == 1  {
				cell.timeRemainingLabel.text = "\(Int(weeks)) wk"
			}
		} else if Int(days) > 0 && Int(days) <= 7 {
			cell.timeRemainingLabel.text = "\(Int(days)) days"
			if Int(days) == 1  {
				cell.timeRemainingLabel.text = "\(Int(days)) day"
			}
		} else if Int(hours) > 0 && Int(hours) <= 24 {
			if Int(hours) >= 12 {
				cell.timeRemainingLabel.text = "Today"
			} else {
				cell.timeRemainingLabel.text = "\(Int(hours)) hrs"
				if Int(hours) == 1  {
					cell.timeRemainingLabel.text = "\(Int(days)) hr"
				}
			}
		} else if Int(minutes) > 0 && Int(minutes) <= 60 {
			cell.timeRemainingLabel.text = "\(Int(minutes)) min"
		} else if Int(seconds) > 0 && Int(seconds) <= 60 {
			cell.timeRemainingLabel.text = "\(Int(seconds)) sec"
		}
		
        return cell
    }
	
	func component (x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if (section == 0) {
			return "Upcoming Music"
		}
		return "Recently Released"
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedAlbum = AppDB.sharedInstance.albums[indexPath.section]![indexPath.row]
		streamTable.deselectRowAtIndexPath(indexPath, animated: true)
		performSegueWithIdentifier("AlbumViewSegue", sender: self)
	}
	
	func longPressGestureRecognized(gesture: UIGestureRecognizer) {
		var cellLocation = gesture.locationInView(streamTable)
		let indexPath = streamTable.indexPathForRowAtPoint(cellLocation)
		if indexPath?.row != nil {
			if gesture.state == UIGestureRecognizerState.Began {
				let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
				let buyAction = UIAlertAction(title: "Open in iTunes Store", style: .Default, handler: { action in
					let albumURL = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].iTunesURL
					if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumURL)!) {
						UIApplication.sharedApplication().openURL(NSURL(string: albumURL)!)
					}
				})
				let reportAction = UIAlertAction(title: "Report a problem", style: .Default, handler: { action in
					// Implement...
				})
				let deleteAction = UIAlertAction(title: "Unsubscribe", style: .Destructive, handler: { action in
					let albumID = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].ID
					let albumArtwork = AppDB.sharedInstance.albums[indexPath!.section]![indexPath!.row].artwork
					for n in UIApplication.sharedApplication().scheduledLocalNotifications {
						var notification = n as! UILocalNotification
						let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
						let ID = userInfoCurrent["ID"]! as! Int
						if ID == albumID {
							println("Canceled location notification with ID: \(ID)")
							UIApplication.sharedApplication().cancelLocalNotification(notification)
							break
						}
					}
					UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
						self.streamTable.cellForRowAtIndexPath(indexPath!)?.alpha = 0
					}, completion: { (value: Bool) in
						AppDB.sharedInstance.deleteAlbum(Int32(albumID))
						AppDB.sharedInstance.deleteArtwork(albumArtwork as String)
						AppDB.sharedInstance.getAlbums()
						AppDB.sharedInstance.getArtists()
						self.streamTable.reloadData()
					})
				})
				let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
				controller.addAction(buyAction)
				controller.addAction(reportAction)
				controller.addAction(deleteAction)
				controller.addAction(cancelAction)
				self.presentViewController(controller, animated: true, completion: nil)
			}
		}
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "AlbumViewSegue" {
			var detailController = segue.destinationViewController as! AlbumView
			detailController.album = selectedAlbum
		}
    }
}
