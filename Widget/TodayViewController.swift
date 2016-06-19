//
//  TodayViewController.swift
//  Widget
//
//  Created by Maurice Achtenhagen on 6/14/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController {

	@IBOutlet var upcomingTitle: UILabel!

	override func viewDidLoad() {
        super.viewDidLoad()
		self.preferredContentSize = CGSize(width: 0, height: 60)
		updateTitle()
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openInApp))
		upcomingTitle.addGestureRecognizer(tapGesture)
    }

	override func viewWillAppear(animated: Bool) {
		updateTitle()
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	func openInApp() {
		self.extensionContext?.openURL(NSURL(string: "releasify://upcoming")!, completionHandler: nil)
	}

	func updateTitle() {
		let sharedDefaults = NSUserDefaults(suiteName: "group.fioware.TodayExtensionSharingDefaults")
		if let title = sharedDefaults?.stringForKey("upcomingAlbum")  {
			upcomingTitle.text = title
		} else {
			upcomingTitle.text = "No Upcoming Albums"
		}
	}
}

// MARK: - NCWidgetProviding

extension TodayViewController: NCWidgetProviding {
	func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
		updateTitle()
		completionHandler(NCUpdateResult.NewData)
	}

	func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		return UIEdgeInsetsZero
	}
}
