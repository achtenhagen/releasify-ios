//
//  ArtistPicker.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistsPicker: UIViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let blacklist: NSArray = ["Various Artists", "Verschiedene Interpreten"]
	var keys: NSMutableArray = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"]
	var artists = [String: [String]]()
	var checkedStates = [String: [Int: Bool]]()
	var filteredArtists = [String]()
	var filteredCheckedStates = [Bool]()
	var hasSelectedAll = false
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
			for (key, values) in checkedStates {
				for (section, state) in values {
					checkedStates[key]?.updateValue(false, forKey: section)
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
		for artist in collection {
			let representativeItem: MPMediaItem = artist.representativeItem
			let artistName = (representativeItem.valueForProperty(MPMediaItemPropertyAlbumArtist) as AnyObject) as! String
			if artistName != previousArtist && !blacklist.containsObject(artistName) {
				let currentSection = getSectionForArtistName(artistName)
				if artists[currentSection.section] == nil {
					artists[currentSection.section] = [String]()
				}
				if checkedStates[currentSection.section] == nil {
					checkedStates[currentSection.section] = [Int: Bool]()
				}
				checkedStates[currentSection.section]?[artists[currentSection.section]!.count] = false
				artists[currentSection.section]?.append(artistName)
				previousArtist = artistName
			}
		}
		
		if artists.count < keys.count {
			for (index, section) in enumerate(keys) {
				if artists.indexForKey(section as! String) == nil {
					println("Empty section found: \(section)")
					keys.removeObject(section)
				}
			}
		}
		
		setupSearchController()
		
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
		for (section, values) in checkedStates {
			for (artist, state) in values {
				checkedStates[section]?.updateValue(false, forKey: artist)
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
		
		for (section, values) in checkedStates {
			for (index, state) in values {
				if state == true || hasSelectedAll {
					totalItems++
					var artist = artists[section]![index]
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
		indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
		indicatorView.center = view.center
		view.addSubview(activityView)
		view.addSubview(indicatorView)
		indicatorView.startAnimating()
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		
		var batchesProcessed = 0
		for batch in batches {
			let apiUrl = NSURL(string: APIURL.submitArtist.rawValue)
			API.sharedInstance.sendRequest(APIURL.submitArtist.rawValue, postString: batch, successHandler: { (response, data) in
				if let HTTPResponse = response as? NSHTTPURLResponse {
					println("HTTP status code: \(HTTPResponse.statusCode)")
					if HTTPResponse.statusCode == 202 {
						if let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: nil) as? NSDictionary {
							if let awaitingArtists: [NSDictionary] = json["pending"] as? [NSDictionary] {
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
								self.progressBar.hidden = true
								self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
							} else {
								self.dismissViewControllerAnimated(true, completion: nil)
							}
						}
					} else {
						self.activityView.removeFromSuperview()
						self.indicatorView.removeFromSuperview()
					}
				}
				},
				errorHandler: { (error) in
					self.progressBar.progressTintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
					self.activityView.removeFromSuperview()
					self.indicatorView.removeFromSuperview()
					var alert = UIAlertController(title: "Network Error", message: error.localizedDescription, preferredStyle: .Alert)
					alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
					self.presentViewController(alert, animated: true, completion: nil)
			})
		}
	}
	
	// MARK: - Helper function to get the section a given artist is contained in.
	func getSectionForArtistName (artistName: String) -> (index: Int, section: String) {
		for (index, value) in enumerate(keys) {
			if artistName.uppercaseString.hasPrefix(value as! String) || index == keys.count - 1 {
				return (index, value as! String)
			}
		}
		return (0, keys[0] as! String)
	}
	
	func tableViewCellComponent (filteredCell: String, set: Bool) -> Bool {
		let currentSection = getSectionForArtistName(filteredCell)
		for (key, value) in enumerate(artists[currentSection.section]!) {
			if artists[currentSection.section]![key] == filteredCell {
				if set {
					checkedStates[currentSection.section]![key]! = !checkedStates[currentSection.section]![key]!
					return true
				}
				return checkedStates[currentSection.section]![key]!
			}
		}
		return false
	}
	
	func filterContentForSearchText(searchText: String) {
		filteredArtists.removeAll(keepCapacity: true)
		filteredCheckedStates.removeAll(keepCapacity: true)
		if !searchText.isEmpty {
			let filter: String -> Bool = { artist in
				let range = artist.rangeOfString(searchText, options: .CaseInsensitiveSearch)
				return range != nil
			}
			for key in keys {
				if artists[key as! String] == nil {
					artists[key as! String] = [String]()
				}
				let namesForKey = artists[key as! String]!, matches = namesForKey.filter(filter)
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
		return keys[section] as? String
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if searchController.active {
			return filteredArtists.count
		}
		return artists[keys[section] as! String] == nil ? 0 : artists[keys[section] as! String]!.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! UITableViewCell
		let section = keys[indexPath.section] as! String
		
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
			if hasSelectedAll || checkedStates[section]?[indexPath.row]! == true {
				cell.accessoryType = .Checkmark
			}
		}
		return cell
	}
	
	func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
		if searchController.active {
			return nil
		}
		return keys as [AnyObject]
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
		lbl.text = keys[section] as? String
		if searchController.active {
			lbl.text = "Results (\(filteredArtists.count))"
		}
		return headerView
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let section = keys[indexPath.section] as! String
		if searchController.active {
			filteredCheckedStates[indexPath.row] = !filteredCheckedStates[indexPath.row]
			tableViewCellComponent(filteredArtists[indexPath.row], set: true)
		} else {
			checkedStates[section]![indexPath.row]! = !checkedStates[section]![indexPath.row]!
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
