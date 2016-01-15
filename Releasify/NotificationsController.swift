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
	var notifications: [UILocalNotification]!
	var albums: [Album]!
	
	@IBOutlet weak var notificationsTable: UITableView!
	
	@IBAction func closeView(sender: AnyObject) {
		notificationsTable.setEditing(false, animated: false)
		dismissViewControllerAnimated(true, completion: {
			NSNotificationCenter.defaultCenter().postNotificationName("updateNotificationButton", object: nil, userInfo: nil)
		})
	}
	
	override func setEditing (editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		notificationsTable.setEditing(editing, animated: true)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()		
		
		notifications = [UILocalNotification]()
		albums = [Album]()
		for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
			let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
			let notificationID = userInfoCurrent["albumID"] as! Int
			if let album = AppDB.sharedInstance.getAlbum(notificationID) {
				notifications.append(notification)
				albums.append(album)
			}
		}
		
		notificationsTable.registerNib(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: notificationCellReuseIdentifier)
		
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.colors = [UIColor(red: 0, green: 34/255, blue: 48/255, alpha: 1.0).CGColor, UIColor(red: 0, green: 0, blue: 6/255, alpha: 1.0).CGColor]
		gradient.locations = [0.0 , 1.0]
		gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
		gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		view.layer.insertSublayer(gradient, atIndex: 0)
		
		self.navigationItem.leftBarButtonItem = self.editButtonItem()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}

// MARK: - UITableViewDataSource
extension NotificationsController: UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return notifications.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = notificationsTable.dequeueReusableCellWithIdentifier(notificationCellReuseIdentifier) as! NotificationCell
		if let hash = albums?[indexPath.row].artwork {
			if AppDB.sharedInstance.checkArtwork(hash) {
				cell.artwork.image = AppDB.sharedInstance.getArtwork(hash)
			} else {
				cell.artwork.image = UIImage(named: "icon_artwork_placeholder")
			}
		}
		let date = NSDate(timeIntervalSince1970: (albums?[indexPath.row].releaseDate)!)
		let dateFormatter = NSDateFormatter()
		dateFormatter.timeStyle = .NoStyle
		dateFormatter.dateStyle = .ShortStyle
		dateFormatter.timeZone = NSTimeZone()
		let localDate = dateFormatter.stringFromDate(date)		
		cell.notificationBody.text = "\(AppDB.sharedInstance.getAlbumArtist(albums[indexPath.row].ID)!): \(albums[indexPath.row].title) is set to be released on \(localDate)."
		return cell
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			let notification = notifications[indexPath.row]
			UIApplication.sharedApplication().cancelLocalNotification(notification)
			notifications.removeAtIndex(indexPath.row)
			albums.removeAtIndex(indexPath.row)
			notificationsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
			notificationsTable.reloadData()
			if notifications.count == 0 {
				closeView(self)
			}
		}
	}
}

// MARK: - UITableViewDelegate
extension NotificationsController: UITableViewDelegate {
	func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
		return "Don't notify"
	}
	
	func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
		setEditing(true, animated: true)
	}
	
	func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
		setEditing(false, animated: true)
	}
}
