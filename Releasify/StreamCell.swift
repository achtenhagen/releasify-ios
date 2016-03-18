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
	@IBOutlet var artworkContainer: UIView!
	@IBOutlet var albumTitle: UILabel!
	@IBOutlet var artistTitle: UILabel!
	@IBOutlet var artwork: UIImageView!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var artworkTopConstraint: NSLayoutConstraint!
	@IBOutlet var artworkBottomConstraint: NSLayoutConstraint!
	
	var label: UILabel!
	let imageParallaxFactor: CGFloat = 20
	var imgBackTopInitial: CGFloat!
	var imgBackBottomInitial: CGFloat!

    override func awakeFromNib() {
        super.awakeFromNib()
		
		artworkContainer.clipsToBounds = true
		artworkContainer.layer.masksToBounds = true
		artworkContainer.layer.cornerRadius = 6
		self.artworkBottomConstraint.constant -= 2 * imageParallaxFactor
		self.imgBackTopInitial = self.artworkTopConstraint.constant
		self.imgBackBottomInitial = self.artworkBottomConstraint.constant
		
		containerView.layer.masksToBounds = true
		containerView.layer.cornerRadius = 4
		
		artistImg.layer.masksToBounds = true
		artistImg.layer.cornerRadius = 17.5
		artistImg.layer.borderColor = UIColor.whiteColor().CGColor
		artistImg.layer.borderWidth = 2
		
		var gradientLayerView: UIView!
		switch UIScreen.mainScreen().bounds.width {
		case 320:
			gradientLayerView = UIView(frame: CGRectMake(0, 130, 320, 104))
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
		for var i = 0.0; i < 0.85; i += 0.05 {
			gradient.colors!.append(UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(i)).CGColor)
		}
		gradient.cornerRadius = 4
		gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
		artworkContainer.addSubview(gradientLayerView)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)		
    }
	
	func addNewItemLabel () {
		if label == nil {
			label = UILabel(frame: CGRect(x: 292, y: 260, width: 50, height: 26))
			label.text = "NEW"
			label.font = UIFont(name: label.font.fontName, size: 12)
			label.textColor = Theme.sharedInstance.orangeColor
			label.textAlignment = NSTextAlignment.Center
			label.layer.masksToBounds = true
			label.layer.cornerRadius = 4
			label.layer.borderWidth = 1
			label.layer.borderColor = Theme.sharedInstance.orangeColor.CGColor
			self.addSubview(label)
		}
	}
	
	func removeNewItemLabel () {
		if label != nil {
			label.removeFromSuperview()
			label = nil
		}
	}
	
	func setBackgroundOffset(offset:CGFloat) {
		let boundOffset = max(0, min(1, offset))
		let pixelOffset = (1 - boundOffset) * 2 * imageParallaxFactor
		self.artworkTopConstraint.constant = self.imgBackTopInitial - pixelOffset
		self.artworkBottomConstraint.constant = self.imgBackBottomInitial + pixelOffset
	}
}
