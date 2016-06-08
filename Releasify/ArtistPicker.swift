//
//  ArtistPicker.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistPicker: UIViewController {

	private var theme: ArtistPickerTheme!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let blacklist: NSArray = ["Various Artists", "Verschiedene Interpreten"]
	let keys: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"]
	var sections: [String]!
	var artists = [String: [String]]()
	var checkedStates = [String: [Int: Bool]]()
	var filteredArtists = [String]()
	var filteredCheckedStates = [Bool]()
	var hasSelectedAll = false
	var isIntro = false
	var searchController: UISearchController!
	var collection = [AnyObject]()
	var successArtists = 0
	var responseArtists = [NSDictionary]()
	var activityView: UIView!
	var indicatorView: UIActivityIndicatorView!
	
	@IBOutlet weak var navBar: UINavigationBar!
	@IBOutlet weak var artistsTable: UITableView!
	@IBOutlet weak var selectAllBtn: UIBarButtonItem!
	@IBOutlet weak var progressBar: UIProgressView!
	
	@IBAction func selectAllArtists(sender: UIBarButtonItem) {
		hasSelectedAll = !hasSelectedAll
		if hasSelectedAll {
			selectAllBtn.title = NSLocalizedString("Deselect All", comment: "")
		} else {
			filteredCheckedStates.removeAll(keepCapacity: true)
			for (key, values) in checkedStates {
				for (section, _) in values {
					checkedStates[key]?.updateValue(false, forKey: section)
				}
			}
			selectAllBtn.title = NSLocalizedString("Select All", comment: "")
		}
		artistsTable.reloadData()
	}
	
	@IBAction func closeArtistPicker(sender: UIBarButtonItem) {
		if searchController.active {
			searchController.dismissViewControllerAnimated(true, completion: nil)
		}
		handleBatchProcessing()
		if isIntro {
			NSNotificationCenter.defaultCenter().postNotificationName("finishIntroStep", object: nil, userInfo: nil)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		theme = ArtistPickerTheme(style: appDelegate.theme.style)

		// Theme customizations
		artistsTable.tintColor = theme.globalTintColor
		progressBar.trackTintColor = theme.progressBarBackTintColor
		
		var previousArtist = ""
		for artist in collection {
			let artistName = (artist.representativeItem!!.valueForProperty(MPMediaItemPropertyAlbumArtist)) as! String
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
		
		sections = [String]()
		for (_, section) in keys.enumerate() {
			if artists[section] != nil {
				sections.append(section)
			}
		}

		// Table view customization
		self.artistsTable.backgroundColor = theme.artistsTableViewBackgroundColor
		self.artistsTable.separatorColor = theme.cellSeparatorColor
		self.artistsTable.sectionIndexColor = theme.tableViewSectionIndexColor
		setupSearchController()
	}
	
	override func viewDidDisappear(animated: Bool) {
		hasSelectedAll = false
		responseArtists.removeAll(keepCapacity: true)
		filteredArtists.removeAll(keepCapacity: true)
		filteredCheckedStates.removeAll(keepCapacity: true)
		for (section, values) in checkedStates {
			for (artist, _) in values {
				checkedStates[section]?.updateValue(false, forKey: artist)
			}
		}
		artistsTable.reloadData()
		if activityView != nil {
			activityView.removeFromSuperview()
			indicatorView.removeFromSuperview()
		}
		selectAllBtn.title = NSLocalizedString("Select All", comment: "")
		progressBar.setProgress(0, animated: false)
		self.view.userInteractionEnabled = true
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	// MARK: - Handle artist batch processing
	func handleBatchProcessing () {
		let batchSize = 20
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)"
		var batches = [String]()
		var uniqueIDs = [Int]()
		var totalItems = 0
		var batchCount = 0
		var currentBatch = String()
		for (section, values) in checkedStates {
			for (index, state) in values {
				if state == true || hasSelectedAll {
					totalItems += 1
					var artist = artists[section]![index]
					artist = artist.stringByAddingPercentEncodingForURLQueryValue()!
					currentBatch = currentBatch.stringByAppendingString("&title[]=\(artist)")
					batchCount += 1
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
		self.view.userInteractionEnabled = false
		setupActivityView()
		indicatorView.startAnimating()
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		
		// Process each batch
		var batchesProcessed = 0
		for batch in batches {
			API.sharedInstance.sendRequest(API.Endpoint.submitArtist.url(), postString: batch, successHandler: { (statusCode, data) in
				if statusCode == 202 {
					if let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as? NSDictionary {
						if let successArtists = json["success"] as? [NSDictionary] {
							self.successArtists += successArtists.count
						}
						if let awaitingArtists = json["pending"] as? [NSDictionary] {
							for artist in awaitingArtists {
								if let uniqueID = artist["iTunesUniqueID"] as? Int {
									if !uniqueIDs.contains(uniqueID) && AppDB.sharedInstance.getArtistByUniqueID(uniqueID) == 0 {
										uniqueIDs.append(uniqueID)
										self.responseArtists.append(artist)
									}
								}
							}
						}
						if let failedArtists = json["failed"] as? [NSDictionary] {
							for artist in failedArtists {
								let title = (artist["title"] as? String)!
								if self.appDelegate.debug { print("Artist \(title) was not found on iTunes.") }
							}
						}
					}
					batchesProcessed += 1
					if self.appDelegate.debug { print("Processed batches: \(batchesProcessed)") }
					let batchProgress = Float(Double(batchesProcessed) / Double(batches.count))
					self.progressBar.setProgress(batchProgress, animated: true)
					if batchesProcessed == batches.count {
						if self.appDelegate.debug { print("Completed batch processing.") }
						self.progressBar.setProgress(1.0, animated: true)
						UIApplication.sharedApplication().networkActivityIndicatorVisible = false
						if self.responseArtists.count > 0 {
							self.progressBar.hidden = true
							self.performSegueWithIdentifier("ArtistSelectionSegue", sender: self)
						} else {
							if self.successArtists > 0 {								
								NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
							}
							self.dismissViewControllerAnimated(true, completion: nil)
						}
					}
				}
				},
				errorHandler: { (error) in
					self.progressBar.progressTintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
					self.activityView.removeFromSuperview()
					self.indicatorView.removeFromSuperview()
					let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
					switch (error) {
					case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
						alert.title = NSLocalizedString("You're Offline!", comment: "")
						alert.message = NSLocalizedString("Please make sure you are connected to the internet, then try again.", comment: "")
						let alertActionTitle = NSLocalizedString("ALERT_ACTION_SETTINGS", comment: "The title for the alert controller action")
						alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { action in
							UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
							if self.searchController.active {
								self.searchController.dismissViewControllerAnimated(true, completion: nil)
							}
							self.dismissViewControllerAnimated(true, completion: nil)
						}))
					case API.Error.ServerDownForMaintenance:
						alert.title = NSLocalizedString("Service Unavailable", comment: "")
						alert.message = NSLocalizedString("We'll be back shortly, our servers are currently undergoing maintenance.", comment: "")
					default:
						alert.title = NSLocalizedString("Unable to import!", comment: "")
						alert.message = NSLocalizedString("Please try again later.", comment: "")
					}
					let title = NSLocalizedString("OK", comment: "")
					alert.addAction(UIAlertAction(title: title, style: .Default, handler: { action in
						if self.searchController.active {
							self.searchController.dismissViewControllerAnimated(true, completion: nil)
						}
						self.dismissViewControllerAnimated(true, completion: nil)
					}))
					self.presentViewController(alert, animated: true, completion: nil)
			})
		}
	}
	
	// MARK: - Initialize activity view
	func setupActivityView () {
		activityView = UIView(frame: CGRectMake(0, 0, 90, 90))
		activityView.center = view.center
		activityView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
		activityView.layer.cornerRadius = 14
		activityView.layer.masksToBounds = true
		activityView.userInteractionEnabled = false
		indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
		indicatorView.center = view.center
		self.view.addSubview(activityView)
		self.view.addSubview(indicatorView)
	}
	
	// MARK: - Get section containing a given artist
	func getSectionForArtistName (artistName: String) -> (index: Int, section: String) {
		for (index, value) in keys.enumerate() {
			if artistName.uppercaseString.hasPrefix(value) || index == keys.count - 1 {
				return (index, value)
			}
		}
		return (0, keys[0])
	}
	
	// MARK: - Set the state of all elements in given section
	func tableViewCellComponent (filteredCell: String, set: Bool) -> Bool {
		let currentSection = getSectionForArtistName(filteredCell)
		for (key, _) in (artists[currentSection.section]!).enumerate() {
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
	
	// MARK: - Search function for table view
	func filterContentForSearchText(searchText: String) {
		filteredArtists.removeAll(keepCapacity: true)
		filteredCheckedStates.removeAll(keepCapacity: true)
		if !searchText.isEmpty {
			let filter: String -> Bool = { (artist) in
				let range = artist.rangeOfString(searchText, options: .CaseInsensitiveSearch)
				return range != nil
			}
			for key in sections {
				if artists[key] == nil {
					artists[key] = [String]()
				}
				let namesForKey = artists[key]!, matches = namesForKey.filter(filter)
				filteredArtists += matches
			}
		}
		for i in 0..<filteredArtists.count {
			filteredCheckedStates.append(tableViewCellComponent(filteredArtists[i], set: false))
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ArtistSelectionSegue" {
			let selectionController = segue.destinationViewController as! SearchResultsNavController
			selectionController.artists = responseArtists
		}
	}
	
	// MARK: - Initialize search controller
	func setupSearchController () {
		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self	
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.placeholder = NSLocalizedString("Search Artists", comment: "")
		searchController.searchBar.searchBarStyle = .Minimal
		searchController.searchBar.barStyle = theme.searchBarStyle
		searchController.searchBar.barTintColor = UIColor.clearColor()
		searchController.searchBar.tintColor = theme.searchBarTintColor
		searchController.searchBar.backgroundColor = theme.searchBarBackgroundColor
		searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchController.searchBar.layer.borderWidth = 1
		searchController.searchBar.translucent = false
		searchController.searchBar.autocapitalizationType = .Words
		searchController.searchBar.keyboardAppearance = theme.keyboardStyle
		searchController.searchBar.sizeToFit()
		artistsTable.tableHeaderView = searchController.searchBar
		let backgroundView = UIView(frame: view.bounds)
		backgroundView.backgroundColor = UIColor.clearColor()
		artistsTable.backgroundView = backgroundView
		definesPresentationContext = true
		if #available(iOS 9.0, *) {
			self.searchController.loadViewIfNeeded()
		} else {
			let _ = self.searchController.view
		}
	}
}

// MARK: - UITableViewDataSource
extension ArtistPicker: UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return searchController.active ? 1 : sections.count
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section]
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return searchController.active ? filteredArtists.count : artists[sections[section]]!.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as UITableViewCell!
		let section = sections[indexPath.section]
		cell.textLabel?.text = searchController.active ? filteredArtists[indexPath.row] : artists[section]![indexPath.row]
		cell.textLabel?.textColor = theme.cellTextColor
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
	
	func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
		return !searchController.active ? sections : nil
	}
}

// MARK: - UITableViewDelegate
extension ArtistPicker: UITableViewDelegate {
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView(frame: CGRectMake(0, 0, view.bounds.size.width, 30.0))
		headerView.backgroundColor = theme.sectionHeaderBackgroundColor
		let lbl = UILabel(frame: CGRectMake(15, 1, 150, 20))
		lbl.font = UIFont(name: lbl.font.fontName, size: 16)
		lbl.textColor = theme.sectionHeaderTextColor
		headerView.addSubview(lbl)
		lbl.text = sections[section]
		let title = NSLocalizedString("Results", comment: "")
		if searchController.active { lbl.text = "\(title) (\(filteredArtists.count))" }
		return headerView
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let section = sections[indexPath.section]
		if searchController.active {
			filteredCheckedStates[indexPath.row] = !filteredCheckedStates[indexPath.row]
			tableViewCellComponent(filteredArtists[indexPath.row], set: true)
		} else {
			checkedStates[section]![indexPath.row]! = !checkedStates[section]![indexPath.row]!
		}
		artistsTable.reloadData()
	}
}

// MARK: - UISearchResultsUpdating
extension ArtistPicker: UISearchResultsUpdating {
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
		artistsTable.reloadData()
	}
}

// MARK: - Theme Extension
private class ArtistPickerTheme: Theme {
	var artistsTableViewBackgroundColor: UIColor!
	var tableViewSectionIndexColor: UIColor!
	var cellTextColor: UIColor!
	var progressBarBackTintColor: UIColor!

	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			artistsTableViewBackgroundColor = UIColor(red: 1/255, green: 27/255, blue: 38/255, alpha: 1)
			tableViewSectionIndexColor = UIColor(red: 0, green: 242/255, blue: 192/255, alpha: 1)
			cellTextColor = blueColor
			progressBarBackTintColor = UIColor(red: 0, green: 52/255, blue: 72/255, alpha: 1)
		case .Light:
			artistsTableViewBackgroundColor = UIColor.whiteColor()
			tableViewSectionIndexColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			cellTextColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			progressBarBackTintColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
		}
	}
}

// MARK: - String extension
extension String {
	func stringByAddingPercentEncodingForURLQueryValue() -> String? {
		let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
		characterSet.addCharactersInString("-._~")
		return stringByAddingPercentEncodingWithAllowedCharacters(characterSet)?.stringByReplacingOccurrencesOfString(" ", withString: "+")
	}
}
