//
//  NotificationsController.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 9/4/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

class NotificationsController: UIViewController {
	let notificationCellReuseIdentifier = "NotificationCell"
	
	@IBOutlet weak var clearBtn: UIBarButtonItem!
	@IBOutlet weak var notificationsTable: UITableView!
	
	@IBAction func closeView(sender: AnyObject) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		notificationsTable.registerNib(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: notificationCellReuseIdentifier)
		
		// Background gradient.
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
		
		clearBtn.enabled = (UIApplication.sharedApplication().scheduledLocalNotifications.count > 0 ? true : false)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
}

// MARK: - UITableViewDataSource
extension NotificationsController: UITableViewDataSource { 
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return UIApplication.sharedApplication().scheduledLocalNotifications.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = notificationsTable.dequeueReusableCellWithIdentifier(notificationCellReuseIdentifier) as! NotificationCell
		let notifications = UIApplication.sharedApplication().scheduledLocalNotifications
		var notification = notifications[indexPath.row] as! UILocalNotification
		let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
		let notificationID = userInfoCurrent["AlbumID"]! as! Int
		cell.notificationBody.text = "\(notification.alertTitle) - \(notification.alertBody!)"
		return cell
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			// UIApplication.sharedApplication().cancelLocalNotification(notification)
			clearBtn.enabled = (UIApplication.sharedApplication().scheduledLocalNotifications.count > 0 ? true : false)
		}
	}
}

// MARK: - UITableViewDelegate
extension NotificationsController: UITableViewDelegate {
	func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
		return "Don't notify"
	}
}
