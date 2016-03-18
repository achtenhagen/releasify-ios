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
	
	@IBOutlet var navBar: UINavigationBar!	
	@IBOutlet var searchBar: UISearchBar!
	@IBOutlet var searchTable: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		theme.style = Theme.sharedInstance.style
		theme.set()
		
		searchBar.layer.borderColor = UIColor.clearColor().CGColor
		searchBar.layer.borderWidth = 1
		searchBar.tintColor = Theme.sharedInstance.searchBarTintColor
		searchBar.barStyle = Theme.sharedInstance.searchBarStyle
		// searchBar.barTintColor = UIColor.clearColor()
		searchBar.keyboardAppearance = Theme.sharedInstance.keyboardStyle
		searchTable.backgroundColor = theme.tableBackgroundColor
		searchBar.becomeFirstResponder()
    }
	
	override func viewDidAppear(animated: Bool) {
		
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
}

// MARK: - UITableViewDataSource
extension AddSubscriptionController: UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 0
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
		cell.backgroundColor = theme.cellBackgroundColor
		return cell
	}
}

// MARK: - UITableViewDataDelegate
extension AddSubscriptionController: UITableViewDelegate {
	
}

extension AddSubscriptionController: UISearchBarDelegate {
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}

private class AddSubscriptionControllerTheme: Theme {
	var tableBackgroundColor: UIColor!
	var cellBackgroundColor: UIColor!
	
	override init() {
		switch Theme.sharedInstance.style {
		case .dark:
			tableBackgroundColor = UIColor.clearColor()
			cellBackgroundColor = UIColor.clearColor()
		case .light:
			tableBackgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1.0)
			cellBackgroundColor = UIColor.whiteColor()
		}
	}
	
}
