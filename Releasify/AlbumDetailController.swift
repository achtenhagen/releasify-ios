//
//  AlbumDetailController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/29/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AlbumDetailController: UIViewController {
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var album: Album?
	var artist: String?
	var artwork: UIImage!
	var timeDiff: Double?
	var timer: NSTimer!
	var progress: Float = 0
	var dateAdded: Double = 0
	
	@IBOutlet weak var albumArtwork: UIImageView!
	@IBOutlet weak var albumTitle: UITextView!
	@IBOutlet weak var copyrightLabel: UILabel!
	@IBOutlet weak var firstDigitLabel: UILabel!
	@IBOutlet weak var secondDigitLabel: UILabel!
	@IBOutlet weak var thirdDigitLabel: UILabel!
	@IBOutlet weak var firstTimeLabel: UILabel!
	@IBOutlet weak var secondTimeLabel: UILabel!
	@IBOutlet weak var thirdTimeLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	@IBOutlet weak var detailContainer: UIView!
	@IBOutlet weak var labelTopLayoutConstraint: NSLayoutConstraint!
	@IBOutlet weak var detailContainerTopConstraint: NSLayoutConstraint!
	
	@IBAction func shareAlbum(sender: AnyObject) {
		shareAlbum()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let dbArtwork = AppDB.sharedInstance.getArtwork(album!.artwork) else {
			artwork = UIImage(named: "icon_album_placeholder")!
			albumArtwork.contentMode = .Center
			return
		}
		
		artwork = dbArtwork
		albumArtwork.contentMode = .ScaleToFill
		
		albumArtwork.image = artwork
		albumArtwork.layer.masksToBounds = true
		albumArtwork.layer.cornerRadius = 2.0
		artist = AppDB.sharedInstance.getAlbumArtist(album!.ID)!
		navigationItem.title = artist
		albumTitle.text = album!.title
		albumTitle.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
		albumTitle.textContainer.lineFragmentPadding = 0
		copyrightLabel.text = album!.copyright
		timeDiff = album!.releaseDate - NSDate().timeIntervalSince1970
		if timeDiff > 0 {
			dateAdded = AppDB.sharedInstance.getAlbumDateAdded(album!.ID)!
			progressBar.progress = album!.getProgress(dateAdded)
			timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
		} else {
			progressBar.hidden = true
		}
		let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("shareAlbum"))
		doubleTapGesture.numberOfTapsRequired = 2
		albumArtwork.addGestureRecognizer(doubleTapGesture)
		
		switch UIScreen.mainScreen().bounds.height {
		case 667:
			detailContainerTopConstraint.constant = 30
			labelTopLayoutConstraint.constant = 70
		case 736:
			detailContainerTopConstraint.constant = 60
			labelTopLayoutConstraint.constant = 70
		default:
			detailContainerTopConstraint.constant = 15
			labelTopLayoutConstraint.constant = 45
		}
		
		if AppDB.sharedInstance.getArtwork(album!.artwork + "_large") == nil {
			let subDir = (album!.artwork as NSString).substringWithRange(NSRange(location: 0, length: 2))
			let albumURL = "https://releasify.me/static/artwork/music/\(subDir)/\(album!.artwork)_large.jpg"
			if let checkedURL = NSURL(string: albumURL) {
				let request = NSURLRequest(URL: checkedURL)
				UIApplication.sharedApplication().networkActivityIndicatorVisible = true
				NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
					if error == nil {
						if let HTTPResponse = response as? NSHTTPURLResponse {
							if HTTPResponse.statusCode == 200 {
								let image = UIImage(data: data!)
								AppDB.sharedInstance.addArtwork(self.album!.artwork + "_large", artwork: image!)
								self.albumArtwork.contentMode = .ScaleToFill
								self.albumArtwork.image = image
							}
						}
					}
					UIApplication.sharedApplication().networkActivityIndicatorVisible = false
				})
			}
		} else {
			albumArtwork.image = AppDB.sharedInstance.getArtwork(album!.artwork + "_large")
			albumArtwork.contentMode = .ScaleToFill
		}
		
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
	}
	
	override func viewDidDisappear(animated: Bool) {
		if timer != nil {
			timer.invalidate()
		}
	}
	
	@available(iOS 9.0, *)
	override func previewActionItems() -> [UIPreviewActionItem] {
		let purchaseAction = UIPreviewAction(title: "Purchase", style: .Default) { (action, viewController) -> Void in }
		return [purchaseAction]
	}
	
	func shareAlbum () {
		let shareActivityItem = "\(album!.title) by \(artist)  - \(album!.iTunesUrl)"
		let activityViewController = UIActivityViewController(activityItems: [shareActivityItem], applicationActivities: nil)
		presentViewController(activityViewController, animated: true, completion: nil)
	}
	
	func update () {
		timeLeft(album!.releaseDate - NSDate().timeIntervalSince1970)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		timer.invalidate()
	}
	
	func timeLeft(timeDiff: Double) {
		let weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
		let days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
		let hours   = component(Double(timeDiff),      v: 60 * 60) % 24
		let minutes = component(Double(timeDiff),           v: 60) % 60
		let seconds = component(Double(timeDiff),            v: 1) % 60
		
		if Int(weeks) > 0 {
			firstDigitLabel.text = formatNumber(weeks)
			firstTimeLabel.text = "weeks"
			secondDigitLabel.text = formatNumber(days)
			secondTimeLabel.text = "days"
			thirdDigitLabel.text = formatNumber(hours)
			thirdTimeLabel.text = "hours"
		} else if Int(days) > 0 && Int(days) <= 7 {
			firstDigitLabel.text = formatNumber(days)
			firstTimeLabel.text = "days"
			secondDigitLabel.text = formatNumber(hours)
			secondTimeLabel.text = "hours"
			thirdDigitLabel.text = formatNumber(minutes)
			thirdTimeLabel.text = "minutes"
		} else if Int(hours) > 0 && Int(hours) <= 24 {
			firstDigitLabel.text = formatNumber(hours)
			firstTimeLabel.text = "hours"
			secondDigitLabel.text = formatNumber(minutes)
			secondTimeLabel.text = "minutes"
			thirdDigitLabel.text = formatNumber(seconds)
			thirdTimeLabel.text = "seconds"
		} else if Int(minutes) > 0 && Int(minutes) <= 60 {
			firstDigitLabel.text = String("00")
			firstTimeLabel.text = "hours"
			secondDigitLabel.text = formatNumber(minutes)
			secondTimeLabel.text = "minutes"
			thirdDigitLabel.text = formatNumber(seconds)
			thirdTimeLabel.text = "seconds"
		} else if Int(seconds) > 0 && Int(seconds) <= 60 {
			firstDigitLabel.text = String("00")
			firstTimeLabel.text = "hours"
			secondDigitLabel.text = "00"
			secondTimeLabel.text = "minutes"
			thirdDigitLabel.text = formatNumber(seconds)
			thirdTimeLabel.text = "seconds"
		}
		progress = album!.getProgress(dateAdded)
		progressBar.progress = progress
	}
	
	func component (x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	func formatNumber (n: Double) -> String {
		let stringNumber = String(Int(n))
		return n < 10 ? ("0\(stringNumber)") : stringNumber
	}
}
