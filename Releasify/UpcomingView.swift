
import UIKit

class UpcomingView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var refreshControl:UIRefreshControl!
    var selectedAlbum = Int()
    var artwork = [String:UIImage]()
    var notificationAlbumID = Int()
    
    @IBOutlet weak var albumCollectionView: UICollectionView!
    @IBOutlet weak var subscriptionsBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "appActionPressed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAlbumFromNotification:", name: "showAlbum", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"openiTunes:", name: "storeActionPressed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"refresh", name: "refreshApp", object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        albumCollectionView.addSubview(refreshControl)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: Selector("longPressGestureRecognized:"))
        longPressGesture.minimumPressDuration = 0.5
        albumCollectionView.addGestureRecognizer(longPressGesture)
        
        // Load data into database.
        AppDB.sharedInstance.getArtists()
        AppDB.sharedInstance.getAlbums()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.mainScreen().bounds.width / 2, height: UIScreen.mainScreen().bounds.width / 2)
        
        // iPhone 6 Plus support
        if UIScreen.mainScreen().bounds.width > 375 { layout.itemSize = CGSize(width: 138, height: 138) }
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        albumCollectionView.collectionViewLayout = layout
        
        // Notification payload processing
        if let remoteContent = appDelegate.remoteNotificationPayload["aps"]?["content-available"] as? Int {
            refresh()
        }
        if let localContent = appDelegate.localNotificationPayload["ID"] as? Int {
            notificationAlbumID = appDelegate.localNotificationPayload["ID"]! as! Int
            self.performSegueWithIdentifier("NotificationAlbumSegue", sender: self)
        }
        
        // Shadow overlay
        var gradientLayerView: UIView = UIView(frame: CGRectMake(0, 0, view.bounds.width, 100))
        var gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = gradientLayerView.bounds
        gradient.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.85).CGColor, UIColor.clearColor().CGColor]
        gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
        self.view.addSubview(gradientLayerView)
        view.bringSubviewToFront(subscriptionsBtn)
        
        /*var notification = UILocalNotification()
        notification.category = "DEFAULT_CATEGORY"
        notification.timeZone = NSTimeZone.localTimeZone()
        notification.alertTitle = "New Album Released"
        notification.alertBody = "\"Album\" is now available!"
        notification.fireDate = NSDate().dateByAddingTimeInterval(5)
        notification.applicationIconBadgeNumber = 1
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["ID": 339, "url" : "https://itunes.apple.com/us/album/no-line-on-horizon-deluxe/id305352554?uo=4"]
        UIApplication.sharedApplication().scheduleLocalNotification(notification)*/
    }
    
    override func viewWillAppear(animated: Bool) {
        if AppDB.sharedInstance.artists.count > 0 && AppDB.sharedInstance.albums.count == 0 {
            println("First time refresh.")
            refresh()
        }
    }
    
    func showAlbumFromNotification(notification:NSNotification) {
        notificationAlbumID = notification.userInfo!["ID"]! as! Int
        println(notificationAlbumID)
        self.performSegueWithIdentifier("NotificationAlbumSegue", sender: self)
    }
    
    func openiTunes(notification:NSNotification) {
        let albumURL = notification.userInfo!["url"]! as! String
        delay(0) {
            if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumURL)!) {
                UIApplication.sharedApplication().openURL(NSURL(string: albumURL)!)
            }
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AppDB.sharedInstance.albums.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("albumCell", forIndexPath: indexPath) as! AlbumCell
        cell.artwork.image = UIImage()
        let hash: String = AppDB.sharedInstance.albums[indexPath.row].artwork as String
        let timeLeft = AppDB.sharedInstance.albums[indexPath.row].releaseDate - NSDate().timeIntervalSince1970
        let dbArtwork = AppDB.sharedInstance.checkArtwork(hash)
        if dbArtwork {
            artwork[hash] = AppDB.sharedInstance.getArtwork(hash)
        }
        if let image = artwork[hash] {
            cell.artwork.image = image
        } else {
            cell.artwork.alpha = 0
            let albumURL = "https://releasify.me/static/artwork/music/\(hash)_large.jpg"
            if let checkedURL = NSURL(string: albumURL) {
                let request: NSURLRequest = NSURLRequest(URL: checkedURL)
                let mainQueue = NSOperationQueue.mainQueue()
                NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                    if error == nil {
                        if let HTTPResponse = response as? NSHTTPURLResponse {
                            println("HTTP status code: \(HTTPResponse.statusCode)")
                            if HTTPResponse.statusCode == 200 {
                                let image = UIImage(data: data)
                                self.artwork[hash] = image
                                dispatch_async(dispatch_get_main_queue(), {
                                    if let cellToUpdate = self.albumCollectionView.cellForItemAtIndexPath((indexPath)) as? AlbumCell {
                                        AppDB.sharedInstance.addArtwork(hash, artwork: image!)
                                        cell.artwork.image = image
                                        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {cell.artwork.alpha = 1.0}, completion: nil)
                                    }
                                })
                            }
                        }
                    }
                })
            }
        }
        if indexPath.row == AppDB.sharedInstance.albums.count-1 {
            /* Reached bottom */
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedAlbum = indexPath.row
        self.performSegueWithIdentifier("AlbumViewSegue", sender: self)
    }
    
    func longPressGestureRecognized(gesture: UIGestureRecognizer) {
        var cellLocation = gesture.locationInView(albumCollectionView)
        let indexPath = albumCollectionView.indexPathForItemAtPoint(cellLocation)
        if indexPath?.row != nil {
            if gesture.state == UIGestureRecognizerState.Began {
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                let buyAction = UIAlertAction(title: "Open in iTunes Store", style: .Default, handler: { action in
                    let albumURL = AppDB.sharedInstance.albums[indexPath!.row].iTunesURL
                    if UIApplication.sharedApplication().canOpenURL(NSURL(string: albumURL)!) {
                        UIApplication.sharedApplication().openURL(NSURL(string: albumURL)!)
                    }
                })
                let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
                    let albumID = AppDB.sharedInstance.albums[indexPath!.row].ID
                    let albumArtwork = AppDB.sharedInstance.albums[indexPath!.row].artwork
                    var app:UIApplication = UIApplication.sharedApplication()
                    for n in app.scheduledLocalNotifications {
                        var notification = n as! UILocalNotification
                        let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
                        let ID = userInfoCurrent["ID"]! as! Int
                        if ID == albumID {
                            println("Canceled location notification with ID: \(ID)")
                            app.cancelLocalNotification(notification)
                            break;
                        }
                    }
                    UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { self.albumCollectionView.cellForItemAtIndexPath(indexPath!)?.alpha = 0}, completion: {  (value: Bool) in
                        AppDB.sharedInstance.deleteAlbum(Int32(albumID))
                        AppDB.sharedInstance.deleteArtwork(albumArtwork as String)
                        AppDB.sharedInstance.getAlbums()
                        AppDB.sharedInstance.getArtists()
                        self.albumCollectionView.reloadData()
                    })
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                controller.addAction(buyAction)
                controller.addAction(deleteAction)
                controller.addAction(cancelAction)
                self.presentViewController(controller, animated: true, completion: nil)
            }
        }
    }
    
    func refresh() {
        let explicit = appDelegate.defaults.boolForKey("allowExplicit")
        var failed = true
        let apiUrl = NSURL(string: APIURL.updateContent.rawValue)
        var explicitValue = 1
        if !appDelegate.allowExplicitContent { explicitValue = 0 }
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&explicit=\(explicitValue)"
        let request = NSMutableURLRequest(URL:apiUrl!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        request.timeoutInterval = 30
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) in
            if error == nil {
                if let HTTPResponse = response as? NSHTTPURLResponse {
                    println("HTTP status code: \(HTTPResponse.statusCode)")
                    if HTTPResponse.statusCode == 200 {
                        var error: NSError?
                        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? [NSDictionary] {
                            if error != nil {
                                println(error)
                                return
                            }
                            for item in json {
                                let releaseDate = (item["releaseDate"] as! Double)
                                let albumItem = Album(
                                    ID: item["id"] as! Int,
                                    title: item["title"] as! String,
                                    artistID: item["artistId"] as! Int,
                                    releaseDate: releaseDate,
                                    artwork: (string: item["artwork"] as! String),
                                    explicit: item["explicit"] as! Int,
                                    copyright: item["copyright"] as! String,
                                    iTunesUniqueID: item["iTunesUniqueId"] as! Int,
                                    iTunesURL: item["iTunesUrl"] as! String,
                                    created: Int(NSDate().timeIntervalSince1970)
                                )
                                // When scheduling a notification, be sure to use the ID local to the database.
                                let newAlbumID = AppDB.sharedInstance.addAlbum(albumItem)
                                if newAlbumID > 0 {
                                    let fireDate = Double(releaseDate) - Double(NSDate().timeIntervalSince1970)
                                    if fireDate > 0 {
                                        println("Notification will fire in \(fireDate) seconds.")
                                        var notification = UILocalNotification()
                                        notification.category = "DEFAULT_CATEGORY"
                                        notification.timeZone = NSTimeZone.localTimeZone()
                                        notification.alertTitle = "New Album Released"
                                        notification.alertBody = "\(albumItem.title) is now available."
                                        notification.fireDate = NSDate(timeIntervalSince1970: item["releaseDate"] as! Double)
                                        notification.applicationIconBadgeNumber++
                                        notification.soundName = UILocalNotificationDefaultSoundName
                                        notification.userInfo = ["ID": albumItem.ID, "url": albumItem.iTunesURL]
                                        UIApplication.sharedApplication().scheduleLocalNotification(notification)
                                    }
                                    AppDB.sharedInstance.getAlbums()
                                    self.albumCollectionView.reloadData()
                                }
                            }
                            failed = false
                        }
                    }
                }
            } else {
                var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { action -> Void in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            if !failed {
                self.albumCollectionView.reloadData()
                self.appDelegate.defaults.setObject(NSDate().timeIntervalSince1970, forKey: "lastUpdated")
            }
            AppDB.sharedInstance.getAlbums()
            AppDB.sharedInstance.getArtists()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.refreshControl.endRefreshing()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AlbumViewSegue" {
            var detailController = segue.destinationViewController as! AlbumView
            detailController.album = AppDB.sharedInstance.albums[selectedAlbum]
        } else if segue.identifier == "NotificationAlbumSegue" {
            var detailController = segue.destinationViewController as! AlbumView
            var index = 0
            for album in AppDB.sharedInstance.albums {
                index++
                if album.ID == notificationAlbumID {
                    detailController.album = AppDB.sharedInstance.albums[index]
                    break
                }
            }
        }
    }
}