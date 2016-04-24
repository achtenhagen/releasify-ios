//
//  AddSubscriptionDetailView.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/23/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

private let albumCellReuseIdentifier = "AlbumCell"

class AddSubscriptionDetailView: UICollectionViewController {

	private var theme: AddSubscriptionDetailViewTheme!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var artistID: Int!
	var artistUniqueID: Int!
	var artistTitle: String!
	var albums: [Album]!
	var spinner: UIActivityIndicatorView!

	@IBAction func confirmArtist(sender: AnyObject) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID[]=\(artistUniqueID)"
		API.sharedInstance.sendRequest(API.Endpoint.confirmArtist.url(), postString: postString, successHandler: { (statusCode, data) in
				self.performSegueWithIdentifier("UnwindToAddSubscriptionSegue", sender: self)
			}, errorHandler: { (error) in

		})
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		theme = AddSubscriptionDetailViewTheme(style: appDelegate.theme.style)
		albums = [Album]()

		self.navigationItem.title = artistTitle

        // Register cell class
        self.collectionView!.registerNib(UINib(nibName: "AlbumCell", bundle: nil), forCellWithReuseIdentifier: albumCellReuseIdentifier)

		// Collection view customizations
		self.collectionView?.backgroundColor = theme.viewBackgroundColor
		if theme.style == .dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}

		// Show spinner while albums are fetched
		spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
		spinner.color = theme.globalTintColor
		var frame = spinner.frame
		frame.origin.x = view.frame.size.width / 2 - frame.size.width / 2
		frame.origin.y = view.frame.size.height / 2 - frame.size.height / 2
		spinner.frame = frame
		self.view.addSubview(spinner)
		spinner.startAnimating()

		API.sharedInstance.getAlbumsByArtist(artistUniqueID, successHandler: { (albums) in
			self.albums = albums
			self.collectionView?.reloadData()
			self.spinner.stopAnimating()
			}, errorHandler: { (error) in
				// Handle error
		})
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(albumCellReuseIdentifier, forIndexPath: indexPath) as! AlbumCell
		cell.timeLeft.text = albums![indexPath.row].getFormattedReleaseDate()
		cell.albumTitle.text = albums[indexPath.row].title
		cell.artistTitle.text = artistTitle
		cell.albumTitle.textColor = theme.albumTitleColor
		cell.artistTitle.textColor = theme.artistTitleColor
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

private class AddSubscriptionDetailViewTheme: Theme {
	var viewBackgroundColor: UIColor!
	var albumTitleColor: UIColor!
	var artistTitleColor: UIColor!

	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .dark:
			viewBackgroundColor = UIColor.clearColor()
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		case .light:
			viewBackgroundColor = UIColor.whiteColor()
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			artistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
		}
	}
}
