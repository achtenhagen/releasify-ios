//
//  SubscriptionCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 12/6/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionCell: UITableViewCell {
	
	@IBOutlet var subscriptionImage: UIImageView!
	@IBOutlet var subscriptionTitle: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
	
	override func layoutIfNeeded() {
		super.layoutIfNeeded()
		subscriptionImage.layer.masksToBounds = true
		subscriptionImage.layer.borderColor = UIColor.whiteColor().CGColor
		subscriptionImage.layer.borderWidth = 2
		subscriptionImage.layer.cornerRadius = subscriptionImage.bounds.height / 2
	}
}
