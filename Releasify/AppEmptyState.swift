//
//  AppEmptyState.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/3/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class AppEmptyState {

	private var containerView: UIView!
	private var placeholderImage: UIImageView!
	private var placeholderTitle: UILabel!
	private var placeholderSubtitle: UILabel!
	var placeholderButton: UIButton!

	init(theme: Theme, refView: UIView, imageName: String, title: String, subtitle: String, buttonTitle: String?) {

		// Container view
		containerView = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 300, height: 300)))
		containerView.center = refView.center

		// Image view
		placeholderImage = UIImageView(frame: CGRect(origin: CGPoint(x: 100, y: 100), size: CGSize(width: 100, height: 100)))
		placeholderImage.image = UIImage(named: imageName)
		placeholderImage.center.y -= 80
		containerView.addSubview(placeholderImage)

		// Title label
		placeholderTitle = UILabel()
		placeholderTitle.font = UIFont(name: placeholderTitle.font.fontName, size: 20)
		placeholderTitle.textColor = theme.blueColor
		placeholderTitle.text = title
		placeholderTitle.textAlignment = NSTextAlignment.Center
		placeholderTitle.adjustsFontSizeToFitWidth = true
		placeholderTitle.sizeToFit()
		placeholderTitle.center = CGPoint(x: containerView.frame.size.width / 2, y: (containerView.frame.size.height / 2) + 10)
		containerView.addSubview(placeholderTitle)

		// Subtitle label
		placeholderSubtitle = UILabel()
		placeholderSubtitle.font = UIFont(name: placeholderSubtitle.font!.fontName, size: 14)
		placeholderSubtitle.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		placeholderSubtitle.text = subtitle
		placeholderSubtitle.textAlignment = NSTextAlignment.Center
		placeholderSubtitle.adjustsFontSizeToFitWidth = true
		placeholderSubtitle.sizeToFit()
		placeholderSubtitle.center = CGPoint(x: containerView.frame.size.width / 2, y: (containerView.frame.size.height / 2) + 45)
		containerView.addSubview(placeholderSubtitle)

		// Optional Button
		if buttonTitle != nil {
			placeholderButton = UIButton(type: .RoundedRect)
			placeholderButton.frame = CGRect(origin: CGPoint(x: 80, y: 130), size: CGSize(width: 140, height: 40))
			placeholderButton.setTitle(buttonTitle, forState: UIControlState.Normal)
			placeholderButton.frame.origin.y += 95
			placeholderButton.layer.cornerRadius = 4
			placeholderButton.layer.borderWidth = 1
			placeholderButton.layer.borderColor = theme.blueColor.CGColor
			containerView.addSubview(placeholderButton)
		}
	}

	// MARK: - Return placeholder view
	func view() -> UIView {
		return containerView
	}
}
