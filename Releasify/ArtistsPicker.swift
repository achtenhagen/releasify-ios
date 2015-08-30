
import UIKit
import MediaPlayer

class ArtistsPicker: UIViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let keys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"]
    var artists = [String: [String]]()
    var checkedStates = [Int: [Int: Bool]]()
    var filteredArtists = [String]()
    var filteredCheckedStates = [Bool]()
    var hasSelectedAll = false
    var allowDuplicates = false
    var searchController = UISearchController()
    var collection = [AnyObject]()
    var responseArtists = [NSDictionary]()
    var activityView = UIView()
    var indicatorView = UIActivityIndicatorView()
	
	@IBOutlet weak var navBar: UINavigationBar!
	@IBOutlet weak var artistsTable: UITableView!
    @IBOutlet weak var selectAllBtn: UIBarButtonItem!
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBAction func selectAllArtists(sender: UIBarButtonItem) {
        hasSelectedAll = !hasSelectedAll
        if hasSelectedAll {
            selectAllBtn.title = "Deselect All"
        } else {
            filteredCheckedStates.removeAll(keepCapacity: true)
            for item in checkedStates {
                let section = item.0
                for i in item.1 {
                    checkedStates[section]?.updateValue(false, forKey: i.0)
                }
            }
            selectAllBtn.title = "Select All"
        }
        artistsTable.reloadData()
    }
    
    @IBAction func closeArtistsPicker(sender: UIBarButtonItem) {
		if searchController.active {
            searchController.dismissViewControllerAnimated(true, completion: nil)
        }
		handleBatchProcessing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var previousArtist = ""
        for item in collection {
            var representativeItem: MPMediaItem = item.representativeItem
            var artistName: AnyObject! = representativeItem.valueForProperty(MPMediaItemPropertyAlbumArtist)
            let name: String = artistName as! String
            if (allowDuplicates || name != previousArtist) && name != "Various Artists" && name != "Verschiedene Interpreten" {
                var section = keys[keys.count-1]
                var sectionHasItems = false
                var sectionIndex = 0
                for i in 0..<keys.count {
                    if name.uppercaseString.hasPrefix(keys[i]) || i == keys.count-1 {
                        section = keys[i]
                        sectionHasItems = true
                        sectionIndex = i
                        break
                    }
                }
                if artists[section] == nil {
                    artists[section] = [String]()
                }
                if checkedStates[sectionIndex] == nil {
                    checkedStates[sectionIndex] = [Int: Bool]()
                }
                checkedStates[sectionIndex]?[artists[section]!.count] = false
                artists[section]?.append(name)
                previousArtist = name
            }
        }

		setupSearchController()
		
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
	
    override func viewDidDisappear(animated: Bool) {
        hasSelectedAll = false
        responseArtists.removeAll(keepCapacity: true)
        filteredArtists.removeAll(keepCapacity: true)
        filteredCheckedStates.removeAll(keepCapacity: true)
        for item in checkedStates {
            let section = item.0
            for i in item.1 {
                checkedStates[section]?.updateValue(false, forKey: i.0)
            }
        }
        artistsTable.reloadData()
        activityView.removeFromSuperview()
        indicatorView.removeFromSuperview()
        selectAllBtn.title = "Select All"
        progressBar.setProgress(0, animated: false)
        view.userInteractionEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func handleBatchProcessing () {
        var responseData = []
        var batches = [String]()
        var uniqueIDs = [Int]()
        var totalItems = 0
        let batchSize = 20
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)"
        var batchCount = 0
        var currentBatch = String()
		
		for item in checkedStates {
            let section = item.0
            for i in item.1 {
                if i.1 == true || hasSelectedAll {
                    totalItems++
                    var artist = artists[keys[section]]![i.0]
                    artist = artist.stringByAddingPercentEncodingForURLQueryValue()!
                    currentBatch = currentBatch.stringByAppendingString("&title[]=\(artist)")
                    batchCount++
                    if batchCount == batchSize {
                        batches.append(postString.stringByAppendingString(currentBatch))
                        currentBatch = String()
                        batchCount = 0
                    }
                }
            }
        }
		
		if totalItems == 0 {
			self.dismissViewControllerAnimated(true, completion: nil)
			return
		}
		
		progressBar.hidden = false
		progressBar.progress = 0
		
        if !currentBatch.isEmpty {
            batches.append(postString.stringByAppendingString(currentBatch))
        }
        
        println("Total items: \(totalItems)")
        println("Total batches: \(batches.count)")
        
        view.userInteractionEnabled = false
        activityView = UIView(frame: CGRectMake(0, 0, 90, 90))
        activityView.center = view.center
        activityView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        activityView.layer.cornerRadius = 14
        activityView.layer.masksToBounds = true
        activityView.userInteractionEnabled = false
        indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        indicatorView.center = view.center
        view.addSubview(activityView)
        view.addSubview(indicatorView)
        indicatorView.startAnimating()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		
		var batchesProcessed = 0
        for batch in batches {
            println("Processing batch: \(batch)")
            let apiUrl = NSURL(string: APIURL.submitArtist.rawValue)
			
			API.sharedInstance.sendRequest(APIURL.submitArtist.rawValue, postString: batch, successHandler: { (response, data) in
				if let HTTPResponse = response as? NSHTTPURLResponse {
					println("Received HTTP status code \(HTTPResponse.statusCode) {handleBatchProcessing}")
					if HTTPResponse.statusCode == 202 {
						if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
							if let awaitingArtists: [NSDictionary] = json["success"] as? [NSDictionary] {
								for artist in awaitingArtists {
									if let uniqueID = artist["iTunesUniqueID"] as? Int {
										if !contains(uniqueIDs, uniqueID) && AppDB.sharedInstance.getArtistByUniqueID(uniqueID) == 0 {
											uniqueIDs.append(uniqueID)
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
						batchesProcessed++
						println("Processed batches: \(batchesProcessed)")
						let batchProgress = Float(Double(batchesProcessed) / Double(batches.count))
						self.progressBar.setProgress(batchProgress, animated: true)
						if batchesProcessed == batches.count {
							println("Completed batch processing.")
							self.progressBar.setProgress(1.0, animated: true)
							UIApplication.sharedApplication().networkActivityIndicatorVisible = false
							if self.responseArtists.count > 0 {
								self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
							} else {
								self.dismissViewControllerAnimated(true, completion: nil)
							}
						}
					} else {
						// Invalid request
						self.activityView.removeFromSuperview()
						self.indicatorView.removeFromSuperview()
					}
				}
			},
			errorHandler: { (error) in
				self.progressBar.progressTintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
				self.activityView.removeFromSuperview()
				self.indicatorView.removeFromSuperview()
				var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
					self.dismissViewControllerAnimated(true, completion: nil)
					return
				}))
				self.presentViewController(alert, animated: true, completion: nil)
			})
        }
    }
    
    func tableViewCellComponent (filteredCell: String, set: Bool) -> Bool {
        let artist = filteredCell
        var section = 0
        for i in 0..<keys.count {
            if artist.uppercaseString.hasPrefix(keys[i]) || i == keys.count-1 {
                section = i
                break
            }
        }
        for i in 0..<artists.count {
            if artists[keys[section]]![i] == artist {
                if set {
                    checkedStates[section]![i]! = !checkedStates[section]![i]!
                    return true
                }
                return checkedStates[section]![i]!
            }
        }
        return false
    }
    
    func filterContentForSearchText(searchText: String) {
        filteredArtists.removeAll(keepCapacity: true)
        filteredCheckedStates.removeAll(keepCapacity: true)
        if !searchText.isEmpty {
            let filter: String -> Bool = { artist in
                let range = artist.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
                return range != nil
            }
            for key in keys {
                if artists[key] == nil {
                    artists[key] = [String]()
                }
                let namesForKey = artists[key]!
                let matches = namesForKey.filter(filter)
                filteredArtists += matches
            }
        }
        for i in 0..<filteredArtists.count {
            filteredCheckedStates.append(tableViewCellComponent(filteredArtists[i], set: false))
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ArtistSelectionSegue" {
            var selectionController = segue.destinationViewController as! SearchResultsController
            selectionController.artists = responseArtists
        }
    }
	
	func setupSearchController () {
		searchController = UISearchController(searchResultsController: nil)
		searchController.dimsBackgroundDuringPresentation = false
		searchController.searchResultsUpdater = self
		searchController.searchBar.searchBarStyle = .Minimal
		searchController.searchBar.placeholder = "Search Artists"
		searchController.searchBar.tintColor = view.tintColor
		searchController.searchBar.barStyle = .Black
		searchController.searchBar.translucent = false
		searchController.searchBar.backgroundColor = self.view.backgroundColor
		searchController.searchBar.autocapitalizationType = .Words
		searchController.searchBar.keyboardAppearance = .Dark
		definesPresentationContext = true
		searchController.searchBar.sizeToFit()
		artistsTable.tableHeaderView = searchController.searchBar
		var backgroundView = UIView(frame: view.bounds)
		backgroundView.backgroundColor = UIColor.clearColor()
		artistsTable.backgroundView = backgroundView
	}
}

// MARK: - UITableViewDataSource
extension ArtistsPicker: UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if searchController.active {
			return 1
		}
		return keys.count
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return keys[section]
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if searchController.active {
			return filteredArtists.count
		}
		return artists[keys[section]] == nil ? 0 : artists[keys[section]]!.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell:UITableViewCell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! UITableViewCell
		let section = keys[indexPath.section]
		
		if searchController.active {
			cell.textLabel?.text = filteredArtists[indexPath.row]
		} else {
			cell.textLabel?.text = artists[section]![indexPath.row]
		}
		
		cell.accessoryType = .None
		
		if searchController.active {
			if hasSelectedAll || filteredCheckedStates[indexPath.row] == true {
				cell.accessoryType = .Checkmark
			}
		} else {
			if hasSelectedAll || checkedStates[indexPath.section]?[indexPath.row] == true {
				cell.accessoryType = .Checkmark
			}
		}
		return cell
	}
	
	func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
		if searchController.active {
			return nil
		}
		return keys
	}
}

// MARK: - UITableViewDelegate
extension ArtistsPicker: UITableViewDelegate {
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		var headerView = UIView(frame: CGRectMake(0, 0, view.bounds.size.width, 30.0))
		headerView.backgroundColor = UIColor(patternImage: UIImage(named: "navBar.png")!)
		let lbl = UILabel(frame: CGRectMake(15, 1, 150, 20))
		lbl.font = UIFont(name: lbl.font.fontName, size: 16)
		lbl.textColor = UIColor(red: 0, green: 242/255, blue: 192/255, alpha: 1.0)
		headerView.addSubview(lbl)
		lbl.text = keys[section]
		if searchController.active {
			lbl.text = "Results (\(filteredArtists.count))"
		}
		return headerView
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if searchController.active {
			filteredCheckedStates[indexPath.row] = !filteredCheckedStates[indexPath.row]
			tableViewCellComponent(filteredArtists[indexPath.row], set: true)
		} else {
			checkedStates[indexPath.section]![indexPath.row]! = !checkedStates[indexPath.section]![indexPath.row]!
		}
		artistsTable.reloadData()
	}
}

// MARK: - UISearchControllerDelegate
extension ArtistsPicker: UISearchControllerDelegate {
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text)
		artistsTable.reloadData()
	}
}

// MARK: - UISearchResultsUpdating
extension ArtistsPicker: UISearchResultsUpdating {
	
}

// MARK: - String
extension String {
	func stringByAddingPercentEncodingForURLQueryValue() -> String? {
		let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
		characterSet.addCharactersInString("-._~")
		return stringByAddingPercentEncodingWithAllowedCharacters(characterSet)?.stringByReplacingOccurrencesOfString(" ", withString: "+")
	}
}
