
import UIKit

class ArtistCell: UITableViewCell {


    @IBOutlet weak var albumTitle: UILabel!
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var releaseLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        albumArtwork.layer.masksToBounds = true
        albumArtwork.layer.cornerRadius = 2
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
