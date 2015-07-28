
import UIKit

class AlbumView: UIViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var backgroundImage = UIImageView()
    var album: Album!
    var artist = String()
    var artwork = UIImage()
    var explicit = false
    var timeDiff = Double()
    var timer = NSTimer()
    var progress: Float = 0
    var dateAdded: Double = 0
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistTitleLabel: UILabel!
    @IBOutlet weak var copyrightLabel: UILabel!
    @IBOutlet weak var firstDigitLabel: UILabel!
    @IBOutlet weak var secondDigitLabel: UILabel!
    @IBOutlet weak var thirdDigitLabel: UILabel!
    @IBOutlet weak var firstTimeLabel: UILabel!
    @IBOutlet weak var secondTimeLabel: UILabel!
    @IBOutlet weak var thirdTimeLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var explicitLabel: UILabel!
    
	@IBAction func shareAlbum(sender: AnyObject) {
		shareAlbum()
	}
	
    @IBAction func openiTunes(sender: AnyObject) {
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: album!.iTunesURL)!) {
            UIApplication.sharedApplication().openURL(NSURL(string: album!.iTunesURL)!)
        }
    }
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dbArtwork = AppDB.sharedInstance.getArtwork(album.artwork) {
            artwork = dbArtwork
        }
        albumArtwork.image = artwork
		albumArtwork.layer.masksToBounds = true
		albumArtwork.layer.cornerRadius = 2.0
        artist = AppDB.sharedInstance.getAlbumArtist(Int32(album.ID))
        artistTitleLabel.text = artist
        albumTitleLabel.text = album.title
        copyrightLabel.text = album.copyright
        if !explicit { explicitLabel.hidden = true }
        timeDiff = album.releaseDate - NSDate().timeIntervalSince1970
        if timeDiff > 0 {
            dateAdded = AppDB.sharedInstance.getAlbumDateAdded(Int32(album.ID))
            progress = album.getProgress(dateAdded)
            progressBar.setProgress(progress, animated: false)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        } else {
            progressBar.hidden = true
        }
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("shareAlbum"))
        doubleTapGesture.numberOfTapsRequired = 2
        albumArtwork.addGestureRecognizer(doubleTapGesture)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.timer.invalidate()
    }
    
    func shareAlbum () {
        let firstActivityItem = "\(album.title) by \(artist)  - \(album.iTunesURL)"
        let activityViewController = UIActivityViewController(activityItems: [firstActivityItem], applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
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
        progressBar.setProgress(progress, animated: true)
    }
    
    func component (x: Double, v: Double) -> Double {
        return floor(x / v)
    }
    
    func formatNumber (n: Double) -> String {
        let stringNumber = String(stringInterpolationSegment: Int(n))
        return n < 10 ? ("0\(stringNumber)") : stringNumber
    }
}