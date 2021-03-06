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
	
	private var theme: AddSubscriptionControllerTheme!
	private var artistCellReuseIdentifier = "ArtistCell"
	private var unwindSegueIdentifier = "ImportArtistsFromSearchResultsSegue"
	private var appEmptyStateView: UIView!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var searchBar: UISearchBar!
	var searchResults: [Artist]!
	var selectedArtist: Artist!
	var mediaQuery: MPMediaQuery!
	var delayTimer: NSTimer!
	var needsRefresh = false

	@IBOutlet var importContainer: UIView!
	@IBOutlet var importContainerTitle: UILabel!
	@IBOutlet var importContainerSubtitle: UILabel!
	@IBOutlet var importBtn: UIButton!
	@IBOutlet var searchTable: UITableView!

	@IBAction func UnwindToAddSubscriptionSegue(sender: UIStoryboardSegue) {
		if needsRefresh {			
			NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
		}
	}

	@IBAction func ImportArtists(sender: AnyObject) {
		self.resignFirstResponder()
		self.performSegueWithIdentifier(unwindSegueIdentifier, sender: self)
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		// Initialization
		searchResults = [Artist]()
		theme = AddSubscriptionControllerTheme(style: appDelegate.theme.style)

		// Search bar customizations
		searchBar = UISearchBar()
		searchBar.delegate = self
		searchBar.placeholder = NSLocalizedString("Search", comment: "")
		searchBar.searchBarStyle = .Minimal
		searchBar.barStyle = theme.searchBarStyle
		searchBar.barTintColor = UIColor.clearColor()
		searchBar.tintColor = theme.searchBarTintColor
		searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchBar.layer.borderWidth = 1
		searchBar.translucent = false
		searchBar.autocapitalizationType = .Words
		searchBar.keyboardAppearance = theme.keyboardStyle
		searchBar.showsCancelButton = true
		searchBar.returnKeyType = .Search
		searchBar.sizeToFit()
		self.navigationItem.titleView = searchBar
		searchBar.becomeFirstResponder()

		// Theme dependent gradient
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}

		// Import container customizations
		importContainer.backgroundColor = theme.importContainerBackgroundColor
		importContainerTitle.textColor = theme.importContainerTitleColor
		importContainerSubtitle.textColor = theme.importContainerSubtitle
		importBtn.setImage(theme.style == .Dark ? UIImage(named: "icon_import_dark") : UIImage(named: "icon_import"), forState: .Normal)

		// Add 1px bottom border to import container
		let topBorder = UIView(frame: CGRect(x: 0, y: 59, width: self.view.bounds.width, height: 1))
		topBorder.backgroundColor = theme.importContainerBorderColor
		self.importContainer.addSubview(topBorder)

		// Configure search table
		searchTable.backgroundColor = theme.tableViewBackgroundColor
		searchTable.separatorColor = theme.cellSeparatorColor
		searchTable.registerNib(UINib(nibName: "SearchResultArtistCell", bundle: nil), forCellReuseIdentifier: artistCellReuseIdentifier)

		// Query music library
		mediaQuery = MPMediaQuery.artistsQuery()
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 {
			importBtn.enabled = true
		}
    }

	override func viewDidAppear(animated: Bool) {
		searchBar.becomeFirstResponder()
	}

	override func viewWillAppear(animated: Bool) {
		let indexPath = self.searchTable.indexPathForSelectedRow
		if indexPath != nil {
			self.searchTable.deselectRowAtIndexPath(indexPath!, animated: true)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func delayTimerPerformSearch(userInfo: AnyObject) {
		let timer = userInfo as? NSTimer
		let keyword = timer?.userInfo as! String
		searchFor(keyword, errorHandler: { (error) in
			let title = NSLocalizedString("Oops!", comment: "")
			let message = NSLocalizedString("There was an error performing your search request. Please try again later.", comment: "")
			self.handleError(title, message: message, error: error)
		})
	}

	// Perform search on server for keyword
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
				self.searchResults.append(Artist(ID: artist["ID"] as! Int, title: (artist["title"] as? String)!,
					iTunesUniqueID: artist["iTunesUniqueID"] as! Int, avatar: nil))
			}
			self.searchTable.reloadData()
			if self.searchResults.count == 0 {
				self.showAppEmptyState()
			} else {
				self.hideAppEmptyState()
			}
			}, errorHandler: { (error) in
		})
	}

	// Show App empty state
	func showAppEmptyState() {
		if appEmptyStateView == nil {
			let title = NSLocalizedString("No Results", comment: "")
			let subtitle = NSLocalizedString("Your search did not return any results", comment: "")
			let stateImg = theme.style == .Dark ? "app_empty_state_search_dark" : "app_empty_state_search"
			let appEmptyState = AppEmptyState(style: theme.style, refView: self.view, imageName: stateImg, title: title,
			                                  subtitle: subtitle, buttonTitle: nil)
			appEmptyStateView = appEmptyState.view()
			searchTable.tableFooterView = UIView()
			self.view.addSubview(appEmptyStateView)
		}
	}

	// Hide App empty state
	func hideAppEmptyState() {
		if appEmptyStateView != nil {
			appEmptyStateView.removeFromSuperview()
			appEmptyStateView = nil
			searchTable.tableFooterView = nil
		}
	}

	// Error Message Handler
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
			alert.title = NSLocalizedString("Service Unavailable", comment: "Service Unavailable")
			alert.message = NSLocalizedString("We'll be back shortly, our servers are currently undergoing maintenance.", comment: "")
		default:
			alert.title = title
			alert.message = message
		}
		let title = NSLocalizedString("OK", comment: "")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ImportArtistsFromSearchResultsSegue" {
			let artistPickerController = segue.destinationViewController as! ArtistPicker
			artistPickerController.collection = mediaQuery.collections!
		} else if segue.identifier == "addArtistDetailSegue" {
			let addSubscriptionDetailView = segue.destinationViewController as! AddSubscriptionDetailView
			addSubscriptionDetailView.artistTitle = selectedArtist.title
			addSubscriptionDetailView.artistID = selectedArtist.ID
			addSubscriptionDetailView.artistUniqueID = selectedArtist.iTunesUniqueID
		} else if segue.identifier == "UnwindToStreamViewSegue" {
			
		}
	}
}

// MARK: - UITableViewDataSource
extension AddSubscriptionController: UITableViewDataSource {
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
		selectedArtist = searchResults[indexPath.row]
		searchBar.resignFirstResponder()
		self.performSegueWithIdentifier("addArtistDetailSegue", sender: self)
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
			hideAppEmptyState()
		}
	}

	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		if needsRefresh {
			self.performSegueWithIdentifier("UnwindToStreamViewSegue", sender: self)
		} else {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
}

// Theme Subclass
private class AddSubscriptionControllerTheme: Theme {
	var cellBackgroundColor: UIColor!
	var artistTitleColor: UIColor!
	var importContainerBackgroundColor: UIColor!
	var importContainerBorderColor: UIColor!
	var importContainerTitleColor: UIColor!
	var importContainerSubtitle: UIColor!
	var importContainerButtonColor: UIColor!
	
	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			cellBackgroundColor = UIColor.clearColor()
			artistTitleColor = UIColor.whiteColor()
			importContainerBackgroundColor = UIColor(red: 0, green: 22/255, blue: 32/255, alpha: 1)
			importContainerBorderColor = cellSeparatorColor
			importContainerTitleColor = UIColor.whiteColor()
			importContainerSubtitle = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			importContainerButtonColor = blueColor
		case .Light:
			cellBackgroundColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			importContainerBackgroundColor = UIColor.whiteColor()
			importContainerBorderColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
			importContainerTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			importContainerSubtitle = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			importContainerButtonColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
		}
	}
}
