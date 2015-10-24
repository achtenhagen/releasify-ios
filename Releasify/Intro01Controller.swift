//
//  Intro01Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro01Controller: UIViewController {
	
	var delegate: IntroPageDelegate?
	
	@IBOutlet weak var getStartedButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
    }
	
	@IBAction func getStartedButtonPressed(sender: UIButton) {
		advanceIntroPageTo(1)
	}
	
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension Intro01Controller: IntroPageDelegate {
	func advanceIntroPageTo(index: Int) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(1)
		}
	}
	
	func finishIntro(completed: Bool) {
		if delegate != nil {
			delegate?.finishIntro(false)
		}
	}
}