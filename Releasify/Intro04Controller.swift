//
//  Intro04Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/23/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro04Controller: UIViewController {
	
	var delegate: IntroPageDelegate?

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

extension Intro04Controller: IntroPageDelegate {
	func advanceIntroPageTo(index: Int) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(1)
		}
	}
	
	func finishIntro(completed: Bool) {
		if delegate != nil {
			delegate?.finishIntro(completed)
		}
	}
}
