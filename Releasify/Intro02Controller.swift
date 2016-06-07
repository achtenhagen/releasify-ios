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
		let title = NSLocalizedString("ALERT_DISABLE_NOTIFICATION_TITLE", comment: "The title for the alert controller")
		let message = NSLocalizedString("ALERT_DISABLE_NOTIFICATION_MESSAGE", comment: "The message for the alert controller")
		let cancelTitle = NSLocalizedString("ALERT_ACTION_CANCEL", comment: "The title for the first alert controller action")
		let disableTitle = NSLocalizedString("ALERT_ACTION_DISABLE", comment: "The title for the second alert controller action")
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: cancelTitle, style: .Cancel, handler: nil))
		alert.addAction(UIAlertAction(title: disableTitle, style: .Destructive, handler: { action in
			API.sharedInstance.register(self.appDelegate.allowExplicitContent, successHandler: { (userID, userUUID) in
				self.appDelegate.userID = userID!
				self.appDelegate.userUUID = userUUID
				NSUserDefaults.standardUserDefaults().setInteger(self.appDelegate.userID, forKey: "ID")
				NSUserDefaults.standardUserDefaults().setValue(self.appDelegate.userUUID, forKey: "uuid")
				let skipBtnTitle = NSLocalizedString("SKIP_BUTTON_TITLE", comment: "The title for the skip button")
				self.skipBtn.setTitle(skipBtnTitle, forState: UIControlState.Normal)
				self.delegate?.advanceIntroPageTo(3, reverse: false)
				},
				errorHandler: { (error) in
					self.handleError(error)
			})
		}))
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// MARK: - Notification settings
	@IBAction func permissionBtn(sender: UIButton) {
		if UIApplication.sharedApplication().respondsToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
			permissionBtn.enabled = false
			let appAction = UIMutableUserNotificationAction()
			appAction.identifier = "APP_ACTION"
			let notificationOpenActionTitle = NSLocalizedString("NOTIFICATION_SETTINGS_OPEN_IN_APP", comment: "The title for the first notification action")
			appAction.title = notificationOpenActionTitle
			appAction.activationMode = .Foreground
			appAction.destructive = false
			appAction.authenticationRequired = false
			
			let storeAction = UIMutableUserNotificationAction()
			storeAction.identifier = "STORE_ACTION"
			let notificationPurchaseActionTitle = NSLocalizedString("NOTIFICATION_SETTINGS_PURCHASE", comment: "The title for the second notification action")
			storeAction.title = notificationPurchaseActionTitle
			storeAction.activationMode = .Foreground
			storeAction.destructive = false
			storeAction.authenticationRequired = false
			
			let preorderAction = UIMutableUserNotificationAction()
			preorderAction.identifier = "PREORDER_ACTION"
			let notificationPreOrderActionTitle = NSLocalizedString("NOTIFICATION_SETTINGS_PREORDER", comment: "The title for the third notification action")
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
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(Intro02Controller.finishRegister), name: "finishNotificationRegister", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func finishRegister() {
		if appDelegate.userID > 0 && appDelegate.userUUID != nil {
			let skipBtnTitle = NSLocalizedString("SKIP_BUTTON_TITLE", comment: "The title for the skip button")
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
			alert.title = NSLocalizedString("ALERT_OFFLINE_TITLE", comment: "The title for the alert controller")
			alert.message = NSLocalizedString("ALERT_OFFLINE_MESSAGE", comment: "The message for the alert controller")
			let alertActionTitle = NSLocalizedString("ALERT_ACTION_SETTINGS", comment: "")
			alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
				UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
			}))
		default:
			alert.title = NSLocalizedString("ALERT_REGISTER_FAIL_TITLE", comment: "The title for the alert controller")
			alert.message = NSLocalizedString("ALERT_REGISTER_FAIL_MESSAGE", comment: "The message for the alert controller")
		}
		let title = NSLocalizedString("ALERT_ACTION_OK", comment: "The title for the alert action")
		alert.addAction(UIAlertAction(title: title, style: .Default, handler: nil))
		self.presentViewController(alert, animated: true, completion: nil)
	}
}
