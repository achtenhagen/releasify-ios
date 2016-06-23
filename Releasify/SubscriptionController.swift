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
	private var appEmptyStateView: UIView!
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
		subscriptionsTable.backgroundView = UIView(frame: subscriptionsTable.bounds)
		subscriptionsTable.backgroundView?.userInteractionEnabled = false
		subscriptionsTable.separatorColor = theme.cellSeparatorColor
		
		// Search controller customizations
		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.placeholder = NSLocalizedString("Search Artists", comment: "")
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
		let indexPath = subscriptionsTable.indexPathForSelectedRow
		if indexPath != nil {
			subscriptionsTable.deselectRowAtIndexPath(indexPath!, animated: true)
		}
		if AppDB.sharedInstance.artists.count == 0 {
			showAppEmptyState()
		} else {
			hideAppEmptyState()
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		searchController.active = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func reloadSubscriptions() {
		filteredArtists = [Artist]()
		artists = AppDB.sharedInstance.artists
		subscriptionsTable.reloadData()
	}

	// Show App empty state
	func showAppEmptyState() {
		if appEmptyStateView == nil {
			let title = NSLocalizedString("No Subscriptions", comment: "")
			let subtitle = NSLocalizedString("Your subscriptions will appear here", comment: "")
			let stateImg = theme.style == .Dark ? "app_empty_state_artists_dark" : "app_empty_state_artists"
			let appEmptyState = AppEmptyState(style: theme.style, refView: self.view, imageName: stateImg, title: title,
			                                  subtitle: subtitle, buttonTitle: nil, offset: searchController.searchBar.frame.height)
			appEmptyStateView = appEmptyState.view()
			subscriptionsTable.tableFooterView = UIView()
			self.view.addSubview(appEmptyStateView)
		}
	}

	// Hide App empty state
	func hideAppEmptyState() {
		if appEmptyStateView != nil {
			appEmptyStateView.removeFromSuperview()
			appEmptyStateView = nil
			subscriptionsTable.tableFooterView = nil
		}
	}
	
	// Handle error messages
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = NSLocalizedString("You're Offline!", comment: "")
			alert.message = NSLocalizedString("Please make sure you are connected to the internet, then try again.", comment: "")
			let alertActionTitle = NSLocalizedString("Settings", comment: "")
			alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		case API.Error.ServerDownForMaintenance:
			alert.title = NSLocalizedString("Service Unavailable", comment: "")
			alert.message = NSLocalizedString("We'll be back shortly, our servers are currently undergoing maintenance.", comment: "")
		default:
			alert.title = title
			alert.message = message
		}
		let title = NSLocalizedString("OK", comment: "")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// Search function for UISearchResultsUpdating
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
		searchController.searchBar.backgroundColor = theme.searchBarBackgroundColor
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

// Theme Subclass
private class SubscriptionControllerTheme: Theme {
	var subscriptionTitleColor: UIColor!
	
	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			subscriptionTitleColor = UIColor.whiteColor()
		case .Light:
			subscriptionTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)			
		}
	}
}
