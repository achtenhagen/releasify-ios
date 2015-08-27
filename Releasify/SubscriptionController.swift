
import UIKit

class SubscriptionController: UICollectionViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let subscriptionCellReuseIdentifier = "subscriptionCell"
	var refreshControl: UIRefreshControl!

	@IBOutlet var artistsCollectionView: UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Register CollectionView Cell Nib.
		artistsCollectionView.registerNib(UINib(nibName: "SubscriptionCell", bundle: nil), forCellWithReuseIdentifier: subscriptionCellReuseIdentifier)
		
		// Add Edge insets to compensate for navigation bar.
		artistsCollectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		artistsCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		
		// Pull-to-refresh Control.
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		artistsCollectionView.addSubview(refreshControl)
		
		AppDB.sharedInstance.getArtists()
		artistsCollectionView.reloadData()	
    }
    
    override func viewWillAppear(animated: Bool) {
		artistsCollectionView.reloadData()
		artistsCollectionView.scrollsToTop = true
        if AppDB.sharedInstance.artists.count > 0 {
			// Show welcome screen?
        }
    }
	
	override func viewWillDisappear(animated: Bool) {
		artistsCollectionView.scrollsToTop = false
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func refresh() {
        API.sharedInstance.refreshSubscriptions({
			self.artistsCollectionView.reloadData()
			self.refreshControl.endRefreshing()
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
        if AppDB.sharedInstance.artists.count > 0 {
			
        }
    }

	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = artistsCollectionView.dequeueReusableCellWithReuseIdentifier(subscriptionCellReuseIdentifier, forIndexPath: indexPath) as! SubscriptionCell
		cell.subscriptionTitle.text = AppDB.sharedInstance.artists[indexPath.row].title as String
		return cell
	}
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return AppDB.sharedInstance.artists.count
	}
    
	/*func deleteArtist () {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID=\(AppDB.sharedInstance.artists[indexPath.row].iTunesUniqueID)"
		API.sharedInstance.sendRequest(APIURL.removeArtist.rawValue, postString: postString, successHandler: { (response, data) in
			if let HTTPResponse = response as? NSHTTPURLResponse {
				println(HTTPResponse.statusCode)
				if HTTPResponse.statusCode == 204 {
					println("Successfully unsubscribed.")
				}
			}
			},
			errorHandler: { (error) in
				AppDB.sharedInstance.addPendingArtist(AppDB.sharedInstance.artists[indexPath.row].ID)
				var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
		})
		AppDB.sharedInstance.deleteArtist(AppDB.sharedInstance.artists[indexPath.row].ID)
		AppDB.sharedInstance.artists.removeAtIndex(indexPath.row)
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
		self.subscriptionsTable.setEditing(false, animated: true)
	}*/
}
