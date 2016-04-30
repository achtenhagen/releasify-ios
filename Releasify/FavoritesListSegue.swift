//
//  FavoritesListSegue.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/29/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class FavoritesListSegue: UIStoryboardSegue {

	override func perform() {
		let sourceViewController = self.sourceViewController
		let destinationViewController = self.destinationViewController
		let navBar = sourceViewController.navigationController?.navigationBar

		// Temporarily add destination controller to source controller
		destinationViewController.view.frame = CGRect(x: 0, y: -sourceViewController.view.frame.size.height,
		                                              width: sourceViewController.view.frame.width,
		                                              height: sourceViewController.view.frame.height)
		sourceViewController.view.addSubview(destinationViewController.view)

		UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
				sourceViewController.navigationController?.navigationBar.frame.origin.y += sourceViewController.view.bounds.size.height
				destinationViewController.view.frame.origin.y = -44
			}, completion: { (completed) in
				destinationViewController.view.removeFromSuperview()
				destinationViewController.view.addSubview(navBar!)
				sourceViewController.presentViewController(destinationViewController, animated: false, completion: nil)
				// navBar?.removeFromSuperview()
				// sourceViewController.navigationController?.navigationBar.frame.origin.y = 20
		})
	}
}
