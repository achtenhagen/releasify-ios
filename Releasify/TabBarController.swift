//
//  TabBarController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/12/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

protocol TabControllerDelegate: class {
	func animateTitleView()
	func changeTitleViewText(title: String)
}

class TabBarController: UITabBarController {
	
	weak var notificationDelegate: AppControllerDelegate?
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var theme: Theme!
	var streamController: StreamViewController!
	var subscriptionController: SubscriptionController!
	var mediaQuery: MPMediaQuery!	
	var responseArtists: [NSDictionary]!
	var keyword: String!
	var favListBarBtn: UIBarButtonItem!
	var addBarBtn: UIBarButtonItem!
	
	@IBAction func addSubscription(sender: AnyObject) {
		self.performSegueWithIdentifier("AddSubscriptionSegue", sender: self)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

		theme = appDelegate.theme
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(addSubscriptionFromShortcutItem), name: "addSubscriptionShortcutItem", object: nil)
		mediaQuery = MPMediaQuery.artistsQuery()
		
		// Navigation bar items
		favListBarBtn = self.navigationController?.navigationBar.items![0].leftBarButtonItem
		favListBarBtn.tintColor = theme.globalTintColor
		addBarBtn = self.navigationController?.navigationBar.items![0].rightBarButtonItem
		addBarBtn.tintColor = theme.globalTintColor
		
		// Navigation item title view
		let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
		titleLabel.backgroundColor = UIColor.clearColor()
		titleLabel.textAlignment = NSTextAlignment.Center
		titleLabel.textColor = theme.globalTintColor
		titleLabel.font = UIFont.systemFontOfSize(17)
		titleLabel.adjustsFontSizeToFitWidth = true
		titleLabel.text = "Releasify"
		self.navigationItem.titleView = titleLabel

		// Theme customizations
		if theme.style == .dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		} else {
			self.view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 242/255, alpha: 1)
		}

		// Add 1px border to top of tab bar
		let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: self.tabBar.frame.size.width, height: 1))
		topBorder.backgroundColor = theme.tabBarTopBorderColor
		self.tabBar.addSubview(topBorder)

		// Initialize view controllers
		if streamController == nil {
			streamController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("StreamController") as! StreamViewController
			streamController.delegate = notificationDelegate
			streamController.tabBarDelegate = self
		}
		
		if subscriptionController == nil {
			subscriptionController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SubscriptionController") as! SubscriptionController
		}
		
		self.setViewControllers([streamController, subscriptionController], animated: true)
		
		// Handle 3D Touch quick action while app is not running
		if let shortcutItem = appDelegate.shortcutKeyDescription {
			if shortcutItem == "add-subscription" {
				addSubscriptionFromShortcutItem()
			}
		}
		
		// Adjust image inset for tabbar items
		for item in self.tabBar.items! {
			item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Handle 3D Touch quick action
	func addSubscriptionFromShortcutItem() {
		self.performSegueWithIdentifier("AddSubscriptionSegue", sender: self)
	}
	
	// MARK: - Handle failed subscription
	func handleAddSubscriptionError(error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = "Unable to update!"
			alert.message = "Please try again later."
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// MARK: - Error Message Handler
	func handleError(title: String, message: String, error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = title
			alert.message = message
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
}

// MARK: - TabControllerDelegate
extension TabBarController: TabControllerDelegate {
	func animateTitleView() {
		let animation = CATransition()
		animation.delegate = self
		animation.duration = 0.25
		animation.removedOnCompletion = false
		animation.type = kCATransitionPush
		animation.subtype = kCATransitionFromTop
		animation.beginTime = CACurrentMediaTime() + 1
		animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		animation.setValue("titleView", forKey: "animationKey")
		self.navigationItem.titleView!.layer.addAnimation(animation, forKey: "changeTitle")
	}

	func changeTitleViewText(title: String) {
		 let label = self.navigationItem.titleView as! UILabel
		 label.text = title
	}

	override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
		let value = anim.valueForKey("animationKey") as! String
		if value == "titleView" {
			changeTitleViewText("Releasify")
			return
		}
	}
}
