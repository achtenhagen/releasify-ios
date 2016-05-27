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
	var artwork = [String:UIImage]()
	var selectedArtists = NSMutableArray()
	var keyword: String!
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

		theme = SearchResultsControllerTheme(style: appDelegate.theme.style)
		
		artistsTable.registerNib(UINib(nibName: "SearchResultsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
		if keyword == nil {
			infoLabel.text = "Please choose from the list below."
		} else {
			infoLabel.text = "Showing results for \"\(keyword)\""
		}
		
		// Theme customizations
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		} else {
			self.view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1)
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
					self.selectedArtists.addObject(artistUniqueID)
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
	func parseAlbumsByArtist(artist: NSDictionary) -> [NSDictionary] {
		guard let albums = artist["albums"] as? [NSDictionary] else {
			return [NSDictionary]()
		}
		return albums
	}
}

// MARK: - UITableViewDataSource
extension SearchResultsController: UITableViewDataSource {
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! SearchResultCell
		let albums = parseAlbumsByArtist(artists[indexPath.section])
		if albums.count > 0 {
			cell.albumTitle.text = albums[indexPath.row]["title"] as? String
			cell.releaseLabel.text = albums[indexPath.row]["releaseDate"] as? String
			let albumURL = albums[indexPath.row]["artworkUrl"] as? String
			if let img = artwork[albumURL!] {
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
						// show placeholder artwork
				})
			}
		}
		let bgColorView = UIView()
		bgColorView.backgroundColor = UIColor.clearColor()
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
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = artistsTable.dequeueReusableHeaderFooterViewWithIdentifier("header") as! SearchResultsHeader
		let artistID = (artists[section]["iTunesUniqueID"] as? Int)!
		headerView.contentView.backgroundColor = UIColor.clearColor()
		headerView.artistLabel.text = artists[section]["title"] as? String
		headerView.confirmBtn.tag = section		
		headerView.confirmBtn.addTarget(self, action: #selector(SearchResultsController.confirmArtist(_:)), forControlEvents: .TouchUpInside)
		if selectedArtists.containsObject(artistID) {
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
	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			break
		case .Light:
			break
		}
	}
}
