//
//  Intro03Controller.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 10/20/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class Intro03Controller: UIViewController {
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	weak var delegate: IntroPageDelegate?
	var mediaQuery: MPMediaQuery!
	
	@IBOutlet weak var buttonBottomLayoutConstraint: NSLayoutConstraint!
	@IBOutlet weak var imageTopLayoutConstraint: NSLayoutConstraint!
	@IBOutlet weak var importButton: UIButton!
	
	@IBAction func skipButtonPressed(sender: UIButton) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(4, reverse: false)
		}
	}
	
	@IBAction func importButtonPressed(sender: UIButton) {
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 && appDelegate.userID > 0 {
			performSegueWithIdentifier("importFromIntroSegue", sender: self)
		} else {
			let title = NSLocalizedString("Unable to import!", comment: "")
			let message = NSLocalizedString("You currently have no artists in your media library.", comment: "")
			let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
			let actionTitle = NSLocalizedString("OK", comment: "")
			alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
		if view.bounds.height == 480 {
			buttonBottomLayoutConstraint.constant = 0
			imageTopLayoutConstraint.constant = 20
		}
		if appDelegate.userID == 0 {
			importButton.enabled = false
			importButton.layer.opacity = 0.5
		}
		importButton.layer.borderColor = UIColor.whiteColor().CGColor
		importButton.layer.borderWidth = 1
		importButton.layer.cornerRadius = 4
		mediaQuery = MPMediaQuery.artistsQuery()
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(Intro03Controller.finishIntro), name: "finishIntroStep", object: nil)
    }
	
	override func viewDidAppear(animated: Bool) {
		if appDelegate.userID == 0 {
			importButton.enabled = false
			importButton.layer.opacity = 0.5
		} else {
			importButton.enabled = true
			importButton.layer.opacity = 1
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	func finishIntro () {
		if delegate != nil {
			delegate?.advanceIntroPageTo(4, reverse: false)
		}
	}
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "importFromIntroSegue" {
			let artistPickerController = segue.destinationViewController as! ArtistPicker
			artistPickerController.collection = mediaQuery.collections!
			artistPickerController.isIntro = true
		}
    }
}
