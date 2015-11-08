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
	@IBOutlet weak var artistTitle: UILabel!
	@IBOutlet weak var albumTitle: UILabel!
	@IBOutlet weak var timeLeft: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		layer.masksToBounds = true
		layer.cornerRadius = 4
		
		var gradientLayerView: UIView!
		
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 145, containerView.frame.height))
		case 375:
			gradientLayerView = UIView(frame: CGRectMake(0, 27, 172, containerView.frame.height))
		case 414:
			gradientLayerView = UIView(frame: CGRectMake(0, 47, 192, containerView.frame.height))
		default:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 145, containerView.frame.height))
		}
		
		let gradient = CAGradientLayer()
		gradient.frame = gradientLayerView.bounds
		gradient.colors = [AnyObject]()
		gradient.colors!.append(UIColor.clearColor().CGColor)
		for var i = 0.0; i < 0.85; i += 0.05 {
			gradient.colors!.append(UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(i)).CGColor)
		}
		gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
		containerView.addSubview(gradientLayerView)
		containerView.bringSubviewToFront(progressBar)
		containerView.bringSubviewToFront(timeLeft)
	}
}
