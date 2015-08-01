
import UIKit

class StreamCell: UITableViewCell {

	@IBOutlet weak var albumArtwork: UIImageView!
	@IBOutlet weak var artistLabel: UILabel!
	@IBOutlet weak var albumTitle: UITextView!
	@IBOutlet weak var timeRemainingLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		albumArtwork.layer.masksToBounds = true
		albumArtwork.layer.cornerRadius = 2.0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}