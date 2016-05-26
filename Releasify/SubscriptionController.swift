//
//  SubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionController: UITableViewController {
	
	private var theme: SubscriptionControllerTheme!
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var searchController: UISearchController!
	var artists: [Artist]!
	var filteredArtists: [Artist]!
	var selectedArtist: Artist?
	
	@IBOutlet var subscriptionsTable: UITableView!
	
	@IBAction func unwindToSubscriptions(sender: UIStoryboardSegue) {
		AppDB.sharedInstance.getArtists()
		reloadSubscriptions()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		theme = SubscriptionControllerTheme(style: appDelegate.theme.style)
		artists = AppDB.sharedInstance.artists
		filteredArtists = [Artist]()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(SubscriptionController.reloadSubscriptions), name: "refreshSubscriptions", object: nil)
		
		// Table view customizations
		subscriptionsTable.backgroundColor = theme.tableViewBackgroundColor
		subscriptionsTable.backgroundView = UIView(frame: self.subscriptionsTable.bounds)
		subscriptionsTable.backgroundView?.userInteractionEnabled = false
		subscriptionsTable.separatorColor = theme.cellSeparatorColor
		
		// Search controller customizations
		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.placeholder = "Search Artists"
		searchController.searchBar.searchBarStyle = .Minimal
		searchController.searchBar.barStyle = theme.searchBarStyle
		searchController.searchBar.barTintColor = UIColor.clearColor()
		searchController.searchBar.tintColor = theme.searchBarTintColor
		searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchController.searchBar.layer.borderWidth = 1
		searchController.searchBar.translucent = false
		searchController.searchBar.autocapitalizationType = .Words
		searchController.searchBar.keyboardAppearance = theme.keyboardStyle
		searchController.searchBar.sizeToFit()
		subscriptionsTable.tableHeaderView = searchController.searchBar
		definesPresentationContext = true
	}
	
	override func viewDidAppear(animated: Bool) {
		reloadSubscriptions()
	}
	
	override func viewWillAppear(animated: Bool) {
		let indexPath = self.subscriptionsTable.indexPathForSelectedRow
		if indexPath != nil {
			subscriptionsTable.deselectRowAtIndexPath(indexPath!, animated: true)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		searchController.active = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func reloadSubscriptions() {
		artists = AppDB.sharedInstance.artists
		filteredArtists = [Artist]()
		subscriptionsTable.reloadData()
	}
	
	// MARK: - Handle error messages
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = title
			alert.message = message
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// MARK: - Search function for UISearchResultsUpdating
	func filterContentForSearchText(searchText: String) {
		filteredArtists.removeAll(keepCapacity: true)
		if !searchText.isEmpty {
			filteredArtists = AppDB.sharedInstance.artists.filter({ (artist: Artist) -> Bool in
				return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
			})
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "SubscriptionDetailSegue" {
			let detailController = segue.destinationViewController as! SubscriptionDetailController
			detailController.artist = selectedArtist
		}
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return searchController.active ? filteredArtists.count : artists.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("subscriptionCell", forIndexPath: indexPath) as! SubscriptionCell
		if searchController.active {
			cell.subscriptionImage.image = UIImage(named: filteredArtists[indexPath.row].avatar!)
			cell.subscriptionTitle.text = filteredArtists[indexPath.row].title
		} else {
			cell.subscriptionImage.image = UIImage(named: artists[indexPath.row].avatar!)
			cell.subscriptionTitle.text = artists[indexPath.row].title
		}
		cell.subscriptionTitle.textColor = theme.subscriptionTitleColor
		cell.borderColor = theme.cellBorderColor
		let bgColorView = UIView()
		bgColorView.backgroundColor = theme.cellHighlightColor
		cell.selectedBackgroundView = bgColorView
		cell.setNeedsLayout()
		cell.layoutIfNeeded()
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if searchController.active {
			selectedArtist = filteredArtists[indexPath.row]
		} else {
			selectedArtist = artists[indexPath.row]
		}
		self.performSegueWithIdentifier("SubscriptionDetailSegue", sender: self)
	}
	
	override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
		return action == #selector(NSObject.copy(_:))
	}
	
	override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
		let cell = tableView.cellForRowAtIndexPath(indexPath) as! SubscriptionCell
		UIPasteboard.generalPasteboard().string = cell.subscriptionTitle!.text
	}
}

// MARK: - UISearchControllerDelegate
extension SubscriptionController: UISearchControllerDelegate {
	func willPresentSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = theme.navBarTintColor
	}
	
	func willDismissSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = UIColor.clearColor()
	}
}

// MARK: - UISearchResultsUpdating
extension SubscriptionController: UISearchResultsUpdating {
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
		subscriptionsTable.reloadData()
	}
}

// MARK: - Theme Extension
private class SubscriptionControllerTheme: Theme {
	var subscriptionTitleColor: UIColor!
	var cellBorderColor: UIColor!
	
	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			subscriptionTitleColor = UIColor.whiteColor()
			cellBorderColor = UIColor.whiteColor()
		case .Light:
			subscriptionTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			cellBorderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
		}
	}
}
