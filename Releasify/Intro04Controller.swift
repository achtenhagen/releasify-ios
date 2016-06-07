//
//  Intro04Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/23/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro04Controller: UIViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	weak var delegate: IntroPageDelegate?

	@IBOutlet weak var finishIntroBtn: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func finishIntro(sender: UIButton) {
		if appDelegate.userID == 0 {
			let title = NSLocalizedString("ALERT_CONTINUE_WITHOUT_NOTIFICATIONS_TITLE", comment: "The title for the alert controller")
			let message = NSLocalizedString("ALERT_CONTINUE_WITHOUT_NOTIFICATIONS_MESSAGE", comment: "The message for the alert controller")
			let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
			let alertFirstActionTitle = NSLocalizedString("ALERT_ACTION_NO", comment: "The title for the first alert controller action")
			alert.addAction(UIAlertAction(title: alertFirstActionTitle, style: .Cancel, handler: { (action) in
				if self.delegate != nil {
					self.delegate?.advanceIntroPageTo(2, reverse: true)
				}
			}))
			let alertSecondActionTitle = NSLocalizedString("ALERT_ACTION_YES", comment: "The title for the second alert controller action")
			alert.addAction(UIAlertAction(title: alertSecondActionTitle, style: .Destructive, handler: { (action) in
				API.sharedInstance.register(self.appDelegate.allowExplicitContent, successHandler: { (userID, userUUID) in
					self.appDelegate.userID = userID!
					self.appDelegate.userUUID = userUUID
					NSUserDefaults.standardUserDefaults().setInteger(self.appDelegate.userID, forKey: "ID")
					NSUserDefaults.standardUserDefaults().setValue(self.appDelegate.userUUID, forKey: "uuid")
					self.performSegueWithIdentifier("FirstRunSegue", sender: self)
					},
					errorHandler: { (error) in
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
				})
			}))
			self.presentViewController(alert, animated: true, completion: nil)
		} else {
			performSegueWithIdentifier("FirstRunSegue", sender: self)
		}
	}
}
