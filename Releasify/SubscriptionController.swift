
import UIKit

class SubscriptionController: UICollectionViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let subscriptionCellReuseIdentifier = "subscriptionCell"
	var artistCollectionLayout: UICollectionViewFlowLayout!
	var refreshControl: UIRefreshControl!

	@IBOutlet var artistsCollectionView: UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Register CollectionView Cell Nib.
		artistsCollectionView.registerNib(UINib(nibName: "SubscriptionCell", bundle: nil), forCellWithReuseIdentifier: subscriptionCellReuseIdentifier)
		
		// Add Edge insets to compensate for navigation bar.
		artistsCollectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		artistsCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
		
		// Collection view layout settings.
		let defaultItemSize = CGSize(width: 145, height: 180)
		artistCollectionLayout = UICollectionViewFlowLayout()
		artistCollectionLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		artistCollectionLayout.itemSize = defaultItemSize
		artistCollectionLayout.minimumLineSpacing = 10
		artistCollectionLayout.minimumInteritemSpacing = 10
		
		switch UIScreen.mainScreen().bounds.width {
		// iPhone 4S, 5, 5C & 5S
		case 320:
			artistCollectionLayout.itemSize = defaultItemSize
		// iPhone 6
		case 375:
			artistCollectionLayout.itemSize = CGSize(width: 172, height: 207)
		// iPhone 6 Plus
		case 414:
			artistCollectionLayout.itemSize = CGSize(width: 192, height: 227)
		default:
			artistCollectionLayout.itemSize = defaultItemSize
		}
		
		artistsCollectionView.setCollectionViewLayout(artistCollectionLayout, animated: false)
		
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
    }

	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = artistsCollectionView.dequeueReusableCellWithReuseIdentifier(subscriptionCellReuseIdentifier, forIndexPath: indexPath) as! SubscriptionCell
		cell.subscriptionTitle.text = AppDB.sharedInstance.artists[indexPath.row].title as String
		cell.optionsBtn.tag = indexPath.row
		cell.optionsBtn.addTarget(self, action: "deleteArtist:", forControlEvents: .TouchUpInside)
		return cell
	}
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return AppDB.sharedInstance.artists.count
	}
    
	func deleteArtist (sender: UIButton) {
		let rowIndex = sender.tag
		var alert = UIAlertController(title: "Remove Subscription?", message: "Please confirm that you want to unsubscribe from this artist.", preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Confirm", style: .Destructive, handler: { action in
			let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&artistUniqueID=\(AppDB.sharedInstance.artists[rowIndex].iTunesUniqueID)"
			API.sharedInstance.sendRequest(APIURL.removeArtist.rawValue, postString: postString, successHandler: { (response, data) in
				if let HTTPResponse = response as? NSHTTPURLResponse {
					println("HTTP status code: \(HTTPResponse.statusCode)")
					if HTTPResponse.statusCode == 204 {
						println("Successfully unsubscribed.")
					}
				}
			},
			errorHandler: { (error) in
				AppDB.sharedInstance.addPendingArtist(AppDB.sharedInstance.artists[rowIndex].ID)
				var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
			})
			AppDB.sharedInstance.deleteArtist(AppDB.sharedInstance.artists[rowIndex].ID, index: rowIndex)
			self.artistsCollectionView.reloadData()
		}))
		presentViewController(alert, animated: true, completion: nil)
	}
}
