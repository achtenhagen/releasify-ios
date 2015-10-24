//
//  Intro03Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro03Controller: UIViewController {
	
	var delegate: IntroPageDelegate?
	
	@IBOutlet weak var importButton: UIButton!
	
	@IBAction func skipButtonPressed(sender: UIButton) {
		finishIntro(true)
	}
	
	@IBAction func importButtonPressed(sender: UIButton) {
		performSegueWithIdentifier("importFromIntroSegue", sender: self)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
    }
}

extension Intro03Controller: IntroPageDelegate {
	func advanceIntroPageTo(index: Int) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(3)
		}
	}
	
	func finishIntro(completed: Bool) {
		if delegate != nil {
			delegate?.finishIntro(false)
		}
	}
}