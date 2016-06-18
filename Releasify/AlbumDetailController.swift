//
//  AlbumDetailController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 4/29/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumDetailController: UIViewController {
	
	weak var delegate: StreamViewControllerDelegate?

	private var theme: AlbumDetailControllerTheme!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var canAddToFavorites = true
	var mediaLibrary: MPMediaLibrary!
	var album: Album?
	var indexPath: NSIndexPath?
	var artist: String?
	var artwork: UIImage!
	var timeDiff: Double?
	var timer: NSTimer!
	var progress: Float = 0
	var dateAdded: Double = 0
	var isFavorite = false

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
		if !isFavorite {
			addFavorite()
		} else {
			removeFavorite()
		}
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
				let filename = theme.style == .Dark ? "icon_artwork_dark" : "icon_artwork"
				artwork = UIImage(named: filename)!
			}
		}

		// Dynamic constraints to supported various screen sizes
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
		albumArtwork.layer.cornerRadius = 2
		artistTitle.text = artist
		albumTitle.text = album!.title
		copyrightLabel.text = album!.copyright

		// Artwork overlay
		artworkOverlay.layer.masksToBounds = true
		artworkOverlay.layer.cornerRadius = 2
		artworkOverlay.effect = theme.style == .Dark ? UIBlurEffect(style: .Dark) : UIBlurEffect(style: .Light)

		// Theme settings
		progressBar.trackTintColor = theme.progressBarBackTintColor
		albumTitle.textColor = theme.albumTitleColor
		artistTitle.textColor = theme.artistTitleColor
		buyBtn.tintColor = theme.buyBtnColor
		copyrightLabel.textColor = theme.footerLabelColor

		// Favorites button enabled state
		favoriteBtn.enabled = canAddToFavorites

		// Buy button
		buyBtn.layer.borderColor = theme.globalTintColor.CGColor
		buyBtn.layer.borderWidth = 1
		buyBtn.layer.cornerRadius = 4
		if appDelegate.canAddToLibrary {
			buyBtn.setTitle(NSLocalizedString("Add to Library", comment: ""), forState: .Normal)
		}
		
		// Configure things based on album availability
		timeDiff = album!.releaseDate - NSDate().timeIntervalSince1970
		if timeDiff > 0 {
			self.navigationController?.navigationBar.shadowImage = UIImage()			
			dateAdded = AppDB.sharedInstance.getAlbumDateAdded(album!.ID)!
			progressBar.progress = album!.getProgressSinceDate(dateAdded)
			buyBtn.setTitle(NSLocalizedString("Pre-Order", comment: ""), forState: .Normal)
			timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
		} else {
			if theme.style == .Light {
				self.navigationController?.navigationBar.shadowImage = UIImage(named: "navbar_shadow")
			}
			progressBar.hidden = true			
			artworkOverlay.hidden = true
		}

		// Check if album has already been added to favorites
		if Favorites.sharedInstance.isFavorite(album!) {
			isFavorite = true
			let btnImg = theme.style == .Dark ? "icon_favorite_dark_filled" : "icon_favorite_filled"
			favoriteBtn.setImage(UIImage(named: btnImg), forState: .Normal)
		} else {
			let btnImg = theme.style == .Dark ? "icon_favorite_dark" : "icon_favorite"
			favoriteBtn.setImage(UIImage(named: btnImg), forState: .Normal)
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
		
		// Theme customizations
		if theme.style == .Dark {
			let btnImg = theme.style == .Dark ? "icon_share_dark" : "icon_share"
			shareBtn.setImage(UIImage(named: btnImg), forState: .Normal)
			let gradient = theme.gradient()
			gradient.frame = self.view.bounds
			self.view.layer.insertSublayer(gradient, atIndex: 0)
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
				let title =  NSLocalizedString("Error", comment: "")
				let message = NSLocalizedString("Failed to download album artwork.", comment: "")
				let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
				let alertActionTitle = NSLocalizedString("OK", comment: "")
				alert.addAction(UIAlertAction(title: alertActionTitle, style: .Default, handler: nil))
				self.presentViewController(alert, animated: true, completion: nil)
		})
	}

	// MARK: - Add album to favorites list
	func addFavorite() {
		Favorites.sharedInstance.add(album!)
		Favorites.sharedInstance.save()
		isFavorite = true
		let favImage = theme.style == .Dark ? "icon_favorite_dark_filled" : "icon_favorite_filled"
		favoriteBtn.setImage(UIImage(named: favImage), forState: .Normal)
		NSNotificationCenter.defaultCenter().postNotificationName("reloadFavList", object: nil, userInfo: nil)
	}

	// MARK: - Remove album from favorites list
	func removeFavorite() {
		Favorites.sharedInstance.removeFavoriteIfExists(album!.ID)
		Favorites.sharedInstance.save()
		isFavorite = false
		let favImage = theme.style == .Dark ? "icon_favorite_dark" : "icon_favorite"
		favoriteBtn.setImage(UIImage(named: favImage), forState: .Normal)
		NSNotificationCenter.defaultCenter().postNotificationName("reloadFavList", object: nil, userInfo: nil)
	}
	
	@available(iOS 9.0, *)
	override func previewActionItems() -> [UIPreviewActionItem] {
		var buyTitle = NSLocalizedString("Pre-Order", comment: "")
		if timeDiff <= 0 {
			let s1 = NSLocalizedString("Add to Library", comment: "")
			let s2 = NSLocalizedString("Purchase", comment: "")
			buyTitle = appDelegate.canAddToLibrary ? s1 : s2
		}
		// 3D Touch purchase action
		let purchaseAction = UIPreviewAction(title: buyTitle, style: .Default) { (action, viewController) -> Void in
			if UIApplication.sharedApplication().canOpenURL(NSURL(string: (self.album?.iTunesUrl)!)!) {
				UIApplication.sharedApplication().openURL(NSURL(string: (self.album?.iTunesUrl)!)!)
			}
		}
		// 3D Touch favorites action
		let favoritesActionTitle = isFavorite == true ? NSLocalizedString("Remove from Favorites", comment: "") : NSLocalizedString("Add to Favorites", comment: "")
		let favoriteAction = UIPreviewAction(title: favoritesActionTitle, style: .Default, handler: { (action, viewController) -> Void in
			if !self.isFavorite {
				self.addFavorite()
			} else {
				self.removeFavorite()
			}
		})
		return [purchaseAction, favoriteAction]
	}
	
	// MARK: - Handle album share sheet
	func shareAlbum() {
		let message = NSLocalizedString("Buy this album on iTunes", comment: "")
		let shareActivityItem = "\(message):\n\(album!.iTunesUrl)"
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
			firstTimeLabel.text = NSLocalizedString("weeks", comment: "")
			secondDigitLabel.text = formatNumber(days)
			secondTimeLabel.text = NSLocalizedString("days", comment: "")
			thirdDigitLabel.text = formatNumber(hours)
			thirdTimeLabel.text = NSLocalizedString("hours", comment: "")
		} else if Int(days) > 0 && Int(days) <= 7 {
			firstDigitLabel.text = formatNumber(days)
			firstTimeLabel.text = NSLocalizedString("days", comment: "")
			secondDigitLabel.text = formatNumber(hours)
			secondTimeLabel.text = NSLocalizedString("hours", comment: "")
			thirdDigitLabel.text = formatNumber(minutes)
			thirdTimeLabel.text = NSLocalizedString("minutes", comment: "")
		} else if Int(hours) > 0 && Int(hours) <= 24 {
			firstDigitLabel.text = formatNumber(hours)
			firstTimeLabel.text = NSLocalizedString("hours", comment: "")
			secondDigitLabel.text = formatNumber(minutes)
			secondTimeLabel.text = NSLocalizedString("minutes", comment: "")
			thirdDigitLabel.text = formatNumber(seconds)
			thirdTimeLabel.text = NSLocalizedString("seconds", comment: "")
		} else if Int(minutes) > 0 && Int(minutes) <= 60 {
			firstDigitLabel.text = String("00")
			firstTimeLabel.text = NSLocalizedString("hours", comment: "")
			secondDigitLabel.text = formatNumber(minutes)
			secondTimeLabel.text = NSLocalizedString("minutes", comment: "")
			thirdDigitLabel.text = formatNumber(seconds)
			thirdTimeLabel.text = NSLocalizedString("seconds", comment: "")
		} else if Int(seconds) > 0 && Int(seconds) <= 60 {
			firstDigitLabel.text = String("00")
			firstTimeLabel.text = NSLocalizedString("hours", comment: "")
			secondDigitLabel.text = "00"
			secondTimeLabel.text = NSLocalizedString("minutes", comment: "")
			thirdDigitLabel.text = formatNumber(seconds)
			thirdTimeLabel.text = NSLocalizedString("seconds", comment: "")
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
	var buyBtnColor: UIColor!
	var footerLabelColor: UIColor!
	
	override init (style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			progressBarBackTintColor = UIColor(red: 0, green: 52/255, blue: 72/255, alpha: 1)
			albumTitleColor = UIColor.whiteColor()
			artistTitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			buyBtnColor = globalTintColor
			footerLabelColor = UIColor(red: 141/255, green: 141/255, blue: 141/255, alpha: 0.5)
		case .Light:
			progressBarBackTintColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
			albumTitleColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
			artistTitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			buyBtnColor = globalTintColor
			footerLabelColor = UIColor(red: 141/255, green: 141/255, blue: 141/255, alpha: 1)
		}
	}
}
