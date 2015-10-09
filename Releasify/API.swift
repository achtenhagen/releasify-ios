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
	
	enum Error: ErrorType {
		case BadRequest
		case FailedRequest
		case FailedToParseJSON
		case FileNotFound
		case InternalServerError
		case InvalidHTTPResponse
		case RequestEntityTooLarge
		case Unauthorized
		case UnknownError
	}
	
	enum URL: String {
		case register = "https://releasify.me/api/ios/v2.1/register.php",
		updateContent = "https://releasify.me/api/ios/v2.1/update_content.php",
		confirmArtist = "https://releasify.me/api/ios/v2.1/confirm_artist.php",
		submitArtist  = "https://releasify.me/api/ios/v2.1/submit_artist.php",
		removeArtist  = "https://releasify.me/api/ios/v2.1/unsubscribe_artist.php",
		lookupItem    = "https://releasify.me/api/ios/v2.1/item.php"
	}
	
	// MARK: - Refresh Content
	func refreshContent (successHandler: ([Int] -> Void)?, errorHandler: ((error: ErrorType) -> Void)) {
		newItems = [Int]()
		var postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&explicit=\(appDelegate.allowExplicitContent ? 1 : 0)"
		if appDelegate.userDeviceToken != nil {
			postString += "&token=\(appDelegate.userDeviceToken!)"
		}
		if appDelegate.contentHash != nil {
			postString += "&hash=\(appDelegate.contentHash!)"
		}
		sendRequest(URL.updateContent.rawValue, postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 200 {
				switch statusCode {
				case 204:
					if let handler: Void = successHandler?(self.newItems) { handler }
				case 400:
					// Request new ID
					break
				case 403:
					errorHandler(error: Error.Unauthorized)
				case 404:
					errorHandler(error: Error.FileNotFound)
				case 500:
					errorHandler(error: Error.InternalServerError)
				default:
					errorHandler(error: Error.UnknownError)
				}
				return
			}
			
			guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? NSDictionary else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			
			guard let contentHash = json!["hash"] as? String else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			
			guard let content = json!["content"] as? [NSDictionary] else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			
			guard let subscriptions = json!["subscriptions"] as? [NSDictionary] else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			
			self.processContent(content)
			self.processSubscriptions(subscriptions)
			
			NSUserDefaults.standardUserDefaults().setValue(contentHash, forKey: "contentHash")
			self.appDelegate.contentHash = contentHash
			
			AppDB.sharedInstance.getArtists()
			AppDB.sharedInstance.getAlbums()
			
			self.appDelegate.completedRefresh = true
			NSUserDefaults.standardUserDefaults().setInteger(Int(NSDate().timeIntervalSince1970), forKey: "lastUpdated")
			
			if let handler: Void = successHandler?(self.newItems) {
				handler
			}
			},
			errorHandler: { (error) -> Void in
				errorHandler(error: error)
		})
	}
	
	// MARK: - Process downloaded JSON data.
	func processContent (json: [NSDictionary]) {
		for item in json {
			let releaseDate = item["releaseDate"] as! Double
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
			if newAlbumID > 0 && UIApplication.sharedApplication().scheduledLocalNotifications!.count < 64 {
				self.newItems.append(newAlbumID)
				let remaining = Double(releaseDate) - Double(NSDate().timeIntervalSince1970)
				if remaining > 0 {
					print("Notification will fire in \(remaining) seconds.")
					let notification = UILocalNotification()
					if #available(iOS 8.2, *) {
						notification.alertTitle = "New Album Released"
					}
					notification.category = "DEFAULT_CATEGORY"
					notification.timeZone = NSTimeZone.localTimeZone()
					notification.alertBody = "\(albumItem.title) is now available."
					notification.fireDate = NSDate(timeIntervalSince1970: item["releaseDate"] as! Double)
					notification.applicationIconBadgeNumber++
					notification.soundName = UILocalNotificationDefaultSoundName
					notification.userInfo = ["AlbumID": albumItem.ID, "iTunesURL": albumItem.iTunesURL]
					UIApplication.sharedApplication().scheduleLocalNotification(notification)
				}
			}
		}
	}
	
	// MARK: - Process downloaded JSON data.
	func processSubscriptions (json: [NSDictionary]) {
		for item in json {
			let artistID = item["artistId"] as! Int
			let artistTitle = (item["title"] as? String)!
			let artistUniqueID = item["iTunesUniqueID"] as! Int
			AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID)
		}
	}
	
	// MARK: - Device Registration
	func register (allowExplicitContent: Bool = false, deviceToken: String? = nil, successHandler: ((userID: Int?, userUUID: String) -> Void), errorHandler: ((error: ErrorType) -> Void)) {
		let UUID = NSUUID().UUIDString
		var explicitValue = 1
		if !allowExplicitContent { explicitValue = 0 }
		var postString = "uuid=\(UUID)&explicit=\(explicitValue)"
		if deviceToken != nil { postString += "&deviceToken=\(deviceToken!)" }
		sendRequest(URL.register.rawValue, postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 201 {
				errorHandler(error: Error.BadRequest)
				return
			}
			guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? NSDictionary else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			let receivedUserID = json!["id"] as? Int
			if receivedUserID > 0 {
				print("Received user ID: \(receivedUserID!) from the server.")
				successHandler(userID: receivedUserID!, userUUID: UUID)
			}
			},
			errorHandler: { (error) in
				errorHandler(error: error)
		})
	}

	// MARK: - Network Requests
	func sendRequest (url: String, postString: String, successHandler: ((statusCode: Int!, data: NSData!) -> Void), errorHandler: (error: ErrorType) -> Void) {
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
				errorHandler(error: Error.FailedRequest)
				return
			}
			guard let response = response as? NSHTTPURLResponse else {
				errorHandler(error: Error.InvalidHTTPResponse)
				return
			}
			print("HTTP status code: \(response.statusCode)")
			successHandler(statusCode: response.statusCode, data: data)
		})
	}
}
