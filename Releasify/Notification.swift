//
//  Notification.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 11/1/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class Notification: UIView {

	var notificationView: UIVisualEffectView!
	var title: UILabel!
	var subtitle: UILabel!
	var viewFrame: CGRect!
	
	override init (frame: CGRect) {
		super.init(frame: frame)
		self.viewFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
		
		notificationView = UIVisualEffectView(effect: UIBlurEffect(style: Theme.sharedInstance.notificationBlurEffectStyle))
		notificationView.frame = viewFrame
		self.addSubview(notificationView)
		
		let vibrancyEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: Theme.sharedInstance.notificationBlurEffectStyle))
		let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
		vibrancyEffectView.frame = notificationView.frame
		
		title = UILabel(frame: CGRect(x: 10, y: 10, width: 300, height: 20))
		title.font = UIFont.boldSystemFontOfSize(16.0)
		title.lineBreakMode = .ByTruncatingTail
		vibrancyEffectView.contentView.addSubview(title)
		
		subtitle = UILabel(frame: CGRect(x: 10, y: 30, width: 300, height: 20))
		subtitle.font = UIFont.systemFontOfSize(13.0)
		vibrancyEffectView.contentView.addSubview(subtitle)
		
		notificationView.contentView.addSubview(vibrancyEffectView)
		
		self.alpha = 0
	}

	required init? (coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	func show (completed: () -> Void) {
		UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			self.alpha = 1.0
			self.notificationView.frame.origin.x = self.viewFrame.origin.x + self.notificationView.frame.width
			}, completion: { bool in
				self.hide({ completed() })
		})
	}
	
	func hide (completed: () -> Void) {
		UIView.animateWithDuration(0.4, delay: 3.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			// self.alpha = 0
			self.notificationView.frame.origin.x += self.notificationView.frame.width
			}, completion: { bool in
				completed()
		})
	}
}
