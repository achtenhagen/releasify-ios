
import UIKit

class SubscriptionCell: UITableViewCell {

    @IBOutlet weak var artistImg: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        artistImg.layer.masksToBounds = true
        artistImg.layer.cornerRadius = artistImg.bounds.width / 2.0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}