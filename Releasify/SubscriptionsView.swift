
import UIKit
import MediaPlayer

class SubscriptionsView: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var responseArtists = [NSDictionary]()
    var refreshControl: UIRefreshControl!
    var mediaQuery = MPMediaQuery.artistsQuery()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var artistImg: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        if AppDB.sharedInstance.artists.count == 0 {
            /*tableView.hidden = true
            let subscriptionsIcon: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
            let imagePath = NSBundle.mainBundle().pathForResource("icon_empty_subscriptions", ofType: "png")
            subscriptionsIcon.image = UIImage(named: imagePath!)
            subscriptionsIcon.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 60)
            self.view.addSubview(subscriptionsIcon)*/
        }
        refreshDB()
    }
    
    func refreshDB () {
        AppDB.sharedInstance.getArtists()
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        refresh()
        if AppDB.sharedInstance.artists.count > 0 {
            tableView.hidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.editButtonItem().enabled = (AppDB.sharedInstance.artists.count > 0)
        return AppDB.sharedInstance.artists.count
    }
    
    @IBAction func closeView(sender: AnyObject) {
        tableView.setEditing(false, animated: true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addSubscription(sender: AnyObject) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        mediaQuery.groupingType = MPMediaGrouping.AlbumArtist
        if mediaQuery.collections.count > 0 {
            let importAction = UIAlertAction(title: "Music Library", style: .Default, handler: { action in
                self.performSegueWithIdentifier("ArtistPickerSegue", sender: self)
            })
            let addAction = UIAlertAction(title: "Enter Artist Title", style: .Default, handler: { action in
                self.addSubscription()
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            controller.addAction(importAction)
            controller.addAction(addAction)
            controller.addAction(cancelAction)
            self.presentViewController(controller, animated: true, completion: nil)
        } else {
            self.addSubscription()
        }
    }
    
    func addSubscription () {
        responseArtists = [NSDictionary]()
        let actionSheetController: UIAlertController = UIAlertController(title: "Artist Title", message: "We will verify this artist for you.", preferredStyle: .Alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        actionSheetController.addAction(cancelAction)
        let addAction: UIAlertAction = UIAlertAction(title: "Add", style: .Default) { action -> Void in
            let textField = actionSheetController.textFields![0] as! UITextField
            if !textField.text.isEmpty {
                let artist = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                var responseData = []
                var batches = [String]()
                let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)"
                var batchCount = 0
                var currentBatch = postString.stringByAppendingString("&title[]=" + artist)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                println("Processing batch: \(currentBatch)")
                let apiUrl = NSURL(string: APIURL.submitArtist.rawValue)
                let request = NSMutableURLRequest(URL:apiUrl!)
                request.HTTPMethod = "POST"
                request.HTTPBody = currentBatch.dataUsingEncoding(NSUTF8StringEncoding)
                request.timeoutInterval = 300
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) in
                    if error == nil {
                        if let HTTPResponse = response as? NSHTTPURLResponse {
                            println(HTTPResponse.statusCode)
                            if HTTPResponse.statusCode == 200 {
                                if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                                    if let awaitingArtists: [NSDictionary] = json["success"] as? [NSDictionary] {
                                        for artist in awaitingArtists {
                                            if let uniqueID = artist["iTunesUniqueID"] as? Int {
                                                if AppDB.sharedInstance.getArtistByUniqueID(Int32(uniqueID)) == 0 {
                                                    self.responseArtists.append(artist)
                                                }
                                            }                                           
                                        }
                                    }
                                    if let failedArtists: [NSDictionary] = json["failed"] as? [NSDictionary] {
                                        for artist in failedArtists {
                                            let title = (artist["title"] as? String)!
                                            println("Artist \(title) was not found on iTunes.")
                                        }
                                    }
                                }
                                self.refreshDB()
                                println("Completed batch processing.")
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                if self.responseArtists.count > 0 {
                                    self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
                                }
                            }
                        }
                    } else {
                        var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { action -> Void in
                            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                        }))
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action -> Void in
                            self.dismissViewControllerAnimated(true, completion: nil)
                            return
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        actionSheetController.addAction(addAction)
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.keyboardAppearance = .Dark
            textField.autocapitalizationType = .Words
            textField.placeholder = "e.g., Armin van Buuren"
        }
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("subscriptionCell") as! SubscriptionCell
        cell.artistLabel.text = AppDB.sharedInstance.artists[indexPath.row].title as String
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            println(AppDB.sharedInstance.artists[indexPath.row].iTunesUniqueID)
            var failed = true
            let apiUrl = NSURL(string: APIURL.removeArtist.rawValue)
            let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID=\(AppDB.sharedInstance.artists[indexPath.row].iTunesUniqueID)"
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
                        println(HTTPResponse.statusCode)
                        if HTTPResponse.statusCode == 200 {
                            AppDB.sharedInstance.deleteArtist(AppDB.sharedInstance.artists[indexPath.row].ID)
                            AppDB.sharedInstance.artists.removeAtIndex(indexPath.row)
                            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                            println("Successfully unsubscribed.")
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
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.tableView.setEditing(false, animated: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Unsubscribe"
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        tableView.setEditing(!tableView.editing, animated: true)
        if tableView.editing {
            self.editButtonItem().title = "Done"
            self.editButtonItem().style = UIBarButtonItemStyle.Done
        } else {
            self.editButtonItem().title = "Edit"
            self.editButtonItem().style = UIBarButtonItemStyle.Plain
        }
    }
    
    func refresh() {
        var failed = true
        let apiUrl = NSURL(string: APIURL.updateArtists.rawValue)
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)"
        let request = NSMutableURLRequest(URL:apiUrl!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        request.timeoutInterval = 30
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        self.editButtonItem().enabled = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) in
            if error == nil {
                if let HTTPResponse = response as? NSHTTPURLResponse {
                    println("HTTP status code: \(HTTPResponse.statusCode)")
                    if HTTPResponse.statusCode == 200 {
                        var error: NSError?
                        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? [NSDictionary] {
                            if error != nil {
                                return
                            }
                            for item in json {
                                let artistID: Int = item["artistId"] as! Int
                                let artistTitle: String = String(stringInterpolationSegment: item["title"]!)
                                let artistUniqueID: Int = item["iTunesUniqueID"] as! Int
                                let newArtistID = AppDB.sharedInstance.addArtist(Int32(artistID), artistTitle: artistTitle, iTunesUniqueID: Int32(artistUniqueID))
                            }
                            self.refreshDB()
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
            if failed {

            } else {

            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if AppDB.sharedInstance.artists.count > 0 {
                self.editButtonItem().enabled = true
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ArtistPickerSegue" {
            var artistPickerController = segue.destinationViewController as! ArtistsPicker
            artistPickerController.collection = mediaQuery.collections
        } else if segue.identifier == "ArtistSelectionSegue" {
            var selectionController = segue.destinationViewController as! ArtistSelectionView
            selectionController.artists = responseArtists
        }
    }
}