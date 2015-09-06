//
//  SearchResultCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/23/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
	
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