//
//  Notification.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 11/1/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class Notification: UIView {
	
	var titleLabel: UILabel!
	var icon: IconType = .notify
	var iconView: UIImageView!
	var iconFile: String!
	var viewFrame: CGRect!
	
	enum IconType {
		case checkmark
		case error
		case notify
		case remove
		case warning
	}
	
	init(frame: CGRect, title: String, icon: IconType) {
		super.init(frame: frame)
		
		self.layer.masksToBounds = true
		self.layer.cornerRadius = 12
		self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
		self.userInteractionEnabled = true
		
		self.icon = icon
		switch icon {
		case .error:
			iconFile = "icon_error"
		case .checkmark:
			iconFile = "icon_check"
		case .notify:
			iconFile = "icon_notify"
		case .remove:
			iconFile = "icon_remove"
		case .warning:
			iconFile = "icon_warning"
			
		}
		
		iconView = UIImageView(image: UIImage(named: iconFile))
		iconView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
		iconView.center = CGPoint(x: self.center.x, y: self.center.y - 10)
		self.addSubview(iconView)
		
		titleLabel = UILabel(frame: CGRect(x: 0, y: self.frame.height - 30, width: self.frame.width, height: 20))
		titleLabel.font = UIFont.boldSystemFontOfSize(16.0)
		titleLabel.textColor = UIColor.whiteColor()
		titleLabel.textAlignment = .Center
		titleLabel.lineBreakMode = .ByTruncatingTail
		titleLabel.text = title
		self.addSubview(titleLabel)
		
		self.alpha = 0
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	func show(completed: () -> Void) {
		UIView.animateWithDuration(0.25, delay: 0.5, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			self.alpha = 1.0
			self.frame.origin.y = self.center.y
			}, completion: { (bool) in
				self.hide({ completed() })
		})
	}
	
	func hide(completed: () -> Void) {
		UIView.animateWithDuration(0.25, delay: 2.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			self.alpha = 0
			self.frame.origin.y += 50
			}, completion: { (bool) in
				completed()
		})
	}
}
