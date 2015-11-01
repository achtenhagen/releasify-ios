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
	
	@IBOutlet weak var importButton: UIButton!
	
	@IBAction func skipButtonPressed(sender: UIButton) {
		if delegate != nil {
			delegate?.advanceIntroPageTo(4)
		}
	}
	
	@IBAction func importButtonPressed(sender: UIButton) {
		mediaQuery.groupingType = .AlbumArtist
		if mediaQuery.collections!.count > 0 {
			performSegueWithIdentifier("importFromIntroSegue", sender: self)
		} else {
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
			alert.title = "Unable to import."
			alert.message = "You currently have no artists in your media library."
			alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()
		mediaQuery = MPMediaQuery.artistsQuery()
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
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "importFromIntroSegue" {
			let artistPickerController = segue.destinationViewController as! ArtistsPicker
			artistPickerController.collection = mediaQuery.collections!
		}
    }
}
 