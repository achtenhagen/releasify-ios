//
//  Notification.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 11/1/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class Notification: UIView {

	static let sharedInstance = Notification()
	var notificationView: UIVisualEffectView!
	let notificationTitle = UILabel()
	let notificationSubtitle = UILabel()
	
	override func drawRect(rect: CGRect) {
		notificationView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
		notificationView.frame = rect
		notificationView.alpha = 1.0
		addSubview(notificationView)
		
		notificationTitle.frame = CGRect(x: 10, y: 8, width: 300, height: 20)
		notificationTitle.textColor = UIColor(red: 0, green: 216/255, blue: 1, alpha: 1)
		notificationTitle.font = UIFont.systemFontOfSize(16.0)
		notificationTitle.lineBreakMode = .ByTruncatingTail
		notificationTitle.text = "Notification Title"
		notificationView.contentView.addSubview(notificationTitle)
		
		notificationSubtitle.frame = CGRect(x: 10, y: 30, width: 300, height: 20)
		notificationSubtitle.textColor = UIColor.whiteColor()
		notificationSubtitle.layer.opacity = 0.5
		notificationSubtitle.font = UIFont.systemFontOfSize(13.0)
		notificationSubtitle.text = "description goes here..."
		notificationView.contentView.addSubview(notificationSubtitle)
	}

	func showNotification(title: String, subtitle: String) {
		notificationTitle.text = title
		notificationSubtitle.text = subtitle
		UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			self.notificationView.alpha = 1.0
			self.notificationView.frame.origin.y -= self.notificationView.frame.height
			}, completion: { bool in
				self.delay(3, closure: {
					self.hideNotification()
				})
		})
	}
	
	func hideNotification() {
		UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			self.notificationView.alpha = 0
			self.notificationView.frame.origin.y += self.notificationView.frame.height
			}, completion: nil)
	}
	
	func delay(delay: Double, closure: () -> Void) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
	}
}
