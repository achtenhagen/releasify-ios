//
//  StreamCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/5/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class StreamCell: UITableViewCell {
	
	
	@IBOutlet var containerView: UIView!
	@IBOutlet var artistImg: UIImageView!
	@IBOutlet var albumTitle: UILabel!
	@IBOutlet var artistTitle: UILabel!
	@IBOutlet var artwork: UIImageView!
	@IBOutlet var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
		
		containerView.layer.masksToBounds = true
		containerView.layer.cornerRadius = 4
		
		artistImg.layer.masksToBounds = true
		artistImg.layer.cornerRadius = 17.5
		artistImg.layer.borderColor = UIColor.whiteColor().CGColor
		artistImg.layer.borderWidth = 2
		
		artwork.layer.masksToBounds = true
		artwork.layer.cornerRadius = 6
		
		var gradientLayerView: UIView!
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 145, 104))
		case 375:
			gradientLayerView = UIView(frame: CGRectMake(0, 130, 355, 104))
		case 414:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 192, self.frame.height))
		default:
			gradientLayerView = UIView(frame: CGRectMake(0, 0, 145, self.frame.height))
		}
		
		let gradient = CAGradientLayer()
		gradient.frame = gradientLayerView.bounds
		gradient.colors = [AnyObject]()
		gradient.colors!.append(UIColor.clearColor().CGColor)
		for var i = 0.0; i < 1.0; i += 0.05 {
			gradient.colors!.append(UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(i)).CGColor)
		}
		gradient.cornerRadius = 4
		gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
		artwork.addSubview(gradientLayerView)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)		
    }

}
