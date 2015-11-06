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
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
			alert.title = "Continue without Push Notifications?"
			alert.message = "Are you really sure you would like to use Releasify with Push Notifications turned off?"
			alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { action in
				if self.delegate != nil {
					self.delegate?.advanceIntroPageTo(2, reverse: true)
				}
			}))
			alert.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { action in
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
							alert.title = "You're Offline!"
							alert.message = "Please make sure you are connected to the internet, then try again."
							alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
								UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
							}))
						default:
							alert.title = "Unable to register!"
							alert.message = "Please try again later."
						}
						alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
						self.presentViewController(alert, animated: true, completion: nil)
				})
			}))
			self.presentViewController(alert, animated: true, completion: nil)
		} else {
			performSegueWithIdentifier("FirstRunSegue", sender: self)
		}
	}
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
    }
}
