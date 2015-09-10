//
//  NotificationCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 9/4/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
	
	@IBOutlet weak var artwork: UIImageView!
	@IBOutlet weak var notificationBody: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		artwork.layer.masksToBounds = true
		artwork.layer.cornerRadius = 2
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
	}
}
