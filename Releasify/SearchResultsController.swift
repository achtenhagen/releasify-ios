
import UIKit

class SearchResultsController: UIViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var artists: [NSDictionary]!
    var artwork = [String:UIImage]()
	var selectedArtists = NSMutableArray()
	var keyword: String!
    
	@IBOutlet weak var navBar: UINavigationBar!
	@IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var artistsTable: UITableView!
    
    @IBAction func closeView(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {		
		super.viewDidLoad()
		
        artistsTable.registerNib(UINib(nibName: "SearchResultsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
		
		infoLabel.text = "Search results for \"\(keyword)\"."
		
		// Navigation bar customization.
		let image = UIImage(named: "navBar.png")
		navBar.setBackgroundImage(image, forBarMetrics: UIBarMetrics.Default)
		navBar.shadowImage = UIImage()
		navBar.translucent = true
		
		// Background gradient.
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
    
    func confirmArtist (sender: UIButton) {
		var artistID = 0
		
		if let id = (artists[sender.tag]["artistId"] as? Int) {
			artistID = id
		}
		
		let artistTitle = (artists[sender.tag]["title"] as? String)!
		if let artistUniqueID  = (artists[sender.tag]["iTunesUniqueID"] as? Int) {
			let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID=\(artistUniqueID)"
			API.sharedInstance.sendRequest(APIURL.confirmArtist.rawValue, postString: postString, successHandler: { (response, data) in
				if let HTTPResponse = response as? NSHTTPURLResponse {
					println("HTTP status code: \(HTTPResponse.statusCode)")
					if HTTPResponse.statusCode == 200 {
						UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
							artistsTable.headerViewForSection(sender.tag)?.alpha = 0.2
						}, completion: { (state) in
							let newArtistID = AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID)
							AppDB.sharedInstance.getArtists()
							self.selectedArtists.addObject(artistUniqueID)
							if newArtistID > 0 {
								println("Successfully subscribed.")
							}
							if self.artists.count == self.selectedArtists.count {
								self.dismissViewControllerAnimated(true, completion: nil)
							}
						})
					}
				}
			},
			errorHandler: { (error) in
				var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
			})
		}
    }
}

// MARK: - UITableViewDataSource
extension SearchResultsController: UITableViewDataSource {		
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! ArtistCell
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
					NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
						if error != nil {
							return
						}
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
						
					})
				}
			}
		}
		var bgColorView = UIView()
		bgColorView.backgroundColor = UIColor.clearColor()
		cell.selectedBackgroundView = bgColorView
		return cell
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return artists.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let albums = (artists[section]["albums"] as? [NSDictionary])!
		return albums.count
	}
}

// MARK: - UITableViewDelegate
extension SearchResultsController: UITableViewDelegate {	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 50
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = artistsTable.dequeueReusableHeaderFooterViewWithIdentifier("header") as! SearchResultsHeader
		let artistID = (artists[section]["iTunesUniqueID"] as? Int)!
		headerView.contentView.backgroundColor = UIColor.clearColor()
		headerView.artistLabel.text = artists[section]["title"] as? String
		headerView.confirmBtn.tag = section
		headerView.confirmBtn.addTarget(self, action: "confirmArtist:", forControlEvents: .TouchUpInside)
		headerView.artistImg.alpha = 1.0
		headerView.artistLabel.alpha = 1.0
		headerView.confirmBtn.alpha = 1.0
		if selectedArtists.containsObject(artistID) {
			headerView.artistImg.alpha = 0.2
			headerView.artistLabel.alpha = 0.2
			headerView.confirmBtn.alpha = 0.2
		}
		return headerView
	}
}
