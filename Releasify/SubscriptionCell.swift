//
//  SubscriptionCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 8/20/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SubscriptionCell: UICollectionViewCell {
	
	@IBOutlet weak var subscriptionArtwork: UIImageView!
	@IBOutlet weak var subscriptionTitle: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func layoutIfNeeded() {
		super.layoutIfNeeded()
		subscriptionArtwork.layer.masksToBounds = true
		subscriptionArtwork.layer.borderColor = UIColor.whiteColor().CGColor
		subscriptionArtwork.layer.borderWidth = 4
		subscriptionArtwork.layer.cornerRadius = bounds.width / 2
	}
}