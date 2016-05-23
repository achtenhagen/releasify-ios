//
//  StreamCell.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 2/5/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class StreamCell: UITableViewCell {

	private var theme: Theme!
	let imageParallaxFactor: CGFloat = 20
	var gradientLayerView: UIView!
	var gradient: CAGradientLayer!
	var label: UILabel!
	var imgBackTopInitial: CGFloat!
	var imgBackBottomInitial: CGFloat!
	
	@IBOutlet var containerView: UIView!
	@IBOutlet var artistImg: UIImageView!
	@IBOutlet var artworkContainer: UIView!
	@IBOutlet var albumTitle: UILabel!
	@IBOutlet var artistTitle: UILabel!
	@IBOutlet var artwork: UIImageView!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var artworkTopConstraint: NSLayoutConstraint!
	@IBOutlet var artworkBottomConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

		theme = Theme()
		
		artworkContainer.layer.masksToBounds = true
		artworkContainer.layer.cornerRadius = 6
		artworkBottomConstraint.constant -= 2 * imageParallaxFactor
		imgBackTopInitial = self.artworkTopConstraint.constant
		imgBackBottomInitial = self.artworkBottomConstraint.constant
		
		containerView.layer.masksToBounds = true
		containerView.layer.cornerRadius = 4
		
		artistImg.layer.masksToBounds = true
		artistImg.layer.cornerRadius = 17.5
		artistImg.layer.borderColor = UIColor.clearColor().CGColor
		artistImg.layer.borderWidth = 2
    }

	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: - Add shadow overlay to cell
	func addOverlay() {
		if gradientLayerView != nil { gradientLayerView.removeFromSuperview() }
		gradientLayerView = UIView(frame: CGRect(x: 0, y: artworkContainer.bounds.height - 100, width: artworkContainer.bounds.width, height: 100))
		gradient = CAGradientLayer()
		gradient.colors = [AnyObject]()
		gradient.colors!.append(UIColor.clearColor().CGColor)
		for index in 0...17 {
			gradient.colors!.append(UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Double(index) * 0.05)).CGColor)
		}
		gradient.cornerRadius = 4
		gradientLayerView.layer.insertSublayer(gradient, atIndex: 0)
		gradient.frame = gradientLayerView.bounds
		artworkContainer.addSubview(gradientLayerView)
	}

	// MARK: - Add new item label
	func addNewItemLabel() {
		if label == nil {
			label = UILabel(frame: CGRect(x: gradientLayerView.bounds.width - 65, y: artworkContainer.bounds.height - 40, width: 50, height: 26))
			label.text = "NEW"
			label.font = UIFont(name: label.font.fontName, size: 12)
			label.textColor = theme.orangeColor
			label.textAlignment = NSTextAlignment.Center
			label.layer.masksToBounds = true
			label.layer.cornerRadius = 4
			label.layer.borderWidth = 1
			label.layer.borderColor = theme.orangeColor.CGColor
			artworkContainer.addSubview(label)
		}
	}
	
	// MARK: - Remove new item label
	func removeNewItemLabel() {
		if label != nil {
			self.label.removeFromSuperview()
			self.label = nil
		}
	}
	
	// MARK: - Calculate offset for image parallax effect
	func setBackgroundOffset(offset:CGFloat) {
		let boundOffset = max(0, min(1, offset))
		let pixelOffset = (1 - boundOffset) * 2 * imageParallaxFactor
		self.artworkTopConstraint.constant = self.imgBackTopInitial - pixelOffset
		self.artworkBottomConstraint.constant = self.imgBackBottomInitial + pixelOffset
	}
}
