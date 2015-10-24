//
//  Intro02Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro02Controller: UIViewController {
	
	var delegate: IntroPageDelegate?

	@IBAction func skipButtonPressed(sender: UIButton) {
		advanceIntroPageTo(2)
	}
	
	@IBAction func permissionBtn(sender: UIButton) {
		
		// MARK: - Notification settings
		if UIApplication.sharedApplication().respondsToSelector("registerUserNotificationSettings:") {
			
			let appAction = UIMutableUserNotificationAction()
			appAction.identifier = "APP_ACTION"
			appAction.title = "View in App"
			appAction.activationMode = .Foreground
			appAction.destructive = false
			appAction.authenticationRequired = false
			
			let storeAction = UIMutableUserNotificationAction()
			storeAction.identifier = "STORE_ACTION"
			switch UIDevice.currentDevice().systemVersion.compare("8.4.0", options: .NumericSearch) {
			case .OrderedSame, .OrderedDescending:
				storeAction.title = " MUSIC"
			case .OrderedAscending:
				storeAction.title = "Buy on iTunes"
			}
			storeAction.activationMode = .Foreground
			storeAction.destructive = false
			storeAction.authenticationRequired = false
			
			let defaultCategory = UIMutableUserNotificationCategory()
			defaultCategory.identifier = "DEFAULT_CATEGORY"
			let remoteCategory = UIMutableUserNotificationCategory()
			remoteCategory.identifier = "REMOTE_CATEGORY"
			
			let defaultActions = [appAction, storeAction]
			let remoteActions  = [appAction]
			
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension Intro02Controller: IntroPageDelegate {
	func advanceIntroPageTo(index: Int) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(2)
		}
	}
	
	func finishIntro(completed: Bool) {
		if delegate != nil {
			delegate?.finishIntro(false)
		}
	}
}