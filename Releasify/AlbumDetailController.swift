//
//  AlbumDetailController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/29/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit

class AlbumDetailController: UIViewController {
	
	weak var delegate: StreamViewControllerDelegate?
	
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	private var theme: AlbumDetailControllerTheme!
	var canAddToLibrary = false
	var mediaLibrary: MPMediaLibrary!
	var album: Album?
	var indexPath: NSIndexPath?
	var artist: String?
	var artwork: UIImage!
	var timeDiff: Double?
	var timer: NSTimer!
	var progress: Float = 0
	var dateAdded: Double = 0

	@IBOutlet weak var albumArtwork: UIImageView!
	@IBOutlet var artworkOverlay: UIVisualEffectView!
	@IBOutlet var albumTitle: UILabel!
	@IBOutlet var artistTitle: UILabel!
	@IBOutlet weak var copyrightLabel: UILabel!
	@IBOutlet weak var firstDigitLabel: UILabel!
	@IBOutlet weak var secondDigitLabel: UILabel!
	@IBOutlet weak var thirdDigitLabel: UILabel!
	@IBOutlet weak var firstTimeLabel: UILabel!
	@IBOutlet weak var secondTimeLabel: UILabel!
	@IBOutlet weak var thirdTimeLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	@IBOutlet weak var detailContainer: UIView!
	@IBOutlet var buyBtn: UIButton!
	@IBOutlet var favoriteBtn: UIButton!
	@IBOutlet var shareBtn: UIButton!

	// Dynamic constraints (default values correspond to iPhone 6)
	@IBOutlet var leftDigitLeadingConstraint: NSLayoutConstraint!	   // 56
	@IBOutlet var rightDigitLeadingConstraint: NSLayoutConstraint!	   // 56
	@IBOutlet var leftTimeLabelLeadingConstraint: NSLayoutConstraint!  // 32
	@IBOutlet var rightTimeLabelLeadingConstraint: NSLayoutConstraint! // 32
	@IBOutlet var buyBtnTopConstraint: NSLayoutConstraint!			   // 60
	@IBOutlet var buyBtnLeadingConstraint: NSLayoutConstraint!		   // 50
	@IBOutlet var favoriteBtnTopConstraint: NSLayoutConstraint!		   // 67
	@IBOutlet var shareBtnTopConstraint: NSLayoutConstraint!		   // 67
	@IBOutlet var buyBtnTrailingConstraint: NSLayoutConstraint!		   // 50
	@IBOutlet var copyrightLabelTopConstraint: NSLayoutConstraint!	   // 70
	
	// Button actions
	@IBAction func buyAlbum(sender: AnyObject) {
		if UIApplication.sharedApplication().canOpenURL(NSURL(string: (self.album?.iTunesUrl)!)!) {
			UIApplication.sharedApplication().openURL(NSURL(string: (self.album?.iTunesUrl)!)!)
		}
	}

	@IBAction func favoriteAlbum(sender: AnyObject) {
		Favorites.sharedInstance.addFavorite(album!)
		Favorites.sharedInstance.save()
		NSNotificationCenter.defaultCenter().postNotificationName("reloadFavList", object: nil, userInfo: nil)
	}

	@IBAction func shareAlbum(sender: AnyObject) {
		shareAlbum()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		theme = AlbumDetailControllerTheme(style: appDelegate.theme.style)
		
		// Check if remote artwork present, else load local file, else use placeholder
		if artwork == nil {
			if let dbArtwork = AppDB.sharedInstance.getArtwork(album!.artwork) {
				artwork = dbArtwork
			} else {
				let filename = theme.style == .dark ? "icon_artwork_dark" : "icon_artwork_light"
				artwork = UIImage(named: filename)!
			}
		}

		// Dynamic constraints to supported other screen sizes
		switch UIScreen.mainScreen().bounds.height {
		case 568: // iPhone 5
			leftDigitLeadingConstraint.constant = 48
			rightDigitLeadingConstraint.constant = leftDigitLeadingConstraint.constant
			leftTimeLabelLeadingConstraint.constant = 24
			rightTimeLabelLeadingConstraint.constant = leftTimeLabelLeadingConstraint.constant
			favoriteBtnTopConstraint.constant = 47
			shareBtnTopConstraint.constant = favoriteBtnTopConstraint.constant
			buyBtnTopConstraint.constant = 40
			buyBtnLeadingConstraint.constant = 43
			buyBtnTrailingConstraint.constant = buyBtnLeadingConstraint.constant
			copyrightLabelTopConstraint.constant = 45
		case 736: // iPhone 6+
			copyrightLabelTopConstraint.constant = 98
		default:
			break
		}

		// Set album artwork
		albumArtwork.image = artwork
		albumArtwork.layer.masksToBounds = true
		albumArtwork.layer.cornerRadius = 2.0
		artist = AppDB.sharedInstance.getAlbumArtist(album!.ID)!
		artistTitle.text = artist
		albumTitle.text = album!.title
		copyrightLabel.text = album!.copyright

		// Artwork overlay
		artworkOverlay.layer.masksToBounds = true
		artworkOverlay.layer.cornerRadius = 2.0

		// Theme settings
		albumTitle.textColor = theme.albumTitleColor
		artistTitle.textColor = theme.artistTitleColor
		copyrightLabel.textColor = theme.footerLabelColor
		progressBar.trackTintColor = theme.progressBarBackTintColor
		firstDigitLabel.textColor = theme.digitLabelColor
		secondDigitLabel.textColor = theme.digitLabelColor
		thirdDigitLabel.textColor = theme.digitLabelColor
		firstTimeLabel.textColor = theme.timeLabelColor
		secondTimeLabel.textColor = theme.timeLabelColor
		thirdTimeLabel.textColor = theme.timeLabelColor

		// Buy button
		buyBtn.layer.cornerRadius = 4
		buyBtn.layer.borderColor = theme.globalTintColor.CGColor
		buyBtn.layer.borderWidth = 1
		
		// Configure things based on album availability
		timeDiff = album!.releaseDate - NSDate().timeIntervalSince1970
		if timeDiff > 0 {
			self.navigationController?.navigationBar.shadowImage = UIImage()			
			dateAdded = AppDB.sharedInstance.getAlbumDateAdded(album!.ID)!
			progressBar.progress = album!.getProgressSinceDate(dateAdded)
			buyBtn.setTitle("Pre-Order", forState: .Normal)
			buyBtn.tintColor = theme.preOrderBtnColor
			buyBtn.layer.borderColor = theme.preOrderBtnColor.CGColor
			if theme.style == .dark {
				favoriteBtn.setImage(UIImage(named: "icon_favorite_pre"), forState: .Normal)
				shareBtn.setImage(UIImage(named: "icon_share_pre"), forState: .Normal)
			}
			timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
		} else {
			if theme.style == .light {
				self.navigationController?.navigationBar.shadowImage = UIImage(named: "navbar_shadow")
			}
			progressBar.hidden = true			
			artworkOverlay.hidden = true
		}
		
		// Triple tap gesture to re-download artwork
		let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(AlbumDetailController.downloadArtwork as (AlbumDetailController) -> () -> ()))
		tripleTapGesture.numberOfTapsRequired = 3
		albumArtwork.addGestureRecognizer(tripleTapGesture)

		// Fetch artwork if not available
		if AppDB.sharedInstance.getArtwork(album!.artwork) == nil {
			downloadArtwork()
		} else {
			albumArtwork.image = AppDB.sharedInstance.getArtwork(album!.artwork)
			albumArtwork.contentMode = .ScaleToFill
		}
		
		// Insert background gradient depending on theme
		if theme.style == .dark {
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
		}

		// Check users media library capabilities
		if #available(iOS 9.3, *) {
			if SKCloudServiceController.authorizationStatus() == .Authorized {
				let controller = SKCloudServiceController()
				controller.requestCapabilitiesWithCompletionHandler { (capability, error) in
					if capability.rawValue >= 256 {
						self.canAddToLibrary = true
					}
				}
			}
		}
	}

	override func viewDidDisappear(animated: Bool) {
		if timer != nil {
			timer.invalidate()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		timer.invalidate()
	}

	// Download album artwork
	func downloadArtwork() {
		guard let url = album?.artworkUrl else { return }
		API.sharedInstance.fetchArtwork(url, successHandler: { (artwork) in
				self.albumArtwork.contentMode = .ScaleToFill
				self.albumArtwork.image = artwork
				AppDB.sharedInstance.addArtwork(self.album!.artwork, artwork: artwork!)				
			}, errorHandler: {
				let alert = UIAlertController(title: "Error", message: "Failed to download album artwork.", preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	@available(iOS 9.0, *)
	override func previewActionItems() -> [UIPreviewActionItem] {
		var buyTitle = "Pre-Order"
		if timeDiff <= 0 {
			buyTitle = canAddToLibrary ? "Add to Library..." : "Purchase"
		}
		// 3D Touch purchase action
		let purchaseAction = UIPreviewAction(title: buyTitle, style: .Default) { (action, viewController) -> Void in
			if #available(iOS 9.3, *) {
				if self.canAddToLibrary {
//					self.mediaLibrary = MPMediaLibrary()
//					self.mediaLibrary.addItemWithProductID("255991760", completionHandler: { (entity, error) in
//						print(entity)
//					})
				}
			} else {
				if UIApplication.sharedApplication().canOpenURL(NSURL(string: (self.album?.iTunesUrl)!)!) {
					UIApplication.sharedApplication().openURL(NSURL(string: (self.album?.iTunesUrl)!)!)
				}
			}
		}
		// 3D Touch favorites action
		let favoriteAction = UIPreviewAction(title: "Add to Favorites...", style: .Default, handler: { (action, viewController) -> Void in
			Favorites.sharedInstance.addFavorite(self.album!)
		})
		return [purchaseAction, favoriteAction]
	}
	
	// MARK: - Handle album share sheet
	func shareAlbum() {
		let shareActivityItem = "Buy this album on iTunes:\n\(album!.iTunesUrl)"
		let activityViewController = UIActivityViewController(activityItems: [shareActivityItem], applicationActivities: nil)
		self.presentViewController(activityViewController, animated: true, completion: nil)
	}
	
	// MARK: - Selector action for timer to update progress
	func update() {
		timeLeft(album!.releaseDate - NSDate().timeIntervalSince1970)
	}
	
	// MARK: - Compute remaining time
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
		progress = album!.getProgressSinceDate(dateAdded)
		progressBar.progress = progress
	}
	
	// MARK: - Compute the floor of 2 numbers
	func component (x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	// MARK: - Format number to string type
	func formatNumber (n: Double) -> String {
		let stringNumber = String(Int(n))
		return n < 10 ? ("0\(stringNumber)") : stringNumber
	}
}

// MARK: - Theme Extension
private class AlbumDetailControllerTheme: Theme {
	var progressBarBackTintColor: UIColor!
	var albumTitleColor: UIColor!
	var artistTitleColor: UIColor!
	var timeLabelColor: UIColor!
	var digitLabelColor: UIColor!
	var footerLabelColor: UIColor!
	var preOrderBtnColor: UIColor!
	
	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .dark:
			progressBarBackTintColor = UIColor(red: 0, green: 52/255, blue: 72/255, alpha: 1)
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			digitLabelColor = UIColor.whiteColor()
			timeLabelColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
			preOrderBtnColor = orangeColor
			footerLabelColor = UIColor(red: 141/255, green: 141/255, blue: 141/255, alpha: 0.5)
		case .light:
			progressBarBackTintColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			digitLabelColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			timeLabelColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			preOrderBtnColor = orangeColor
			footerLabelColor = UIColor(red: 141/255, green: 141/255, blue: 141/255, alpha: 1)
		}
	}
}
