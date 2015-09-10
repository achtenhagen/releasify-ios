//
//  API.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/11/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class API {
	static let sharedInstance = API()
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var newItems: [Int]!
	
	// MARK: - Refresh Content
	func refreshContent (successHandler: ([Int] -> Void)?, errorHandler: ((error: NSError!) -> Void)?) {
		newItems = [Int]()
		let explicit = NSUserDefaults.standardUserDefaults().boolForKey("allowExplicit")
		var explicitValue = 1
		if !appDelegate.allowExplicitContent {
			explicitValue = 0
		}
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&explicit=\(explicitValue)"
		sendRequest(APIURL.updateContent.rawValue, postString: postString, successHandler: { (response, data) in
			if let HTTPResponse = response as? NSHTTPURLResponse {
				if HTTPResponse.statusCode == 200 {
					println("HTTP status code: \(HTTPResponse.statusCode)")
					var error: NSError?
					if let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &error) as? [NSDictionary] {
						if error != nil {
							errorHandler!(error: error)
							return
						}
						for item in json {
							let releaseDate = (item["releaseDate"] as! Double)
							let albumItem = Album(
								ID: item["id"] as! Int,
								title: item["title"] as! String,
								artistID: item["artistId"] as! Int,
								releaseDate: releaseDate,
								artwork: (string: item["artwork"] as! String),
								explicit: item["explicit"] as! Int,
								copyright: item["copyright"] as! String,
								iTunesUniqueID: item["iTunesUniqueId"] as! Int,
								iTunesURL: item["iTunesUrl"] as! String,
								created: Int(NSDate().timeIntervalSince1970)
							)
							let newAlbumID = AppDB.sharedInstance.addAlbum(albumItem)
							if newAlbumID > 0 && UIApplication.sharedApplication().scheduledLocalNotifications.count < 64 {
								self.newItems.append(newAlbumID)
								let remaining = Double(releaseDate) - Double(NSDate().timeIntervalSince1970)
								if remaining > 0 {
									println("Notification will fire in \(remaining) seconds.")
									var notification = UILocalNotification()
									notification.category = "DEFAULT_CATEGORY"
									notification.timeZone = NSTimeZone.localTimeZone()
									notification.alertTitle = "New Album Released"
									notification.alertBody = "\(albumItem.title) is now available."
									notification.fireDate = NSDate(timeIntervalSince1970: item["releaseDate"] as! Double)
									notification.applicationIconBadgeNumber++
									notification.soundName = UILocalNotificationDefaultSoundName
									notification.userInfo = ["AlbumID": albumItem.ID, "iTunesURL": albumItem.iTunesURL]
									UIApplication.sharedApplication().scheduleLocalNotification(notification)
								}
							}
						}
						AppDB.sharedInstance.getAlbums()
						NSUserDefaults.standardUserDefaults().setInteger(Int(NSDate().timeIntervalSince1970), forKey: "lastUpdated")
						if let handler: Void = successHandler?(self.newItems) {
							handler
						}
					}
				} else {
					errorHandler!(error: NSError(domain: "Unauthorized.", code: 403, userInfo: nil))
				}
			}
			},
			errorHandler: { (error) -> Void in
				errorHandler!(error: error)
		})
	}
	
	// MARK: - Refresh Subscriptions
	func refreshSubscriptions (successHandler: (() -> Void)?, errorHandler: ((error: NSError!) -> Void)?) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)"
		sendRequest(APIURL.updateArtists.rawValue, postString: postString, successHandler: { (response, data) in
			if let HTTPResponse = response as? NSHTTPURLResponse {
				println("HTTP status code: \(HTTPResponse.statusCode)")
				if HTTPResponse.statusCode == 200 {
					var error: NSError?
					if let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &error) as? [NSDictionary] {
						if error != nil {
							errorHandler!(error: error)
							return
						}
						for item in json {
							let artistID = item["artistId"] as! Int
							let artistTitle = (item["title"] as? String)!
							let artistUniqueID = item["iTunesUniqueID"] as! Int
							let newArtistID = AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID)
						}
						AppDB.sharedInstance.getArtists()
						if let handler: Void = successHandler?() {
							handler
							return
						}
					}
				} else {
					errorHandler!(error: NSError(domain: "Unauthorized.", code: 403, userInfo: nil))
				}
			}
			},
			errorHandler: { (error) in
				errorHandler!(error: error)
		})
	}
	
	// MARK: - Device Registration
	func register (allowExplicitContent: Bool = false, deviceToken: String? = nil, successHandler: ((userID: Int?, userUUID: String) -> Void), errorHandler: ((error: NSError!) -> Void)) {
		let UUID = NSUUID().UUIDString
		var explicitValue = 1
		if !allowExplicitContent {
			explicitValue = 0
		}
		var postString = "uuid=\(UUID)&explicit=\(explicitValue)"
		if deviceToken != nil {
			postString += "&deviceToken=\(deviceToken!)"
		}
		sendRequest(APIURL.register.rawValue, postString: postString, successHandler: { (response, data) in
			if let HTTPResponse = response as? NSHTTPURLResponse {
				if HTTPResponse.statusCode != 201 {
					errorHandler(error: NSError(domain: "Error: received HTTP status code \(HTTPResponse.statusCode) {sendRequest}", code: HTTPResponse.statusCode, userInfo: nil))
				}
				var error: NSError?
				if let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &error) as? NSDictionary {
					if error != nil {
						errorHandler(error: error)
					}
					let receivedUserID = json["id"] as? Int
					if receivedUserID > 0 {
						println("Received user ID: \(receivedUserID!) from the server.")
						successHandler(userID: receivedUserID!, userUUID: UUID)
					}
				}
			}
			},
			errorHandler: { (error) in
				errorHandler(error: error)
		})
	}
	
	// MARK: - Network Requests
	func sendRequest (url: String, postString: String, successHandler: ((response: NSURLResponse!, data: NSData!) -> Void), errorHandler: ((error: NSError!) -> Void)) {
		let apiUrl = NSURL(string: url)
		var appVersion = "Unknown"
		if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
			appVersion = version
		}
		let systemVersion = UIDevice.currentDevice().systemVersion
		let deviceName = UIDevice().deviceType.rawValue
		let userAgent = "Releasify/\(appVersion) (iOS/\(systemVersion); \(deviceName))"
		let request = NSMutableURLRequest(URL:apiUrl!)
		request.HTTPMethod = "POST"
		request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
		request.timeoutInterval = 300
		request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			if error != nil {
				errorHandler(error: error)
				return
			}
			successHandler(response: response, data: data)
		})
	}
}

public enum APIURL: String {
	case register = "https://releasify.me/api/ios/v2.0/register.php",
	updateContent = "https://releasify.me/api/ios/v2.0/update_content.php",
	confirmArtist = "https://releasify.me/api/ios/v2.0/confirm_artist.php",
	submitArtist  = "https://releasify.me/api/ios/v2.0/submit_artist.php",
	removeArtist  = "https://releasify.me/api/ios/v2.0/unsubscribe_artist.php",
	updateArtists = "https://releasify.me/api/ios/v2.0/update_artists.php",
	lookupItem    = "https://releasify.me/api/ios/v2.0/item.php"
}
