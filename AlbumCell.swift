
import UIKit

class AlbumCell: UICollectionViewCell {

	@IBOutlet weak var albumArtwork: UIImageView!	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var artistTitle: UILabel!
	@IBOutlet weak var albumTitle: UILabel!
	@IBOutlet weak var timeLeft: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
		var gradientLayerView: UIView!
		
		switch UIScreen.mainScreen().bounds.width {
			// iPhone 4S, 5, 5C & 5S
		case 320:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 145, containerView.frame.height))
			// iPhone 6
		case 375:
			gradientLayerView = UIView(frame: CGRectMake(0, 27, 172, containerView.frame.height))
			// iPhone 6 Plus
		case 414:
			gradientLayerView = UIView(frame: CGRectMake(0, 47, 192, containerView.frame.height))
		default:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 145, containerView.frame.height))
		}
		
		// Shadow overlay
		var gradient: CAGradientLayer = CAGradientLayer()
		gradient.frame = gradientLayerView.bounds
		gradient.colors = [AnyObject]()
		gradient.colors.append(UIColor.clearColor().CGColor)
		for var i = 0.0; i < 0.85; i += 0.05 {
			gradient.colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(i)).CGColor)
		}
		gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
		containerView.addSubview(gradientLayerView)
		containerView.bringSubviewToFront(progressBar)
		containerView.bringSubviewToFront(timeLeft)
    }
}