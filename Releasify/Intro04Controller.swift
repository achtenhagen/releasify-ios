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
		finishIntroBtn.layer.borderColor = UIColor.whiteColor().CGColor
		finishIntroBtn.layer.borderWidth = 1
		finishIntroBtn.layer.cornerRadius = 4
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func finishIntro(sender: UIButton) {
		if appDelegate.userID == 0 {
			let title = NSLocalizedString("Continue without Push Notifications?", comment: "")
			let message = NSLocalizedString("Are you really sure you would like to use Releasify with Push Notifications turned off?", comment: "")
			let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
			let alertFirstActionTitle = NSLocalizedString("No", comment: "")
			alert.addAction(UIAlertAction(title: alertFirstActionTitle, style: .Cancel, handler: { (action) in
				if self.delegate != nil {
					self.delegate?.advanceIntroPageTo(2, reverse: true)
				}
			}))
			let alertSecondActionTitle = NSLocalizedString("Yes", comment: "")
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
							alert.title = NSLocalizedString("You're Offline!", comment: "")
							alert.message = NSLocalizedString("Please make sure you are connected to the internet, then try again.", comment: "")
							let alertActionTitle = NSLocalizedString("Settings", comment: "")
							alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: { (action) in
								UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
							}))
						default:
							alert.title = NSLocalizedString("Unable to register", comment: "")
							alert.message = NSLocalizedString("Please try again later.", comment: "")
						}
						let title = NSLocalizedString("OK", comment: "")
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
