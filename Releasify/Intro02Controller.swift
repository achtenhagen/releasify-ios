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
	
	@IBOutlet var skipBtn: UIButton!
	@IBOutlet var permissionBtn: UIButton!
	
	@IBOutlet weak var imageTopLayoutConstraint: NSLayoutConstraint!
	@IBAction func skipButtonPressed(sender: UIButton) {
		if delegate == nil { return }
		if appDelegate.userID > 0 {
			self.delegate?.advanceIntroPageTo(3, reverse: false)
			return
		}
		let title = NSLocalizedString("Disable Push Notifications?", comment: "")
		let message = NSLocalizedString("Please confirm that you would like to disable Push Notifications. You can re-enable them later in iOS settings.", comment: "")
		let cancelTitle = NSLocalizedString("Cancel", comment: "")
		let disableTitle = NSLocalizedString("Disable", comment: "")
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: cancelTitle, style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: disableTitle, style: .Destructive, handler: { action in
			API.sharedInstance.register(self.appDelegate.allowExplicitContent, successHandler: { (userID, userUUID) in
				self.appDelegate.userID = userID!
				self.appDelegate.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.appDelegate.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.appDelegate.userUUID, forKey: "uuid")
				let skipBtnTitle = NSLocalizedString("NEXT", comment: "")
				self.skipBtn.setTitle(skipBtnTitle, forState: UIControlState.Normal)
				self.delegate?.advanceIntroPageTo(3, reverse: false)
				},
				errorHandler: { (error) in
					self.handleError(error)
			})
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// Notification settings
	@IBAction func permissionBtn(sender: UIButton) {
		if UIApplication.sharedApplication().respondsToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
			permissionBtn.enabled = false
			let appAction = UIMutableUserNotificationAction()
			appAction.identifier = "APP_ACTION"
			let notificationOpenActionTitle = NSLocalizedString("Open in App", comment: "")
			appAction.title = notificationOpenActionTitle
			appAction.activationMode = .Foreground
			appAction.destructive = false
			appAction.authenticationRequired = false
			
			let storeAction = UIMutableUserNotificationAction()
			storeAction.identifier = "STORE_ACTION"
			let notificationPurchaseActionTitle = NSLocalizedString("Purchase", comment: "")
			storeAction.title = notificationPurchaseActionTitle
			storeAction.activationMode = .Foreground
			storeAction.destructive = false
			storeAction.authenticationRequired = false
			
			let preorderAction = UIMutableUserNotificationAction()
			preorderAction.identifier = "PREORDER_ACTION"
			let notificationPreOrderActionTitle = NSLocalizedString("Pre-Order", comment: "")
			preorderAction.title = notificationPreOrderActionTitle
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
		permissionBtn.layer.borderColor = UIColor.whiteColor().CGColor
		permissionBtn.layer.borderWidth = 1
		permissionBtn.layer.cornerRadius = 4
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(Intro02Controller.finishRegister), name: "finishNotificationRegister", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func finishRegister() {
		if appDelegate.userID > 0 && appDelegate.userUUID != nil {
			let skipBtnTitle = NSLocalizedString("NEXT", comment: "")
			skipBtn.setTitle(skipBtnTitle, forState: UIControlState.Normal)
			permissionBtn.enabled = false
			permissionBtn.layer.opacity = 0.5
		}
		if self.delegate != nil {
			self.delegate?.advanceIntroPageTo(3, reverse: false)
		}
	}
	
	func handleError(error: ErrorType) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
		switch (error) {
		case API.Error.NoInternetConnection, API.Error.NetworkConnectionLost:
			alert.title = NSLocalizedString("You're Offline!", comment: "")
			alert.message = NSLocalizedString("Please make sure you are connected to the internet, then try again.", comment: "")
			let alertActionTitle = NSLocalizedString("Settings", comment: "")
			alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = NSLocalizedString("Unable to register", comment: "Unable to register")
			alert.message = NSLocalizedString("Please try again later.", comment: "")
		}
		let title = NSLocalizedString("OK", comment: "")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
}
