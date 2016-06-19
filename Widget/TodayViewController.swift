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
		self.preferredContentSize = CGSize(width: 0, height: 65)
		updateTitle()
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openInApp))
		self.view.addGestureRecognizer(tapGesture)

		// Add vibrancy effect
		let effectView = UIVisualEffectView(effect: UIVibrancyEffect.notificationCenterVibrancyEffect())
		effectView.frame = self.view.bounds
		effectView.autoresizingMask = self.view.autoresizingMask
		let view = self.view
		self.view = effectView
		effectView.contentView.addSubview(view)
		self.view.tintColor = UIColor.clearColor()
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
		guard let title = sharedDefaults?.stringForKey("upcomingAlbum") else {
			upcomingTitle.text = "No Upcoming Albums"
			return
		}
		if title != upcomingTitle.text {
			upcomingTitle.fadeOut(0.2, delay: 1, completion: { (complete) in
				self.upcomingTitle.text = title
				self.upcomingTitle.fadeIn()
			})
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

// MARK: - UIView extension
extension UIView {
	func fadeIn(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0, completion: (Bool) -> Void = { (finished) in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 1 }, completion: completion)
	}
	func fadeOut(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0, completion: (Bool) -> Void = { (finished) in } ) {
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.alpha = 0 }, completion: completion)
	}
}