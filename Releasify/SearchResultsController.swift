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
	var artists: [NSDictionary]!
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
	
	// MARK: - Post notification if the user has added a new subscription
	func closeView() {
		self.dismissViewControllerAnimated(true, completion: { (completed) in
			if self.needsRefresh {				
				NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
			}
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		let navController = self.navigationController as! SearchResultsNavController
		artists = navController.artists
		selectedArtists = [Int]()
		theme = SearchResultsControllerTheme(style: appDelegate.theme.style)
		
		artistsTable.registerNib(UINib(nibName: "SearchResultsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
		infoLabel.text = "Please choose from the list below."
		
		// Theme customizations
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		} else {
			self.view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1)
		}
		infoLabel.textColor = theme.infoLabelColor

		artistsTable.separatorColor = theme.cellSeparatorColor
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
	
	// MARK: - Handle artist confirmation
	func confirmArtist(sender: UIButton) {
		var artistID = 0		
		if let id = artists[sender.tag]["artistID"] as? Int { artistID = id }
		let artistTitle = (artists[sender.tag]["title"] as? String)!
		if let artistUniqueID  = (artists[sender.tag]["iTunesUniqueID"] as? Int) {
			let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID[]=\(artistUniqueID)"
			API.sharedInstance.sendRequest(API.Endpoint.confirmArtist.url(), postString: postString, successHandler: { (statusCode, data) in
				if statusCode == 200 {
					let headerView = self.artistsTable.headerViewForSection(sender.tag) as? SearchResultsHeader
					headerView?.confirmBtn.enabled = false
					headerView?.confirmBtn.setImage(UIImage(named: "icon_confirm"), forState: .Disabled)
					AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID)
					AppDB.sharedInstance.getArtists()
					self.selectedArtists.append(artistUniqueID)
					if self.artists.count == self.selectedArtists.count {
						self.closeView()
					}
					self.needsRefresh = true
				}
				},
				errorHandler: { (error) in
					let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
					switch (error) {
					case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
						alert.title = "You're Offline!"
						alert.message = "Please make sure you are connected to the internet, then try again."
						alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
							UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
						}))
					default:
						alert.title = "Unable to subscribe!"
						alert.message = "Please try again later."
					}
					alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
					self.presentViewController(alert, animated: true, completion: nil)
			})
		}
	}

	// MARK: - Parse response data
	func parseAlbumsByArtist(artist: NSDictionary) -> [Album] {
		var albums = [Album]()
		guard let json = artist["albums"] as? [NSDictionary] else { return albums }
		for item in json {
			guard let ID = item["ID"] as? Int,
				let title = item["title"] as? String,
				let artistID = item["artistID"] as? Int,
				let releaseDate = item["releaseDate"] as? Double,
				let artworkUrl = item["artworkUrl"] as? String,
				let explicit = item["explicit"] as? Int,
				let copyright = item["copyright"] as? String,
				let iTunesUniqueID = item["iTunesUniqueID"] as? Int,
				let iTunesUrl = item["iTunesUrl"] as? String else { break }
			let albumItem = Album(ID: ID, title: title, artistID: artistID, releaseDate: releaseDate, artwork: md5(artworkUrl),
			                      artworkUrl: artworkUrl, explicit: explicit, copyright: copyright, iTunesUniqueID: iTunesUniqueID, iTunesUrl: iTunesUrl,
			                      created: Int(NSDate().timeIntervalSince1970))
			albums.append(albumItem)
		}
		return albums
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
		let albums = parseAlbumsByArtist(artists[indexPath.section])
		let album = albums[indexPath.row]
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
		return artists.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let albums = (artists[section]["albums"] as? [NSDictionary])!
		return albums.count
	}
}

// MARK: - UITableViewDelegate
extension SearchResultsController: UITableViewDelegate {
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 50
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let jsonData = artists[indexPath.section]["albums"] as? [NSDictionary] else { return }
		let albums = API.sharedInstance.processAlbumsFrom(jsonData)
		selectedAlbum = albums[indexPath.row]
		selectedArtist = artists[indexPath.section]["title"] as? String
		self.performSegueWithIdentifier("showAlbumFromSearchResults", sender: self)
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = artistsTable.dequeueReusableHeaderFooterViewWithIdentifier("header") as! SearchResultsHeader
		let artistID = (artists[section]["iTunesUniqueID"] as? Int)!
		headerView.contentView.backgroundColor = UIColor.clearColor()
		headerView.artistLabel.text = artists[section]["title"] as? String
		headerView.confirmBtn.tag = section		
		headerView.confirmBtn.addTarget(self, action: #selector(SearchResultsController.confirmArtist(_:)), forControlEvents: .TouchUpInside)
		if selectedArtists.contains(artistID) {
			headerView.confirmBtn.enabled = false
			headerView.confirmBtn.setImage(UIImage(named: "icon_confirm"), forState: .Disabled)
		} else {
			headerView.confirmBtn.enabled = true
			headerView.confirmBtn.setImage(UIImage(named: "icon_add"), forState: .Normal)
		}
		return headerView
	}
}

// MARK: - Theme Subclass
private class SearchResultsControllerTheme: Theme {
	var infoLabelColor: UIColor!
	var albumTitleColor: UIColor!
	var releaseLabelColor: UIColor!

	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			infoLabelColor = UIColor.whiteColor()
			albumTitleColor = UIColor.whiteColor()
			releaseLabelColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
			break
		case .Light:
			break
		}
	}
}
