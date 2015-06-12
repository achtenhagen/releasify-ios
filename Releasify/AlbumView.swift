
import UIKit

class AlbumView: UIViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var backgroundImage = UIImageView()
    var album: Album!
    var artist = String()
    var artwork = UIImage()
    var explicit = false
    var timeDiff = Int()
    var timer = NSTimer()
    var progress: Float = 0
    var dateAdded = 0
    
    @IBOutlet weak var navBar: UINavigationBar!
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
    @IBOutlet weak var buyBtn: UIBarButtonItem!
    @IBOutlet weak var backgroundView: UIImageView!
    
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
        navBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navBar.shadowImage = UIImage()
        navBar.translucent = true
        artwork = AppDB.sharedInstance.getArtwork(album.artwork)!
        backgroundView.image = artwork
        albumArtwork.image = artwork
        artist = AppDB.sharedInstance.getAlbumArtist(Int32(album.ID))
        artistTitleLabel.text = artist
        albumTitleLabel.text = album.title
        copyrightLabel.text = album.copyright
        if !explicit { explicitLabel.hidden = true }
        timeDiff = album.releaseDate - Int(NSDate().timeIntervalSince1970)
        if timeDiff > 0 {
            dateAdded = AppDB.sharedInstance.getAlbumDateAdded(Int32(album.ID))
            progress = Float((Double(NSDate().timeIntervalSince1970) - Double(dateAdded)) / (Double(album.releaseDate) - Double(dateAdded)))
            progressBar.setProgress(progress, animated: false)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        } else {
            progressBar.hidden = true
        }
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("shareAlbum"))
        doubleTapGesture.numberOfTapsRequired = 2
        albumArtwork.addGestureRecognizer(doubleTapGesture)
        //UIView.animateWithDuration(0.4, delay: 1.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { self.buyLabel.alpha = 0 }, completion: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.timer.invalidate()
    }
    
    func shareAlbum () {
        let firstActivityItem = "\(album.title) by \(artist)  - \(album.iTunesURL)"
        let activityViewController : UIActivityViewController = UIActivityViewController(activityItems: [firstActivityItem], applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func update () {
        timeLeft(album.releaseDate - Int(NSDate().timeIntervalSince1970))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        timer.invalidate()
    }
    
    func timeLeft(timeDiff: Int) {
        
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
        
        progress = Float((Double(NSDate().timeIntervalSince1970) - Double(dateAdded)) / (Double(album.releaseDate) - Double(dateAdded)))
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