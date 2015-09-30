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
	@IBOutlet weak var optionsBtn: UIButton!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		layer.masksToBounds = true
		layer.cornerRadius = 4
	}
}