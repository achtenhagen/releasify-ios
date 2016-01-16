//
//  Intro02Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro02Controller: UIViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	weak var delegate: IntroPageDelegate?
	
	@IBOutlet weak var imageTopLayoutConstraint: NSLayoutConstraint!
	@IBAction func skipButtonPressed(sender: UIButton) {
		if delegate != nil {
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
			alert.title = "Disable Push Notifications?"
			alert.message = "Please confirm that you would like to disable Push Notifications. You can re-enable them later in iOS settings."
			alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
			alert.addAction(UIAlertAction(title: "Disable", style: .Destructive, handler: { action in
				if self.appDelegate.userID == 0 {
					API.sharedInstance.register(self.appDelegate.allowExplicitContent, successHandler: { (userID, userUUID) in
						self.appDelegate.userID = userID!
						self.appDelegate.userUUID = userUUID
						NSUserDefaults.standardUserDefaults().setInteger(self.appDelegate.userID, forKey: "ID")
						NSUserDefaults.standardUserDefaults().setValue(self.appDelegate.userUUID, forKey: "uuid")
						self.delegate?.advanceIntroPageTo(3, reverse: false)
						},
						errorHandler: { (error) in
							self.handleError(error)
					})
				} else {
					self.delegate?.advanceIntroPageTo(3, reverse: false)
				}
			}))
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	// MARK: - Notification settings
	@IBAction func permissionBtn(sender: UIButton) {
		if UIApplication.sharedApplication().respondsToSelector("registerUserNotificationSettings:") {			
			let appAction = UIMutableUserNotificationAction()
			appAction.identifier = "APP_ACTION"
			appAction.title = "Open in App"
			appAction.activationMode = .Foreground
			appAction.destructive = false
			appAction.authenticationRequired = false
			
			let storeAction = UIMutableUserNotificationAction()
			storeAction.identifier = "STORE_ACTION"
			storeAction.title = "Purchase"
			storeAction.activationMode = .Foreground
			storeAction.destructive = false
			storeAction.authenticationRequired = false
			
			let preorderAction = UIMutableUserNotificationAction()
			preorderAction.identifier = "PREORDER_ACTION"
			preorderAction.title = "Pre-Order"
			preorderAction.activationMode = .Foreground
			preorderAction.destructive = false
			preorderAction.authenticationRequired = false
			
			let defaultCategory = UIMutableUserNotificationCategory()
			defaultCategory.identifier = "DEFAULT_CATEGORY"
			
			let remoteCategory = UIMutableUserNotificationCategory()
			remoteCategory.identifier = "REMOTE_CATEGORY"
			
			let defaultActions = [storeAction, appAction]
			let remoteActions  = [preorderAction, appAction]
			
			defaultCategory.setActions(defaultActions, forContext: .Default)
			defaultCategory.setActions(defaultActions, forContext: .Minimal)
			remoteCategory.setActions(remoteActions, forContext: .Default)
			remoteCategory.setActions(remoteActions, forContext: .Minimal)
			
			let categories = NSSet(objects: defaultCategory, remoteCategory)
			let types: UIUserNotificationType = ([.Alert, .Badge, .Sound])
			let settings = UIUserNotificationSettings(forTypes: types, categories: categories as? Set<UIUserNotificationCategory>)
			
			UIApplication.sharedApplication().registerUserNotificationSettings(settings)
			UIApplication.sharedApplication().registerForRemoteNotifications()
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
		if view.bounds.height == 480 {
			imageTopLayoutConstraint.constant = 200
		} else if view.bounds.height == 568 {
			imageTopLayoutConstraint.constant = 260
		}
		NSNotificationCenter.defaultCenter().addObserver(self, selector:"finishRegister", name: "finishNotificationRegister", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func finishRegister () {
		if appDelegate.userID > 0 && self.delegate != nil{
			self.delegate?.advanceIntroPageTo(3, reverse: false)
		}
	}
	
	func handleError (error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = "You're Offline!"
			alert.message = "Please make sure you are connected to the internet, then try again."
			alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = "Unable to register"
			alert.message = "Please try again later."
		}
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
}
