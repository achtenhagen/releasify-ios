//
//  AddSubscriptionDetailView.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/23/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AddSubscriptionDetailView: UICollectionViewController {

	private let albumCellReuseIdentifier = "AlbumCell"
	private var theme: AddSubscriptionDetailViewTheme!
	private var appEmptyStateView: UIView!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var artistID: Int!
	var artistUniqueID: Int!
	var artistTitle: String!
	var albums: [Album]!
	var tmpArtwork: [String:UIImage]!
	var spinner: UIActivityIndicatorView!
	var selectedAlbum: Album!

	@IBAction func confirmArtist(sender: AnyObject) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID[]=\(artistUniqueID)"
		API.sharedInstance.sendRequest(API.Endpoint.confirmArtist.url(), postString: postString, successHandler: { (statusCode, data) in
				self.performSegueWithIdentifier("UnwindToAddSubscriptionSegue", sender: self)
			}, errorHandler: { (error) in
				// Handle error
		})
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		theme = AddSubscriptionDetailViewTheme(style: appDelegate.theme.style)
		albums = [Album]()
		tmpArtwork = [String:UIImage]()

		self.navigationItem.title = artistTitle

		// Check whether user is already subscribed to artist
		if AppDB.sharedInstance.getArtistByUniqueID(artistUniqueID) > 0 {
			self.navigationItem.rightBarButtonItem?.enabled = false
		}

        // Register cell class
        self.collectionView!.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)

		// Collection view customizations
		self.collectionView?.setCollectionViewLayout(AlbumCollectionViewLayout(), animated: false)
		self.collectionView?.backgroundColor = theme.viewBackgroundColor
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}

		// Theme customizations
		self.navigationItem.rightBarButtonItem?.tintColor = theme.style == .Dark ? theme.greenColor : theme.globalTintColor

		// Show spinner while albums are fetched
		spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
		spinner.color = theme.globalTintColor
		var frame = spinner.frame
		frame.origin.x = view.frame.size.width / 2 - frame.size.width / 2
		frame.origin.y = view.frame.size.height / 2 - frame.size.height / 2
		spinner.frame = frame
		self.view.addSubview(spinner)
		spinner.startAnimating()

		// Fetch albums by artist
		API.sharedInstance.getAlbumsByArtist(artistUniqueID, successHandler: { (albums) in
			self.albums = albums
			self.collectionView?.reloadData()
			self.spinner.stopAnimating()
			if self.albums.count == 0 {
				self.showAppEmptyState()
			}
			}, errorHandler: { (error) in
				// Handle error
		})
    }

	// MARK: - Show App empty state
	func showAppEmptyState() {
		if appEmptyStateView == nil {
			let title = NSLocalizedString("No Albums", comment: "")
			let subtitle = NSLocalizedString("We have no content for this artist yet", comment: "")
			let stateImg = theme.style == .Dark ? "app_empty_state_albums_dark" : "app_empty_state_albums"
			let appEmptyState = AppEmptyState(style: theme.style, refView: self.view, imageName: stateImg, title: title,
			                                  subtitle: subtitle, buttonTitle: nil)
			appEmptyStateView = appEmptyState.view()
			self.view.addSubview(appEmptyStateView)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ArtistDetailAlbumsSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
			detailController.artist = artistTitle
			detailController.canAddToFavorites = false
			if let remote_artwork = tmpArtwork[selectedAlbum.artwork] {
				detailController.artwork = remote_artwork
			}
		} else if segue.identifier == "UnwindToAddSubscriptionSegue" {
			let destinationController = segue.destinationViewController as! AddSubscriptionController
			destinationController.needsRefresh = true
		}
    }

	// MARK: - Return artwork for each collection view cell
	func getArtworkForCell(url: String, hash: String, completion: ((artwork: UIImage) -> Void)) {
		if tmpArtwork![hash] != nil {
			completion(artwork: tmpArtwork![hash]!)
			return
		}
		API.sharedInstance.fetchArtwork(url, successHandler: { artwork in
			self.tmpArtwork![hash] = artwork
			completion(artwork: self.tmpArtwork![hash]!)
			}, errorHandler: {
				let filename = self.theme.style == .Dark ? "icon_artwork_dark" : "icon_artwork"
				completion(artwork: UIImage(named: filename)!)
		})
	}

    // MARK: - UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(albumCellReuseIdentifier, forIndexPath: indexPath) as! AlbumCell
		let album = albums[indexPath.row]
		let albumWillFadeIn = tmpArtwork![album.artwork] == nil ? true : false
		cell.alpha = 0
		cell.containerView.hidden = true
		cell.timeLeft.text = album.getFormattedReleaseDate()
		cell.albumTitle.text = album.title
		cell.artistTitle.text = artistTitle
		cell.albumTitle.textColor = theme.albumTitleColor
		cell.artistTitle.textColor = theme.artistTitleColor
		cell.albumArtwork.image = UIImage()
		getArtworkForCell(album.artworkUrl!, hash: album.artwork, completion: { (artwork) in
			cell.albumArtwork.image = artwork
			if albumWillFadeIn {
				cell.fadeIn()
			} else {
				cell.alpha = 1
			}
		})
        return cell
    }

    // MARK: - UICollectionViewDelegate

	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		selectedAlbum = albums![indexPath.row]
		self.performSegueWithIdentifier("ArtistDetailAlbumsSegue", sender: self)
	}

	override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
		collectionView.cellForItemAtIndexPath(indexPath)?.alpha = 0.8
	}

	override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
		collectionView.cellForItemAtIndexPath(indexPath)?.alpha = 1.0
	}
}

private class AddSubscriptionDetailViewTheme: Theme {
	var viewBackgroundColor: UIColor!
	var albumTitleColor: UIColor!
	var artistTitleColor: UIColor!

	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			viewBackgroundColor = UIColor.clearColor()
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		case .Light:
			viewBackgroundColor = UIColor.whiteColor()
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			artistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
		}
	}
}
