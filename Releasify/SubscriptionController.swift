//
//  SubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionController: UITableViewController {
	
	private let theme = SubscriptionControllerTheme()
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var searchController: UISearchController!
	var filteredData: [Artist]!
	var selectedArtist: Artist?
	
	@IBOutlet var subscriptionsTable: UITableView!
	
	@IBAction func unwindToSubscriptions(sender: UIStoryboardSegue) {
		AppDB.sharedInstance.getArtists()
		reloadSubscriptions()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		filteredData = AppDB.sharedInstance.artists
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadSubscriptions", name: "refreshSubscriptions", object: nil)
		
		theme.style = Theme.sharedInstance.style
		theme.set()
		
		self.subscriptionsTable.backgroundColor = theme.subscriptionsTableBackgroundColor
		self.subscriptionsTable.backgroundView = UIView(frame: self.subscriptionsTable.bounds)
		self.subscriptionsTable.backgroundView?.userInteractionEnabled = false
		
		refreshControl = UIRefreshControl()
		refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl!.tintColor = Theme.sharedInstance.refreshControlTintColor
		self.subscriptionsTable.setContentOffset(CGPoint(x: 0, y: 44), animated: true)
		self.subscriptionsTable.addSubview(refreshControl!)
		
		searchController = UISearchController(searchResultsController: nil)
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.placeholder = "Search Artists"
		searchController.searchBar.searchBarStyle = .Minimal
		searchController.searchBar.barStyle = .Black
		searchController.searchBar.barTintColor = UIColor.clearColor()
		searchController.searchBar.tintColor = theme.searchBarTintColor
		searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchController.searchBar.layer.borderWidth = 1
		searchController.searchBar.translucent = false
		searchController.searchBar.autocapitalizationType = .Words
		searchController.searchBar.keyboardAppearance = theme.keyboardStyle
		searchController.searchBar.sizeToFit()
		self.subscriptionsTable.tableHeaderView = searchController.searchBar
		definesPresentationContext = true
		
		self.subscriptionsTable.separatorColor = theme.cellSeparatorColor
	}
	
	override func viewDidAppear(animated: Bool) {
		reloadSubscriptions()
	}
	
	override func viewWillAppear(animated: Bool) {
		let indexPath = self.subscriptionsTable.indexPathForSelectedRow
		if indexPath != nil {
			self.subscriptionsTable.deselectRowAtIndexPath(indexPath!, animated: true)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		searchController.active = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func reloadSubscriptions() {
		filteredData = AppDB.sharedInstance.artists
		subscriptionsTable.reloadData()
	}
	
	// MARK: - Handle refresh content
	func refresh() {
		API.sharedInstance.refreshContent({ newItems in
			self.reloadSubscriptions()
			self.refreshControl!.endRefreshing()
			},
			errorHandler: { (error) in
				self.refreshControl!.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)
		})
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
		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({ (artist: Artist) -> Bool in
			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
		})
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "SubscriptionDetailSegue" {
			let detailController = segue.destinationViewController as! SubscriptionDetailController
			detailController.artist = selectedArtist
		}
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filteredData.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("subscriptionCell", forIndexPath: indexPath) as! SubscriptionCell
		cell.subscriptionImage.image = UIImage(named: filteredData[indexPath.row].avatar)
		cell.subscriptionTitle.text = filteredData[indexPath.row].title
		cell.subscriptionTitle.textColor = theme.subscriptionTitleColor
		let bgColorView = UIView()
		bgColorView.backgroundColor = theme.cellSeparatorColor
		cell.selectedBackgroundView = bgColorView
		cell.setNeedsLayout()
		cell.layoutIfNeeded()
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedArtist = filteredData[indexPath.row]
		searchController.active = false
		self.performSegueWithIdentifier("SubscriptionDetailSegue", sender: self)
	}
	
	override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
		return action == Selector("copy:")
	}
	
	override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
		let cell = tableView.cellForRowAtIndexPath(indexPath) as! SubscriptionCell
		UIPasteboard.generalPasteboard().string = cell.subscriptionTitle!.text
	}
}

// MARK: - UISearchControllerDelegate
extension SubscriptionController: UISearchControllerDelegate {
	func willPresentSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = Theme.sharedInstance.navBarTintColor
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
	var subscriptionsTableBackgroundColor: UIColor!
	var subscriptionTitleColor: UIColor!
	var cellHighlightColor: UIColor!
	var cellSeparatorColor: UIColor!
	
	override init () {
		switch Theme.sharedInstance.style {
		case .dark:
			subscriptionsTableBackgroundColor = UIColor.clearColor()
			subscriptionTitleColor = UIColor.whiteColor()
			cellHighlightColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
			cellSeparatorColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
		case .light:
			subscriptionTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			cellHighlightColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
			cellSeparatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
		}
	}
}
