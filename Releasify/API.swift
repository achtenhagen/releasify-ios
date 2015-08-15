
// -- Releasify API -- //

import UIKit

class API {
    
    static let sharedInstance = API()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var newItems: [Int]!
    
    // -- Main method to update the App's content -- //
	func refreshContent (successHandler: ([Int] -> Void)?, errorHandler: ((error: NSError!) -> Void)?) {
		newItems = [Int]()
        let explicit = NSUserDefaults.standardUserDefaults().boolForKey("allowExplicit")
        var explicitValue = 1
        if !appDelegate.allowExplicitContent { explicitValue = 0 }
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&explicit=\(explicitValue)"
        sendRequest(APIURL.updateContent.rawValue, postString: postString, successHandler: { (response, data) in
            if let HTTPResponse = response as? NSHTTPURLResponse {
                if HTTPResponse.statusCode == 200 {
                    println("HTTP status code: \(HTTPResponse.statusCode)")
                    var error: NSError?
                    if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? [NSDictionary] {
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
                }
            }
        },
        errorHandler: { (error) -> Void in
            errorHandler!(error: error)
        })
    }
    
    // -- Main method to update the App's subscriptions -- //
    func refreshSubscriptions (successHandler: (() -> Void)?, errorHandler: ((error: NSError!) -> Void)?) {
        let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)"
        sendRequest(APIURL.updateArtists.rawValue, postString: postString, successHandler: { (response, data) in
            if let HTTPResponse = response as? NSHTTPURLResponse {
                println("HTTP status code: \(HTTPResponse.statusCode)")
                if HTTPResponse.statusCode == 200 {
                    var error: NSError?
                    if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? [NSDictionary] {
                        if error != nil {
                            errorHandler!(error: error)
                            return
                        }
                        for item in json {
                            let artistID: Int = item["artistId"] as! Int
                            let artistTitle: String = String(stringInterpolationSegment: item["title"]!)
                            let artistUniqueID: Int = item["iTunesUniqueID"] as! Int
                            let newArtistID = AppDB.sharedInstance.addArtist(Int32(artistID), artistTitle: artistTitle, iTunesUniqueID: Int32(artistUniqueID))
                        }
                        AppDB.sharedInstance.getArtists()
                        if let handler: Void = successHandler?() {
                            handler
                        }
                    }
                }
            }
        },
        errorHandler: { (error) in
            errorHandler!(error: error)
        })
    }
    
    // -- Handles all network requests related to the Releasify API -- //
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
            }
            successHandler(response: response, data: data)
        })
    }
	
	// -- Registers a new user with Releasify -- //
	func register (allowExplicitContent: Bool = false, deviceToken: String? = nil, successHandler: ((userID: Int?, userUUID: String) -> Void), errorHandler: ((error: NSError!) -> Void)) {
		let UUID = NSUUID().UUIDString
		var explicitValue = 1
		if !allowExplicitContent { explicitValue = 0 }
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
				if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary {
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
}

public enum APIURL: String {
    case register = "https://releasify.me/api/ios/v1.1/register.php",
    updateContent = "https://releasify.me/api/ios/v1.1/update_content.php",
    confirmArtist = "https://releasify.me/api/ios/v1.1/confirm_artist.php",
    submitArtist  = "https://releasify.me/api/ios/v1.1/submit_artist.php",
    removeArtist  = "https://releasify.me/api/ios/v1.1/unsubscribe_artist.php",
    updateArtists = "https://releasify.me/api/ios/v1.1/update_artists.php"
}
