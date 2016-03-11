//
//  AddSubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/26/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AddSubscriptionController: UITableViewController {
	
	var searchController: UISearchController!

	@IBOutlet var searchTable: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		self.searchController = UISearchController(searchResultsController: nil)
		self.searchController.delegate = self
		self.searchController.searchResultsUpdater = self
		self.searchController.dimsBackgroundDuringPresentation = false
		self.searchController.hidesNavigationBarDuringPresentation = false
		self.searchController.searchBar.placeholder = "Search artists & albums"
		self.searchController.searchBar.searchBarStyle = .Minimal
		self.searchController.searchBar.barStyle = Theme.sharedInstance.searchBarStyle
		self.searchController.searchBar.barTintColor = UIColor.clearColor()
		self.searchController.searchBar.tintColor = Theme.sharedInstance.searchBarTintColor
		self.searchController.searchBar.layer.borderColor = UIColor.clearColor().CGColor
		self.searchController.searchBar.layer.borderWidth = 1
		self.searchController.searchBar.translucent = false
		self.searchController.searchBar.autocapitalizationType = .Words
		self.searchController.searchBar.keyboardAppearance = Theme.sharedInstance.keyboardStyle
		self.searchController.searchBar.sizeToFit()
		self.searchTable.tableHeaderView = self.searchController.searchBar
		
		if #available(iOS 9.0, *) {
			self.searchController.loadViewIfNeeded()
		} else {
			let _ = self.searchController.view
		}
		
		definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Search function for UISearchResultsUpdating
	func filterContentForSearchText(searchText: String) {
//		filteredData = searchText.isEmpty ? AppDB.sharedInstance.artists : AppDB.sharedInstance.artists.filter({(artist: Artist) -> Bool in
//			return artist.title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
//		})
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
}

// MARK: - UISearchControllerDelegate
extension AddSubscriptionController: UISearchControllerDelegate {
	func willPresentSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = Theme.sharedInstance.navBarTintColor
	}
	
	func willDismissSearchController(searchController: UISearchController) {
		searchController.searchBar.backgroundColor = UIColor.clearColor()
	}
}

// MARK: - UISearchResultsUpdating
extension AddSubscriptionController: UISearchResultsUpdating {
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
		searchTable.reloadData()
	}
}
