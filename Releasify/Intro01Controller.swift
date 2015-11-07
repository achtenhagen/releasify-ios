//
//  Intro01Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class Intro01Controller: UIViewController {
	
	weak var delegate: IntroPageDelegate?

	@IBOutlet weak var labelTopLayoutConstraint: NSLayoutConstraint!
	@IBOutlet weak var getStartedButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
		print(view.bounds)
		if view.bounds.height == 480 {
			labelTopLayoutConstraint.constant = 80
		}
    }
	
	@IBAction func getStartedButtonPressed(sender: UIButton) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(2, reverse: false)
		}
	}
	
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}