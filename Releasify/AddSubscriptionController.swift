//
//  AddSubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/26/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AddSubscriptionController: UIViewController {
	
	private let theme = AddSubscriptionControllerTheme()
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var searchResults: [Artist]!
	var isBusy = false
	var artistCellReuseIdentifier = "artistCell"
	
	@IBOutlet var navBar: UINavigationBar!
	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var searchTable: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		searchResults = [Artist]()
		
		// Set theme
		theme.style = Theme.sharedInstance.style
		theme.set()

		// Configure search bar
		searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchBar.layer.borderWidth = 1
		searchBar.tintColor = Theme.sharedInstance.searchBarTintColor
		searchBar.barStyle = Theme.sharedInstance.searchBarStyle
		searchBar.keyboardAppearance = Theme.sharedInstance.keyboardStyle
		searchBar.becomeFirstResponder()

		// Configure search table
		searchTable.backgroundColor = theme.tableBackgroundColor
		searchTable.separatorColor = theme.cellSeparatorColor
		searchTable.registerNib(UINib(nibName: "SearchResultArtistCell", bundle: nil), forCellReuseIdentifier: artistCellReuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func performSearchFor (keyword: String) {
		isBusy = true
		let keyword = keyword.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
		let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&keyword=\(keyword)"
		let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
		dispatch_after(dispatchTime, dispatch_get_main_queue(), {
			API.sharedInstance.sendRequest(API.Endpoint.search.url(), postString: postString, successHandler: { (statusCode, data) in
				if statusCode != 200 {
					// errorHandler(error: API.Error.BadRequest)
					return
				}

				guard let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as? NSDictionary else {
					// errorHandler(error: API.Error.FailedToParseJSON)
					return
				}

				guard let artists: [NSDictionary] = json["artists"] as? [NSDictionary] else {
					// errorHandler(error: API.Error.FailedToParseJSON)
					return
				}

				for artist in artists {
					self.searchResults.append(Artist(
						ID: artist["ID"] as! Int,
						title: (artist["title"] as? String)!,
						iTunesUniqueID: artist["iTunesUniqueID"] as! Int,
						avatar: nil
						))
				}

				self.searchTable.reloadData()
				self.isBusy = false

				}, errorHandler: { (error) in
					self.isBusy = false
			})
		})
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
}

// MARK: - UITableViewDataSource
extension AddSubscriptionController: UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return searchResults.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(artistCellReuseIdentifier, forIndexPath: indexPath) as! SearchResultArtistCell
		cell.artistTitle.text = searchResults[indexPath.row].title
		cell.backgroundColor = theme.cellBackgroundColor
		let bgColorView = UIView()
		bgColorView.backgroundColor = theme.cellHighlightColor
		cell.selectedBackgroundView = bgColorView
		return cell
	}
}

// MARK: - UITableViewDataDelegate
extension AddSubscriptionController: UITableViewDelegate {
	
}

// MARK: - UISearchBarDelegate
extension AddSubscriptionController: UISearchBarDelegate {
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		if !isBusy {
			searchResults = [Artist]()
			self.searchTable.reloadData()
			if !searchBar.text!.isEmpty {
				performSearchFor(searchBar.text!)
			}
		}
	}

	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}

private class AddSubscriptionControllerTheme: Theme {
	var tableBackgroundColor: UIColor!
	var cellBackgroundColor: UIColor!
	var cellHighlightColor: UIColor!
	var cellSeparatorColor: UIColor!
	
	override init() {
		switch Theme.sharedInstance.style {
		case .dark:
			tableBackgroundColor = UIColor.clearColor()
			cellBackgroundColor = UIColor.clearColor()
		case .light:
			tableBackgroundColor = UIColor.whiteColor()
			cellBackgroundColor = UIColor.whiteColor()
			cellHighlightColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
			cellSeparatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
		}
	}
}
