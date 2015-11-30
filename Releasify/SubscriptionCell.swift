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
		subscriptionArtwork.layer.masksToBounds = true
		switch UIScreen.mainScreen().bounds.width {
		case 375:
			subscriptionArtwork.layer.cornerRadius = 75
		case 414:
			subscriptionArtwork.layer.cornerRadius = 85
		default:
			subscriptionArtwork.layer.cornerRadius = 60
		}
		subscriptionArtwork.layer.borderColor = UIColor.whiteColor().CGColor
		subscriptionArtwork.layer.borderWidth = 4
	}
}