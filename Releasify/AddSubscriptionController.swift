//
//  AddSubscriptionController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/26/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class AddSubscriptionController: UIViewController {
	
	private let theme = AddSubscriptionControllerTheme()
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var searchResults: [Artist]!
	var artistCellReuseIdentifier = "artistCell"
	var mediaQuery: MPMediaQuery!
	var delayTimer: NSTimer!
	
	@IBOutlet var navBar: UINavigationBar!
	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var importContainer: UIView!
	@IBOutlet var importBtn: UIButton!
	@IBOutlet var searchTable: UITableView!
	

	@IBAction func ImportArtists(sender: AnyObject) {
		self.performSegueWithIdentifier("ImportArtistsFromSearchResultsSegue", sender: self)
	}

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

		// Theme dependent gradient
		if Theme.sharedInstance.style == .dark {
			let gradient = Theme.sharedInstance.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}

		// Add 1px bottom border to import container
		let topBorder = UIView(frame: CGRect(x: 0, y: 55, width: self.view.bounds.width, height: 1))
		topBorder.backgroundColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
		self.importContainer.addSubview(topBorder)

		// Configure search table
		searchTable.backgroundColor = theme.tableBackgroundColor
		searchTable.separatorColor = theme.cellSeparatorColor
		searchTable.registerNib(UINib(nibName: "SearchResultArtistCell", bundle: nil), forCellReuseIdentifier: artistCellReuseIdentifier)

		// Query music library
		mediaQuery = MPMediaQuery.artistsQuery()
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 {
			importBtn.enabled = true
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func delayTimerPerformSearch(userInfo: AnyObject) {
		let timer = userInfo as? NSTimer
		let keyword = timer?.userInfo as! String
		searchFor(keyword, errorHandler: { (error) in
			self.handleError("Oops!", message: "There was an error performing your search request. Please try again later.", error: error)
		})
	}

	func searchFor(keyword: String, errorHandler: ((error: ErrorType) -> Void)) {
		let keyword = keyword.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
		let postString = "id=\(self.appDelegate.userID)&uuid=\(self.appDelegate.userUUID)&keyword=\(keyword)"
		API.sharedInstance.sendRequest(API.Endpoint.search.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 200 {
				errorHandler(error: API.sharedInstance.getErrorFor(statusCode))
				return
			}

			guard let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as? NSDictionary else {
				errorHandler(error: API.Error.FailedToParseJSON)
				return
			}

			guard let artists: [NSDictionary] = json["artists"] as? [NSDictionary] else {
				errorHandler(error: API.Error.FailedToParseJSON)
				return
			}

			self.searchResults = [Artist]()
			for artist in artists {
				self.searchResults.append(Artist(
					ID: artist["ID"] as! Int,
					title: (artist["title"] as? String)!,
					iTunesUniqueID: artist["iTunesUniqueID"] as! Int,
					avatar: nil
					))
			}
			self.searchTable.reloadData()
			}, errorHandler: { (error) in
		})
	}

	// MARK: - Error Message Handler
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
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
		if segue.identifier == "ImportArtistsFromSearchResultsSegue" {
			let artistPickerController = segue.destinationViewController as! ArtistsPicker
			artistPickerController.collection = mediaQuery.collections!
		}
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
		cell.artistTitle.textColor = theme.artistTitleColor
		cell.backgroundColor = theme.cellBackgroundColor
		let bgColorView = UIView()
		bgColorView.backgroundColor = theme.cellHighlightColor
		cell.selectedBackgroundView = bgColorView
		return cell
	}
}

// MARK: - UITableViewDataDelegate
extension AddSubscriptionController: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

	}
}

// MARK: - UISearchBarDelegate
extension AddSubscriptionController: UISearchBarDelegate {
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		if delayTimer != nil {
			delayTimer.invalidate()
			delayTimer = nil
		}
		if !searchBar.text!.isEmpty {
			delayTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(delayTimerPerformSearch(_:)), userInfo: searchBar.text, repeats: false)
		} else {
			searchResults = [Artist]()
			self.searchTable.reloadData()
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
	var artistTitleColor: UIColor!
	
	override init() {
		switch Theme.sharedInstance.style {
		case .dark:
			tableBackgroundColor = UIColor.clearColor()
			cellBackgroundColor = UIColor.clearColor()
			artistTitleColor = UIColor.whiteColor()
		case .light:
			tableBackgroundColor = UIColor.whiteColor()
			cellBackgroundColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1.0)
		}
	}
}
