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
	var notificationBarItem: UIBarButtonItem?
	var addBarItem: UIBarButtonItem?
	var refreshControl: UIRefreshControl!
	var searchController: UISearchController!
	var filteredData: [Artist]!
	var selectedArtist: Artist?
	var footerLabel: UILabel!
	
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
		searchController.dimsBackgroundDuringPresentation = true
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
		self.definesPresentationContext = true
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadSubscriptions", name: "refreshSubscriptions", object: nil)
		notificationBarItem = self.navigationController?.navigationBar.items![0].leftBarButtonItem
		addBarItem = self.navigationController?.navigationBar.items![0].rightBarButtonItem
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		subscriptionsTable.setContentOffset(CGPoint(x: 0, y: 44), animated: true)
		subscriptionsTable.addSubview(refreshControl)
	}
	
	override func viewDidAppear(animated: Bool) {
		reloadSubscriptions()
	}
	
	override func viewWillAppear(animated: Bool) {
		subscriptionsTable.scrollsToTop = true
		notificationBarItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
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
			self.notificationBarItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
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
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		if footerLabel != nil && subscriptionsTable.contentOffset.y >= (subscriptionsTable.contentSize.height - subscriptionsTable.bounds.size.height) {
			footerLabel.fadeIn()
		} else if footerLabel != nil && footerLabel.alpha == 1.0 {
			footerLabel.fadeOut()
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
		self.performSegueWithIdentifier("SubscriptionDetailSegue", sender: self)
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
		let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 40))
		footerView.backgroundColor = UIColor.clearColor()
		if filteredData.count > 0 {
			footerLabel = UILabel()
			footerLabel.alpha = 0
			footerLabel.font = UIFont(name: footerLabel.font.fontName, size: 14)
			footerLabel.textColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.2)
			footerLabel.text = filteredData.count == 1 ? "\(filteredData.count) Artist" : "\(filteredData.count) Artists"
			footerLabel.textAlignment = NSTextAlignment.Center
			footerLabel.adjustsFontSizeToFitWidth = true
			footerLabel.sizeToFit()
			footerLabel.center = CGPoint(x: self.view.frame.size.width / 2, y: (footerView.frame.size.height / 2) - 7)
			footerView.addSubview(footerLabel)
		}
		return footerView
	}
}

// MARK: - UISearchBarDelegate
extension SubscriptionController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchController.searchBar.backgroundColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1.0)
		notificationBarItem?.enabled = false
		addBarItem?.enabled = false
	}
	
	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
		searchController.searchBar.backgroundColor = UIColor.clearColor()
		notificationBarItem?.enabled = UIApplication.sharedApplication().scheduledLocalNotifications!.count > 0 ? true : false
		addBarItem?.enabled = true
	}
}

// MARK: - UISearchResultsUpdating
extension SubscriptionController: UISearchResultsUpdating {
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
		subscriptionsTable.reloadData()
	}
}

// Mark: - UIView extension
extension UIView {
	func fadeIn (duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0.0, completion: (Bool) -> Void = { (finished: Bool) -> Void in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 1.0 }, completion: completion)
	}
	
	func fadeOut (duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0.0, completion: (Bool) -> Void = { (finished: Bool) -> Void in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 0.0 }, completion: completion)
	}
}
