//
//  AlbumCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 8/16/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class AlbumCell: UICollectionViewCell {
	
	@IBOutlet weak var albumArtwork: UIImageView!
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var containerViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var albumTitle: UILabel!
	@IBOutlet weak var artistTitle: UILabel!	
	@IBOutlet weak var timeLeft: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		albumArtwork.layer.masksToBounds = true
		albumArtwork.layer.cornerRadius = 2
		
		let gradientLayerView = UIView(frame: CGRectMake(0, 0, self.bounds.width, containerView.frame.height))
		let gradient = CAGradientLayer()
		gradient.frame = gradientLayerView.bounds
		gradient.colors = [AnyObject]()
		gradient.colors!.append(UIColor.clearColor().CGColor)

		for index in 0...17 {
			gradient.colors!.append(UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Double(index) * 0.05)).CGColor)
		}

		gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
		containerView.addSubview(gradientLayerView)
		containerView.bringSubviewToFront(timeLeft)	
	}
}