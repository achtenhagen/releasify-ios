//
//  Intro04Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/23/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro04Controller: UIViewController {
	
	weak var delegate: IntroPageDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	@IBAction func finishIntro(sender: UIButton) {
		UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AppController") as! UINavigationController
	}
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
    }
}
