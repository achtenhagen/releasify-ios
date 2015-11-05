//
//  NotificationQueue.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 11/4/15.
//  Copyright © 2015 Fioware Studios, LLC. All rights reserved.
//

final class NotificationQueue {
	
	static var sharedInstance = NotificationQueue()
	var queue: [Notification]?
	var busy = false
	
	private init () {
		queue = [Notification]()
	}
	
	func add (notification: Notification) {
		queue?.append(notification)
		process()
	}
	
	func remove () {
		if queue?.count > 0 {
			queue![0].removeFromSuperview()
			queue?.removeAtIndex(0)
			process()
		}
	}
	
	func process () {
		if busy { return }
		if (queue?.count > 0) {
			self.busy = true
			queue![0].show({
				self.busy = false
				self.remove()
			})
		}
	}
}

