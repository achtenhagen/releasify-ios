//
//  FavoritesListController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/13/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class FavoritesListController: UIViewController {
	
	weak var appControllerDelegate: AppControllerDelegate?
	private var theme: FavoritesListControllerTheme!
	private var appEmptyStateView: UIView!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var navController: FavoritesNavController!
	var selectedAlbum: Album!
	var shouldRestore = false

	@IBOutlet var favoritesTable: UITableView!
	
	@IBAction func dismissViewController(sender: AnyObject) {
		Favorites.sharedInstance.save()
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

		theme = FavoritesListControllerTheme(style: appDelegate.theme.style)

		// Load favorites list
		Favorites.sharedInstance.load()

		// Navigation bar setup
		navController = self.navigationController as! FavoritesNavController

		// Observers
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(reloadFavoritesList), name: "reloadFavList", object: nil)

		// Theme customizations
		self.view.backgroundColor = theme.navBarTintColor
		self.favoritesTable.backgroundColor = theme.tableBackgroundColor
		self.favoritesTable.separatorColor = theme.cellSeparatorColor
		if theme.style == .Dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}

		if Favorites.sharedInstance.list.count == 0 {
			showAppEmptyState()
		}
    }

	override func viewDidAppear(animated: Bool) {
		if shouldRestore {
			navController.appControllerDelegate!.restoreMenu()
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		let indexPath = self.favoritesTable.indexPathForSelectedRow
		if indexPath != nil {
			self.favoritesTable.deselectRowAtIndexPath(indexPath!, animated: true)
		}
	}

	// MARK: - Show App empty state
	func showAppEmptyState() {
		if appEmptyStateView == nil {
			let appEmptyState = AppEmptyState(theme: theme, refView: self.view, imageName: "favorites_empty_state", title: "No Favorites",
			                                  subtitle: "Your favorites will appear here", buttonTitle: nil)
			appEmptyStateView = appEmptyState.view()
			favoritesTable.tableFooterView = UIView()
			self.view.addSubview(appEmptyStateView)
		}
	}

	// MARK: - Hide App empty state
	func hideAppEmptyState() {
		if appEmptyStateView != nil {
			appEmptyStateView.removeFromSuperview()
			appEmptyStateView = nil
			favoritesTable.tableFooterView = nil
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func reloadFavoritesList() {		
		self.favoritesTable.reloadData()
		if Favorites.sharedInstance.list.count == 0 {
			showAppEmptyState()
		} else {
			hideAppEmptyState()
		}
	}
	
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "FavoritesListAlbumSegue" {
			let detailController = segue.destinationViewController as! AlbumDetailController
			detailController.album = selectedAlbum
			detailController.artist = AppDB.sharedInstance.getAlbumArtist(selectedAlbum.ID)!
		}
    }
}

// MARK: - UITableViewDataSource
extension FavoritesListController: UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return Favorites.sharedInstance.list.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("favoritesCell", forIndexPath: indexPath) as! FavoritesListCell
		let favorites = Favorites.sharedInstance.list
		cell.artwork.image = AppDB.sharedInstance.getArtwork(favorites[indexPath.row].artwork)		
		cell.albumTitle.text = favorites[indexPath.row].title
		cell.artistTitle.text = AppDB.sharedInstance.getAlbumArtist(favorites[indexPath.row].ID)!
		cell.backgroundColor = theme.cellBackgroundColor
		cell.albumTitle.textColor = theme.albumTitleColor
		cell.artistTitle.textColor = theme.artistTitleColor
		let bgColorView = UIView()
		bgColorView.backgroundColor = theme.cellHighlightColor
		cell.selectedBackgroundView = bgColorView
		return cell
	}
}

// MARK: - UITableViewDelegate
extension FavoritesListController: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedAlbum = Favorites.sharedInstance.list[indexPath.row]
		navController.appControllerDelegate?.fullyHideMenu()
		shouldRestore = true
		self.performSegueWithIdentifier("FavoritesListAlbumSegue", sender: self)
	}
	
	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let removeAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "         ", handler: { (action, indexPath) -> Void in
			Favorites.sharedInstance.removeFavorite(indexPath.row)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)			
			if Favorites.sharedInstance.list.count == 0 {
				self.showAppEmptyState()
			}
		})
		removeAction.backgroundColor = UIColor(patternImage: UIImage(named: "row_action_delete_small")!)
		return [removeAction]
	}
}

// MARK: - Theme Extension
private class FavoritesListControllerTheme: Theme {
	var viewBackgroundColor: UIColor!
	var tableBackgroundColor: UIColor!
	var cellBackgroundColor: UIColor!
	var albumTitleColor: UIColor!
	var artistTitleColor: UIColor!
	
	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			viewBackgroundColor = UIColor.clearColor()
			tableBackgroundColor = UIColor.clearColor()
			cellBackgroundColor = UIColor.clearColor()
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		case .Light:
			viewBackgroundColor = UIColor.whiteColor()
			tableBackgroundColor = UIColor.whiteColor()
			cellBackgroundColor = UIColor.whiteColor()
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1.0)
			artistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
		}
	}
}
