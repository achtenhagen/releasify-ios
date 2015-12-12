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
	var filteredData: [Artist]!
	var selectedArtist: Artist?
	
	@IBOutlet weak var subscriptionsTable: UITableView!
	@IBOutlet weak var searchBar: UISearchBar!
	
	@IBAction func unwindToSubscriptions (sender: UIStoryboardSegue) {
		AppDB.sharedInstance.getArtists()
		reloadSubscriptions()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadSubscriptions", name: "refreshSubscriptions", object: nil)
		setupSearchBar()
		filteredData = AppDB.sharedInstance.artists
		
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 0.5)
		subscriptionsTable.addSubview(refreshControl)

		AppDB.sharedInstance.getArtists()
		subscriptionsTable.reloadData()
	}
	
	override func viewWillAppear(animated: Bool) {
		reloadSubscriptions()
		subscriptionsTable.scrollsToTop = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		subscriptionsTable.scrollsToTop = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func setupSearchBar () {
		searchBar.delegate = self
		searchBar.searchBarStyle = .Default
		searchBar.barStyle = .Black
		searchBar.barTintColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
		searchBar.tintColor = UIColor(red: 1, green: 0, blue: 162/255, alpha: 1.0)
		searchBar.layer.borderColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1).CGColor
		searchBar.layer.borderWidth = 1
		searchBar.translucent = false
		searchBar.autocapitalizationType = .Words
		searchBar.keyboardAppearance = .Dark
		searchBar.sizeToFit()
	}
	
	func reloadSubscriptions() {
		filteredData = AppDB.sharedInstance.artists
		subscriptionsTable.reloadData()
	}
	
	// MARK: - Refresh content
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
	
	// MARK: - Error message handler
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
		selectedArtist = AppDB.sharedInstance.artists[indexPath.row]
		performSegueWithIdentifier("SubscriptionDetailSegue", sender: self)
	}
}

// MARK: - UISearchBarDelegate
extension SubscriptionController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchBar.showsCancelButton = true
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({(artist: Artist) -> Bool in
			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
		})
		subscriptionsTable.reloadData()
	}
	
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		reloadSubscriptions()
		searchBar.text = ""
		searchBar.resignFirstResponder()
		searchBar.showsCancelButton = false
	}
}
