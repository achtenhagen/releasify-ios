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
	
	override func viewDidAppear(animated: Bool) {
		if appDelegate.userID == 0 {
			finishIntroBtn.enabled = false
			finishIntroBtn.layer.opacity = 0.5
		} else {
			finishIntroBtn.enabled = true
			finishIntroBtn.layer.opacity = 1
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func finishIntro(sender: UIButton) {
		performSegueWithIdentifier("FirstRunSegue", sender: self)
	}
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
    }
}
