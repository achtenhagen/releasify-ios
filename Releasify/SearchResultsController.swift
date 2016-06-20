//
//  SearchResultsController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/21/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SearchResultsController: UIViewController {

	private var theme: SearchResultsControllerTheme!

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var JSONPayload: [NSDictionary]?
	var searchResults: [SearchResult]!
	var tmpArtwork = [Int:UIImage]()
	var selectedAlbum: Album!
	var selectedArtist: String!
	var selectedArtists: [Int]!
	var needsRefresh = false
	
	@IBOutlet weak var navBar: UINavigationBar!
	@IBOutlet weak var infoLabel: UILabel!
	@IBOutlet weak var artistsTable: UITableView!
	
	@IBAction func closeView(sender: AnyObject) {
		closeView()
	}
	
	// Post notification if the user has added a new subscription
	func closeView() {
		self.dismissViewControllerAnimated(true, completion: { (completed) in
			if self.needsRefresh {
				NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
			}
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Initialization
		let navController = self.navigationController as! SearchResultsNavController
		selectedArtists = [Int]()
		theme = SearchResultsControllerTheme(style: appDelegate.theme.style)

		// Parse JSON payload into dictionary
		JSONPayload = navController.searchResults
		searchResults = [SearchResult]()
		parseSearchResults()
		
		artistsTable.registerNib(UINib(nibName: "SearchResultsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
		infoLabel.text = NSLocalizedString("Please choose from the list below.", comment: "")
		
		// Theme customizations
		self.view.backgroundColor = theme.viewBackgroundColor
		artistsTable.backgroundColor = UIColor.clearColor()
		artistsTable.separatorColor = theme.cellSeparatorColor
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}
		infoLabel.textColor = theme.infoLabelColor
	}

	override func viewWillAppear(animated: Bool) {
		let indexPath = artistsTable.indexPathForSelectedRow
		if indexPath != nil {
			artistsTable.deselectRowAtIndexPath(indexPath!, animated: true)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// Parse response data
	func parseSearchResults() {
		guard let data = JSONPayload else {
			if appDelegate.debug { print("Failed to parse search result") }
			return
		}
		for node in data {
			guard
				let ID = node["artistID"] as? Int,
				let title = node["title"] as? String,
				let iTunesUniqueID = node["iTunesUniqueID"] as? Int
			else {
				if appDelegate.debug { print("Failed to parse artist") }
				continue
			}
			let artist = Artist(ID: ID, title: title, iTunesUniqueID: iTunesUniqueID)
			if let JSONAlbums = node["albums"] as? [NSDictionary] {
				let albums = API.sharedInstance.parseAlbumsFrom(JSONAlbums)
				searchResults.append(SearchResult(artist: artist, albums: albums))
			} else {
				searchResults.append(SearchResult(artist: artist))
			}
		}
	}
	
	// Handle artist confirmation
	func confirmArtist(sender: UIButton) {
		let artistID = searchResults[sender.tag].artist.ID
		let artistTitle = searchResults[sender.tag].artist.title
		let artistUniqueID = searchResults[sender.tag].artist.iTunesUniqueID
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID[]=\(artistUniqueID)"
		API.sharedInstance.sendRequest(API.Endpoint.confirmArtist.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode == 200 {
				let headerView = self.artistsTable.headerViewForSection(sender.tag) as? SearchResultsHeader
				headerView?.confirmBtn.enabled = false
				let confirmImg = self.theme.style == .Dark ? "icon_confirm_dark" : "icon_confirm"
				headerView?.confirmBtn.setImage(UIImage(named: confirmImg), forState: .Disabled)
				AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID)
				AppDB.sharedInstance.getArtists()
				self.selectedArtists.append(artistUniqueID)
				if self.searchResults.count == self.selectedArtists.count {
					self.closeView()
				}
				self.needsRefresh = true
			}
			},
			   errorHandler: { (error) in
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
					alert.title = NSLocalizedString("Unable to subscribe!", comment: "")
					alert.message = NSLocalizedString("Please try again later.", comment: "")
				}
				let title = NSLocalizedString("OK", comment: "")
				alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
		})
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showAlbumFromSearchResults" {
			let albumDetailController = segue.destinationViewController as! AlbumDetailController
			albumDetailController.album = selectedAlbum
			albumDetailController.artist = selectedArtist
			albumDetailController.canAddToFavorites = false
			if let remote_artwork = tmpArtwork[selectedAlbum.ID] {
				albumDetailController.artwork = remote_artwork
			}
		}
	}
}

// MARK: - UITableViewDataSource
extension SearchResultsController: UITableViewDataSource {
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! SearchResultCell
		let album = searchResults[indexPath.section].albums![indexPath.row]
		cell.albumTitle.text = album.title
		cell.albumTitle.textColor = theme.albumTitleColor
		cell.releaseLabel.text = album.releaseDateAsYear(album.releaseDate)
		cell.releaseLabel.textColor = theme.releaseLabelColor
		let albumURL = album.artworkUrl
		let albumID = album.ID
		if let img = tmpArtwork[albumID] {
			cell.albumArtwork.image = img
		} else {
			API.sharedInstance.fetchArtwork(albumURL!, successHandler: { (artwork) in
				if let cellToUpdate = self.artistsTable.cellForRowAtIndexPath(indexPath) as? SearchResultCell {
					cellToUpdate.albumArtwork.alpha = 0
					cellToUpdate.albumArtwork.image = artwork
					UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: {
						cellToUpdate.albumArtwork.alpha = 1
						}, completion: nil)
				}
				}, errorHandler: {
					cell.albumArtwork.image = UIImage(named: "icon_artwork_dark")
			})
		}
		let bgColorView = UIView()
		bgColorView.backgroundColor = theme.cellHighlightColor
		cell.selectedBackgroundView = bgColorView
		return cell
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return searchResults.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// If condensed to 1 line, syntax highlighting will crash
		if let albums = searchResults[section].albums { return albums.count }
		return 0
	}
}

// MARK: - UITableViewDelegate
extension SearchResultsController: UITableViewDelegate {
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 50
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let album = searchResults[indexPath.section].albums![indexPath.row]
		selectedAlbum = album
		selectedArtist = searchResults[indexPath.section].artist.title
		self.performSegueWithIdentifier("showAlbumFromSearchResults", sender: self)
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = artistsTable.dequeueReusableHeaderFooterViewWithIdentifier("header") as! SearchResultsHeader
		let artistID = searchResults[section].artist.iTunesUniqueID
		let artistImg = theme.style == .Dark ? "icon_artist_placeholder_dark" : "icon_artist_placeholder"
		headerView.artistImg.image = UIImage(named: artistImg)
		headerView.contentView.backgroundColor = UIColor.clearColor()
		headerView.artistLabel.text = searchResults[section].artist.title
		headerView.artistLabel.textColor = theme.sectionHeaderLabelColor
		headerView.confirmBtn.tag = section		
		headerView.confirmBtn.addTarget(self, action: #selector(SearchResultsController.confirmArtist(_:)), forControlEvents: .TouchUpInside)
		if selectedArtists.contains(artistID) {
			let confirmImg = theme.style == .Dark ? "icon_confirm_dark" : "icon_confirm"
			headerView.confirmBtn.enabled = false
			headerView.confirmBtn.setImage(UIImage(named: confirmImg), forState: .Disabled)
		} else {
			let addImg = theme.style == .Dark ? "icon_add_dark" : "icon_add"
			headerView.confirmBtn.enabled = true
			headerView.confirmBtn.setImage(UIImage(named: addImg), forState: .Normal)
		}
		return headerView
	}
}

// Theme Subclass
private class SearchResultsControllerTheme: Theme {
	var viewBackgroundColor: UIColor!
	var infoLabelColor: UIColor!
	var sectionHeaderLabelColor: UIColor!
	var albumTitleColor: UIColor!
	var releaseLabelColor: UIColor!

	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			viewBackgroundColor = UIColor.clearColor()
			infoLabelColor = UIColor.whiteColor()
			sectionHeaderLabelColor = globalTintColor
			albumTitleColor = UIColor.whiteColor()
			releaseLabelColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
			break
		case .Light:
			viewBackgroundColor = UIColor.whiteColor()
			infoLabelColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			sectionHeaderLabelColor = globalTintColor
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			releaseLabelColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			break
		}
	}
}
