//
//  AppEmptyState.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/3/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class AppEmptyState {

	private var theme: AppEmptyStateTheme!
	private var containerView: UIView!
	private var placeholderImage: UIImageView!
	private var placeholderTitle: UILabel!
	private var placeholderSubtitle: UILabel!
	var placeholderButton: UIButton!

	init(style: Theme.Styles, refView: UIView, imageName: String, title: String, subtitle: String, buttonTitle: String?, offset: CGFloat = 0) {

		theme = AppEmptyStateTheme(style: style)

		// Container view
		containerView = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 300, height: 300)))
		containerView.center = refView.center
		containerView.center.y += offset

		// Image view
		placeholderImage = UIImageView(frame: CGRect(origin: CGPoint(x: 100, y: 100), size: CGSize(width: 100, height: 100)))
		placeholderImage.image = UIImage(named: imageName)
		placeholderImage.center.y -= 80
		containerView.addSubview(placeholderImage)

		// Title label
		placeholderTitle = UILabel()
		placeholderTitle.font = UIFont(name: placeholderTitle.font.fontName, size: 20)
		placeholderTitle.textColor = theme.titleColor
		placeholderTitle.text = title
		placeholderTitle.textAlignment = NSTextAlignment.Center
		placeholderTitle.adjustsFontSizeToFitWidth = true
		placeholderTitle.sizeToFit()
		placeholderTitle.center = CGPoint(x: containerView.frame.size.width / 2, y: (containerView.frame.size.height / 2) + 10)
		containerView.addSubview(placeholderTitle)

		// Subtitle label
		placeholderSubtitle = UILabel()
		placeholderSubtitle.font = UIFont(name: placeholderSubtitle.font!.fontName, size: 14)
		placeholderSubtitle.textColor = theme.subtitleColor
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
			placeholderButton.layer.borderColor = theme.placeholderButtonTintColor.CGColor
			placeholderButton.tintColor = theme.placeholderButtonTintColor
			containerView.addSubview(placeholderButton)
		}
	}

	// Return placeholder view
	func view() -> UIView {
		return containerView
	}
}

// Theme Subclass
private class AppEmptyStateTheme: Theme {
	var titleColor: UIColor!
	var subtitleColor: UIColor!
	var placeholderButtonTintColor: UIColor!

	override init(style: Styles) {
		super.init(style: style)
		switch style {
		case .Dark:
			titleColor = globalTintColor
			subtitleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
			placeholderButtonTintColor = globalTintColor
		case .Light:
			titleColor = globalTintColor
			subtitleColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
			placeholderButtonTintColor = globalTintColor
		}
	}
}
