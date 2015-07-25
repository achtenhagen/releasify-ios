
import UIKit

class ArtistSelectionView: UIViewController, UITableViewDataSource {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var artists: [NSDictionary]!
    var artwork = [String:UIImage]()
    
    @IBOutlet weak var artistsTable: UITableView!
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.artistsTable.registerNib(UINib(nibName: "TableViewHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return artists.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let albums = (artists[section]["albums"] as? [NSDictionary])!
        return albums.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! ArtistCell
        let albums = (artists[indexPath.section]["albums"] as? [NSDictionary])!
        if albums.count > 0 {
            cell.albumTitle.text = albums[indexPath.row]["title"] as? String
            cell.releaseLabel.text = albums[indexPath.row]["releaseDate"] as? String
            let hash = albums[indexPath.row]["artwork"]! as! String
            let albumURL = "https://releasify.me/static/artwork/music/\(hash).jpg"
            if let img = artwork[albumURL] {
                cell.albumArtwork.image = img
            } else {
                if let checkedURL = NSURL(string: albumURL) {
                    let request = NSURLRequest(URL: checkedURL)
                    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response, data, error) in
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
                                            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { cellToUpdate.albumArtwork.alpha = 1.0 }, completion: nil)
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
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = self.artistsTable.dequeueReusableHeaderFooterViewWithIdentifier("header") as! ArtistSelectionHeaderView
        headerView.contentView.backgroundColor = UIColor.clearColor()
        headerView.artistLabel.text = artists[section]["title"] as? String
        headerView.confirmBtn.tag = section
        headerView.confirmBtn.addTarget(self, action: "confirmArtist:", forControlEvents: .TouchUpInside)
        return headerView
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func confirmArtist (sender: UIButton) {
        let artistUniqueID  = (artists[sender.tag]["iTunesUniqueID"] as? Int)!
        let apiUrl = NSURL(string: APIURL.confirmArtist.rawValue)
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID=\(artistUniqueID)"
        let request = NSMutableURLRequest(URL:apiUrl!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        request.timeoutInterval = 30
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            if error == nil {
                if let HTTPResponse = response as? NSHTTPURLResponse {
                    println("HTTP status code: \(HTTPResponse.statusCode)")
                    if HTTPResponse.statusCode == 200 {
                        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.artistsTable.headerViewForSection(sender.tag)?.alpha = 0.2 }, completion: nil)
                        println("Successfully subscribed.")
                    }
                }
            } else {
                var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
}
