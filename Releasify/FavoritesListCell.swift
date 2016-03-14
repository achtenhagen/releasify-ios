//
//  FavoritesListCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/12/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class FavoritesListCell: UITableViewCell {
	
	@IBOutlet var artwork: UIImageView!
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var albumTitle: UILabel!
	@IBOutlet var artistTitle: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		artwork.layer.cornerRadius = 2
		artwork.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
