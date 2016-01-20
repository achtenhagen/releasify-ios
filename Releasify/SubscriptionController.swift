//
//  SubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionController: UIViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var refreshControl: UIRefreshControl!
	var searchController: UISearchController!
	var filteredData: [Artist]!
	var selectedArtist: Artist?
	
	@IBOutlet weak var subscriptionsTable: UITableView!
	
	@IBAction func unwindToSubscriptions (sender: UIStoryboardSegue) {
		AppDB.sharedInstance.getArtists()
		reloadSubscriptions()
	}
	
	override func loadView() {
		super.loadView()
		filteredData = AppDB.sharedInstance.artists
		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.definesPresentationContext = true
		searchController.dimsBackgroundDuringPresentation = false
		searchController.searchBar.delegate = self
		searchController.searchBar.placeholder = "Search Artists"
		searchController.searchBar.searchBarStyle = .Minimal
		searchController.searchBar.barStyle = .Black
		searchController.searchBar.barTintColor = UIColor.clearColor()
		searchController.searchBar.tintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
		searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchController.searchBar.layer.borderWidth = 1
		searchController.searchBar.translucent = false
		searchController.searchBar.autocapitalizationType = .Words
		searchController.searchBar.keyboardAppearance = .Dark
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.searchBar.sizeToFit()
		subscriptionsTable.tableHeaderView = searchController.searchBar
		let backgroundView = UIView(frame: view.bounds)
		backgroundView.backgroundColor = UIColor.clearColor()
		subscriptionsTable.backgroundView = backgroundView
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadSubscriptions", name: "refreshSubscriptions", object: nil)
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		subscriptionsTable.setContentOffset(CGPoint(x: 0, y: 44), animated: true)
		subscriptionsTable.addSubview(refreshControl)
	}
	
	override func viewWillAppear(animated: Bool) {
		reloadSubscriptions()
		subscriptionsTable.scrollsToTop = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		subscriptionsTable.scrollsToTop = false
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
			self.refreshControl.endRefreshing()
			NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
			},
			errorHandler: { error in
				self.refreshControl.endRefreshing()
				self.handleError("Unable to update!", message: "Please try again later.", error: error)
		})
	}
	
	// MARK: - Handle error messages
	func handleError (title: String, message: String, error: ErrorType) {
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
		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({(artist: Artist) -> Bool in
			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
		})
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "SubscriptionDetailSegue" {
			let detailController = segue.destinationViewController as! SubscriptionDetailController
			detailController.artist = selectedArtist
		}
	}
}

// MARK: - UITableViewDataSource
extension SubscriptionController: UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filteredData.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = subscriptionsTable.dequeueReusableCellWithIdentifier("subscriptionCell", forIndexPath: indexPath) as! SubscriptionCell
		cell.subscriptionImage.image = UIImage(named: filteredData[indexPath.row].avatar)
		cell.subscriptionTitle.text = filteredData[indexPath.row].title
		let bgColorView = UIView()
		bgColorView.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.1)
		cell.selectedBackgroundView = bgColorView
		cell.setNeedsLayout()
		cell.layoutIfNeeded()
		return cell
	}
}

// MARK: - UITableViewDelegate
extension SubscriptionController: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedArtist = filteredData[indexPath.row]
		searchController.active = false
		performSegueWithIdentifier("SubscriptionDetailSegue", sender: self)
	}
	
	func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
		return action == Selector("copy:")
	}
	
	func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
		let cell = tableView.cellForRowAtIndexPath(indexPath) as! SubscriptionCell
		UIPasteboard.generalPasteboard().string = cell.subscriptionTitle!.text
	}
	
	func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 40))
		footerView.backgroundColor = UIColor.clearColor()
		let label = UILabel()
		label.font = UIFont(name: label.font.fontName, size: 14)
		label.textColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.2)
		label.text = "\(filteredData.count) Artists"
		label.textAlignment = NSTextAlignment.Center
		label.adjustsFontSizeToFitWidth = true
		label.sizeToFit()
		label.center = CGPoint(x: view.frame.size.width / 2, y: (footerView.frame.size.height / 2) - 7)
		footerView.addSubview(label)
		return footerView
	}
}

// MARK: - UISearchBarDelegate
extension SubscriptionController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchController.searchBar.backgroundColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1.0)
	}
	
	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
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
