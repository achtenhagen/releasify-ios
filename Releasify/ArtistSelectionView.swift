
import UIKit

class ArtistSelectionView: UIViewController, UITableViewDataSource {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var artistAlbums = String()
    var albums  = [NSDictionary]()
    var artists = [NSDictionary]()
    var artwork = [String:UIImage]()
    
    @IBOutlet weak var artistsTable: UITableView!
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        artistsTable.setEditing(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! ArtistCell
        cell.artistLabel?.text = artists[indexPath.row]["title"] as? String
        albums = (artists[indexPath.row]["albums"] as? [NSDictionary])!
        artistAlbums = String()
        for var i = 0; i < albums.count; i++ {
            artistAlbums = artistAlbums.stringByAppendingString((albums[i]["title"]! as! String))
            if i < albums.count-1 {
                artistAlbums = artistAlbums.stringByAppendingString(", ")
            }
        }
        cell.albumsLabel.text = artistAlbums
        if albums.count > 0 {
            let hash = albums[0]["artwork"]! as! String
            let albumURL = "https://releasify.me/static/artwork/music/\(hash).jpg"
            if let img = artwork[albumURL] {
                cell.albumArtwork.image = img
            } else {
                if let checkedURL = NSURL(string: albumURL) {
                    let request: NSURLRequest = NSURLRequest(URL: checkedURL)
                    let mainQueue = NSOperationQueue.mainQueue()
                    NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                        if error == nil {
                            if let HTTPResponse = response as? NSHTTPURLResponse {
                                println("HTTP status code: \(HTTPResponse.statusCode)")
                                if HTTPResponse.statusCode == 200 {
                                    let image = UIImage(data: data)
                                    self.artwork[albumURL] = image
                                    dispatch_async(dispatch_get_main_queue(), {
                                        if let cellToUpdate: ArtistCell = self.artistsTable.cellForRowAtIndexPath(indexPath) as? ArtistCell {
                                            cellToUpdate.albumArtwork.alpha = 0
                                            cellToUpdate.albumArtwork.image = image
                                            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {cellToUpdate.albumArtwork.alpha = 1.0}, completion: nil)
                                        }
                                    })
                                }
                            }
                        }
                    })
                }
            }
        }
        var bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let artistUniqueID = (artists[indexPath.row]["iTunesUniqueID"] as? Int)!
        var failed = true
        let apiUrl = NSURL(string: APIURL.confirmArtist.rawValue)
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID=\(artistUniqueID)"
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
                        println("Successfully subscribed.")
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
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
}
