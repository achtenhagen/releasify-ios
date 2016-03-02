//
//  SearchResultsController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/21/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SearchResultsController: UIViewController {
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
		self.dismissViewControllerAnimated(true, completion: { bool in
			if self.needsRefresh {
				NSNotificationCenter.defaultCenter().postNotificationName("refreshContent", object: nil, userInfo: nil)
			}
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		artistsTable.registerNib(UINib(nibName: "SearchResultsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
		if keyword == nil {
			infoLabel.text = "Please choose from the list below."
		} else {
			infoLabel.text = "Showing results for \"\(keyword)\""
		}
		
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
		self.view.layer.insertSublayer(gradient, atIndex: 0)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	// MARK: - Handle artist confirmation
	func confirmArtist(sender: UIButton) {
		var artistID = 0		
		if let id = (artists[sender.tag]["artistID"] as? Int) { artistID = id }
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
}

// MARK: - UITableViewDataSource
extension SearchResultsController: UITableViewDataSource {
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = artistsTable.dequeueReusableCellWithIdentifier("ArtistCell") as! SearchResultCell
		let album = (artists[indexPath.section]["albums"] as? [NSDictionary])!
		if album.count > 0 {
			cell.albumTitle.text = album[indexPath.row]["title"] as? String
			cell.releaseLabel.text = album[indexPath.row]["releaseDate"] as? String
			let hash = album[indexPath.row]["artwork"]! as! String
			let subDir = (hash as NSString).substringWithRange(NSRange(location: 0, length: 2))
			let albumURL = "https://releasify.io/static/artwork/music/\(subDir)/\(hash).jpg"
			if let img = artwork[albumURL] {
				cell.albumArtwork.image = img
			} else {
				if let checkedURL = NSURL(string: albumURL) {
					let request = NSURLRequest(URL: checkedURL)
					NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
						if error != nil {
							return
						}
						if let HTTPResponse = response as? NSHTTPURLResponse {
							if HTTPResponse.statusCode == 404 { return }
							if HTTPResponse.statusCode == 200 {
								let image = UIImage(data: data!)
								self.artwork[albumURL] = image
								dispatch_async(dispatch_get_main_queue(), {
									if let cellToUpdate = self.artistsTable.cellForRowAtIndexPath(indexPath) as? SearchResultCell {
										cellToUpdate.albumArtwork.alpha = 0
										cellToUpdate.albumArtwork.image = image
										UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: {
											cellToUpdate.albumArtwork.alpha = 1.0
											}, completion: nil)
									}
								})
							}
						}
						
					})
				}
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
		headerView.confirmBtn.addTarget(self, action: "confirmArtist:", forControlEvents: .TouchUpInside)
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
