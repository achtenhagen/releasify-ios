
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
		
		// Shadow overlay
		var gradientLayerView: UIView = UIView(frame: CGRectMake(0, 0, containerView.bounds.width, containerView.bounds.height))
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