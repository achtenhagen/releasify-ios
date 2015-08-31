
import UIKit

class AlbumDetailController: UIViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var album: Album!
    var artist = String()
    var artwork = UIImage()
    var timeDiff = Double()
    var timer = NSTimer()
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
	@IBOutlet var detailContainer: UIView!
	@IBOutlet weak var detailContainerTopConstraint: NSLayoutConstraint!
	
	@IBAction func shareAlbum(sender: AnyObject) {
		shareAlbum()
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let dbArtwork = AppDB.sharedInstance.getArtwork(album.artwork) {
            artwork = dbArtwork
        }
		
        albumArtwork.image = artwork
		albumArtwork.layer.masksToBounds = true
		albumArtwork.layer.cornerRadius = 2.0
        artist = AppDB.sharedInstance.getAlbumArtist(album.ID)
		navigationItem.title = artist
        albumTitle.text = album.title
		albumTitle.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
		albumTitle.textContainer.lineFragmentPadding = 0;
        copyrightLabel.text = album.copyright
        timeDiff = album.releaseDate - NSDate().timeIntervalSince1970
        if timeDiff > 0 {
            dateAdded = AppDB.sharedInstance.getAlbumDateAdded(album.ID)
			progressBar.progress = album.getProgress(dateAdded)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
		} else {
			progressBar.hidden = true
		}
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("shareAlbum"))
        doubleTapGesture.numberOfTapsRequired = 2
        albumArtwork.addGestureRecognizer(doubleTapGesture)
		
		switch UIScreen.mainScreen().bounds.width {
			// iPhone 6
		case 375:
			detailContainerTopConstraint.constant = 45
			// iPhone 6 Plus
		case 414:
			detailContainerTopConstraint.constant = 60
		default:
			detailContainerTopConstraint.constant = 15
		}
		
		if AppDB.sharedInstance.getArtwork(album.artwork + "_large") == nil {
			let albumURL = "https://releasify.me/static/artwork/music/\(album.artwork)_large.jpg"
			if let checkedURL = NSURL(string: albumURL) {
				let request = NSURLRequest(URL: checkedURL)
				UIApplication.sharedApplication().networkActivityIndicatorVisible = true
				NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
					if error == nil {
						if let HTTPResponse = response as? NSHTTPURLResponse {
							println("HTTP status code: \(HTTPResponse.statusCode)")
							if HTTPResponse.statusCode == 200 {
								let image = UIImage(data: data)
								AppDB.sharedInstance.addArtwork(self.album.artwork + "_large", artwork: image!)
								self.albumArtwork.image = image
								println("Successfully downloaded HD artwork.")
							}
						}
					}
					UIApplication.sharedApplication().networkActivityIndicatorVisible = false
				})
			}
		} else {
			albumArtwork.image = AppDB.sharedInstance.getArtwork(album.artwork + "_large")
		}
		
		// Background gradient
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    override func viewDidDisappear(animated: Bool) {
        timer.invalidate()
    }
    
    func shareAlbum () {
        let shareActivityItem = "\(album.title) by \(artist)  - \(album.iTunesURL)"
        let activityViewController = UIActivityViewController(activityItems: [shareActivityItem], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func update () {
        timeLeft(album.releaseDate - NSDate().timeIntervalSince1970)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        timer.invalidate()
    }
    
    func timeLeft(timeDiff: Double) {
        
        var weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
        var days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
        var hours   = component(Double(timeDiff),      v: 60 * 60) % 24
        var minutes = component(Double(timeDiff),           v: 60) % 60
        var seconds = component(Double(timeDiff),            v: 1) % 60
        
        if Int(weeks) > 0 {
            firstDigitLabel.text = String(stringInterpolationSegment: formatNumber(weeks))
            firstTimeLabel.text = "weeks"
            secondDigitLabel.text = String(stringInterpolationSegment: formatNumber(days))
            secondTimeLabel.text = "days"
            thirdDigitLabel.text = String(stringInterpolationSegment: formatNumber(hours))
            thirdTimeLabel.text = "hours"
        } else if Int(days) > 0 && Int(days) <= 7 {
            firstDigitLabel.text = String(stringInterpolationSegment: formatNumber(days))
            firstTimeLabel.text = "days"
            secondDigitLabel.text = String(stringInterpolationSegment: formatNumber(hours))
            secondTimeLabel.text = "hours"
            thirdDigitLabel.text = String(stringInterpolationSegment: formatNumber(minutes))
            thirdTimeLabel.text = "minutes"
        } else if Int(hours) > 0 && Int(hours) <= 24 {
            firstDigitLabel.text = String(stringInterpolationSegment: formatNumber(hours))
            firstTimeLabel.text = "hours"
            secondDigitLabel.text = String(stringInterpolationSegment: formatNumber(minutes))
            secondTimeLabel.text = "minutes"
            thirdDigitLabel.text = String(stringInterpolationSegment: formatNumber(seconds))
            thirdTimeLabel.text = "seconds"
        } else if Int(minutes) > 0 && Int(minutes) <= 60 {
            firstDigitLabel.text = String("00")
            firstTimeLabel.text = "hours"
            secondDigitLabel.text = String(stringInterpolationSegment: formatNumber(minutes))
            secondTimeLabel.text = "minutes"
            thirdDigitLabel.text = String(stringInterpolationSegment: formatNumber(seconds))
            thirdTimeLabel.text = "seconds"
        } else if Int(seconds) > 0 && Int(seconds) <= 60 {
            firstDigitLabel.text = String("00")
            firstTimeLabel.text = "hours"
            secondDigitLabel.text = "00"
            secondTimeLabel.text = "minutes"
            thirdDigitLabel.text = String(stringInterpolationSegment: formatNumber(seconds))
            thirdTimeLabel.text = "seconds"
        }
        progress = album.getProgress(dateAdded)
		progressBar.progress = progress
    }
    
    func component (x: Double, v: Double) -> Double {
        return floor(x / v)
    }
    
    func formatNumber (n: Double) -> String {
        let stringNumber = String(stringInterpolationSegment: Int(n))
        return n < 10 ? ("0\(stringNumber)") : stringNumber
    }
}