
import UIKit

class AlbumCell: UICollectionViewCell {

	@IBOutlet weak var albumArtwork: UIImageView!
	@IBOutlet weak var artistTitle: UILabel!
	@IBOutlet weak var albumTitle: UILabel!
	@IBOutlet weak var timeLeft: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}