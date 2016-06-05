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
	private let baseURL = NSURL(string: "https://releasify.io/api/ios/v1.2/")!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
	enum Error: ErrorType {
		case BadRequest
		case CannotConnectToHost
		case DNSLookupFailed
		case FailedRequest
		case FailedToGetResource
		case FailedToParseJSON
		case FailedToProcessJSON
		case FileNotFound
		case InternalServerError
		case InvalidHTTPResponse
		case NetworkConnectionLost
		case NoInternetConnection
		case RequestEntityTooLarge
		case ServerDownForMaintenance
		case Unauthorized
		case UnknownError
	}
	
	enum Endpoint {
		case confirmArtist
		case feed
		case getAlbumsByArtist
		case itemLookup
		case register
		case removeAlbum
		case removeArtist
		case search
		case searchArtist
		case submitArtist
		case updateContent
		
		func url() -> NSURL {
			switch self {
			case .confirmArtist:
				return sharedInstance.baseURL.URLByAppendingPathComponent("confirm_artist.php")
			case .feed:
				return sharedInstance.baseURL.URLByAppendingPathComponent("feed.php")
			case .getAlbumsByArtist:
				return sharedInstance.baseURL.URLByAppendingPathComponent("get_albums_by_artist.php")
			case .itemLookup:
				return sharedInstance.baseURL.URLByAppendingPathComponent("item.php")
			case .register:
				return sharedInstance.baseURL.URLByAppendingPathComponent("register.php")
			case .removeAlbum:
				return sharedInstance.baseURL.URLByAppendingPathComponent("unsubscribe_album.php")
			case .removeArtist:
				return sharedInstance.baseURL.URLByAppendingPathComponent("unsubscribe_artist.php")
			case .search:
				return sharedInstance.baseURL.URLByAppendingPathComponent("search.php")
			case .searchArtist:
				return sharedInstance.baseURL.URLByAppendingPathComponent("search_artist.php")
			case .submitArtist:
				return sharedInstance.baseURL.URLByAppendingPathComponent("submit_artist.php")
			case .updateContent:
				return sharedInstance.baseURL.URLByAppendingPathComponent("update_content.php")
			}
		}
	}

	// Return error for http status code
	func getErrorFor(statusCode: Int) -> ErrorType {
		switch statusCode {
		case 400:
			return Error.BadRequest
		case 403:
			return Error.Unauthorized
		case 404:
			return Error.FileNotFound
		case 413:
			return Error.RequestEntityTooLarge
		case 500:
			return Error.InternalServerError
		case 503:
			return Error.ServerDownForMaintenance
		default:
			return Error.UnknownError
		}
	}

	// MARK: - Get iTunes feed
	func getiTunesFeed(successHandler: ([Album] -> Void), errorHandler: ((error: ErrorType) -> Void)) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)"
		sendRequest(Endpoint.feed.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 200 {
				errorHandler(error: self.getErrorFor(statusCode))
				return
			}		

			guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [NSDictionary] else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}

			if let handler: Void = successHandler(self.processAlbumsFrom(json!)) {
				handler
				return
			}

			}, errorHandler: { (error) in
				errorHandler(error: error)
		})
	}
	
	// MARK: - Refresh Content
	func refreshContent(successHandler: ((processedAlbums: [Album], contentHash: String) -> Void)?, errorHandler: ((error: ErrorType) -> Void)) {
		var processedAlbums = [Album]()
		var postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&explicit=\(appDelegate.allowExplicitContent ? 1 : 0)"
		if appDelegate.userDeviceToken != nil {
			postString += "&token=\(appDelegate.userDeviceToken!)"
		}
		if appDelegate.contentHash != nil {
			postString += "&hash=\(appDelegate.contentHash!)"
		}
		sendRequest(Endpoint.updateContent.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 200 {
				if statusCode == 204 {
					if let handler: Void = successHandler?(processedAlbums: processedAlbums, contentHash: self.appDelegate.contentHash!) {
						handler
						return
					}
				}
				errorHandler(error: self.getErrorFor(statusCode))
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

			processedAlbums = self.processAlbumsFrom(content)
			self.processSubscriptions(subscriptions)
			
			// Pass new content back thru closure
			if let handler: Void = successHandler?(processedAlbums: processedAlbums, contentHash: contentHash) { handler }
			},
			errorHandler: { (error) in
				errorHandler(error: error)
		})
	}

	// MARK: - Process downloaded JSON data
	func processAlbumsFrom(json: [NSDictionary]) -> [Album] {
		var albums = [Album]()
		for item in json {
			guard let ID = item["ID"] as? Int,
				let title = item["title"] as? String,
				let artistID = item["artistID"] as? Int,
				let releaseDate = item["releaseDate"] as? Double,
				let artworkUrl = item["artworkUrl"] as? String,
				let explicit = item["explicit"] as? Int,
				let copyright = item["copyright"] as? String,
				let iTunesUniqueID = item["iTunesUniqueID"] as? Int,
				let iTunesUrl = item["iTunesUrl"] as? String else { break }
			let albumItem = Album(ID: ID, title: title, artistID: artistID, releaseDate: releaseDate, artwork: md5(artworkUrl),
				artworkUrl: artworkUrl, explicit: explicit, copyright: copyright, iTunesUniqueID: iTunesUniqueID, iTunesUrl: iTunesUrl,
				created: Int(NSDate().timeIntervalSince1970))
			albums.append(albumItem)
		}
		return albums
	}
	
	// MARK: - Process downloaded JSON data
	func processSubscriptions(json: [NSDictionary]) {
		for item in json {
			let artistID = item["artistID"] as! Int
			let artistTitle = item["title"] as! String
			let artistUniqueID = item["iTunesUniqueID"] as! Int
			AppDB.sharedInstance.addArtist(artistID, artistTitle: artistTitle, iTunesUniqueID: artistUniqueID)
		}
	}

	// MARK: - Get artist albums for `AddSubscriptionDetailView`
	func getAlbumsByArtist(artistUniqueID: Int, successHandler: ((albums: [Album]) -> Void), errorHandler: ((error: ErrorType) -> Void)) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&artistUniqueID=\(artistUniqueID)"
		sendRequest(Endpoint.getAlbumsByArtist.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 200 {
				errorHandler(error: self.getErrorFor(statusCode))
				return
			}
			guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [NSDictionary] else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			// Process serialized JSON data
			let albums = self.processAlbumsFrom(json!)
			successHandler(albums: albums)
		}, errorHandler: { (error) in
				errorHandler(error: error)
		})
	}
	
	// MARK: - Album lookup
	func lookupAlbum(albumID: Int, successHandler: ((album: Album) -> Void), errorHandler: ((error: ErrorType) -> Void)) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&itemID=\(albumID)"
		sendRequest(Endpoint.itemLookup.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 200 {
				errorHandler(error: self.getErrorFor(statusCode))
				return
			}
			guard let item = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? NSDictionary else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}
			let releaseDate = item!["releaseDate"] as! Double
			let hash = md5(item!["artworkUrl"] as! String)
			let album = Album(
				ID: item!["ID"] as! Int,
				title: item!["title"] as! String,
				artistID: item!["artistID"] as! Int,
				releaseDate: releaseDate,
				artwork: hash,
				artworkUrl: (string: item!["artworkUrl"] as! String),
				explicit: item!["explicit"] as! Int,
				copyright: item!["copyright"] as! String,
				iTunesUniqueID: item!["iTunesUniqueID"] as! Int,
				iTunesUrl: item!["iTunesUrl"] as! String,
				created: Int(NSDate().timeIntervalSince1970)
			)
			successHandler(album: album)
			},
			errorHandler: { (error) in
				errorHandler(error: error)
		})
	}
	
	// MARK: - Fetch Artwork
	func fetchArtwork(url: String, successHandler: ((image: UIImage?) -> Void), errorHandler: (() -> Void)) {		
		if url.isEmpty { errorHandler(); return }
		let albumUrl = url.stringByReplacingOccurrencesOfString("100x100", withString: "600x600", options: .LiteralSearch, range: nil)
		guard let checkedURL = NSURL(string: albumUrl) else { errorHandler(); return }
		let request = NSURLRequest(URL: checkedURL)
		NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) in
			if error != nil { errorHandler(); return }
			guard let HTTPResponse = response as? NSHTTPURLResponse else { errorHandler(); return }
			if HTTPResponse.statusCode != 200 { errorHandler(); return }
			guard let imageData = UIImage(data: data!) else { errorHandler(); return }
			successHandler(image: imageData)
		})
	}
	
	// MARK: - Unsubscribe album
	func unsubscribeAlbum(iTunesUniqueID: Int, successHandler: (() -> Void)?, errorHandler: (error: ErrorType) -> Void) {
		let postString = "id=\(appDelegate.userID)&uuid=\(appDelegate.userUUID)&iTunesUniqueID=\(iTunesUniqueID)"
		API.sharedInstance.sendRequest(API.Endpoint.removeAlbum.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 204 {
				errorHandler(error: self.getErrorFor(statusCode))
				return
			}
			if let handler: Void = successHandler?() { handler }
			},
			errorHandler: { (error) in
				errorHandler(error: error)
		})
	}
	
	// MARK: - Device Registration
	func register(allowExplicitContent: Bool = true, deviceToken: String? = nil, successHandler: ((userID: Int?, userUUID: String) -> Void),
	              errorHandler: ((error: ErrorType) -> Void)) {
		let UUID = NSUUID().UUIDString
		var explicitValue = 1
		if !allowExplicitContent { explicitValue = 0 }
		var postString = "uuid=\(UUID)&explicit=\(explicitValue)"
		if deviceToken != nil { postString += "&deviceToken=\(deviceToken!)" }
		sendRequest(Endpoint.register.url(), postString: postString, successHandler: { (statusCode, data) in
			if statusCode != 201 {
				errorHandler(error: self.getErrorFor(statusCode))
				return
			}
			guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? NSDictionary else {
				errorHandler(error: Error.FailedToParseJSON)
				return
			}			
			let receivedUserID = json!["ID"] as? Int
			if receivedUserID > 0 {
				successHandler(userID: receivedUserID!, userUUID: UUID)
			}
			},
			errorHandler: { (error) in
				errorHandler(error: error)
		})
	}

	// MARK: - Handle network requests
	func sendRequest(url: NSURL, postString: String, successHandler: ((statusCode: Int!, data: NSData!) -> Void), errorHandler: (error: ErrorType) -> Void) {
		var appVersion = "Unknown"
		if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
			appVersion = version
		}
		let systemVersion = UIDevice.currentDevice().systemVersion
		let deviceName = UIDevice().deviceType.rawValue
		let userAgent = "Releasify/\(appVersion) (iOS/\(systemVersion); \(deviceName))"
		let request = NSMutableURLRequest(URL:url)
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
				switch (error!.code) {
				case -1004:
					errorHandler(error: Error.CannotConnectToHost)
				case -1005:
					errorHandler(error: Error.NetworkConnectionLost)
				case -1006:
					errorHandler(error: Error.DNSLookupFailed)
				case -1009:
					errorHandler(error: Error.NoInternetConnection)
				default:
					errorHandler(error: Error.FailedRequest)
				}
				return
			}
			guard let response = response as? NSHTTPURLResponse else {
				errorHandler(error: Error.InvalidHTTPResponse)
				return
			}
			if self.appDelegate.debug { print("HTTP status code: \(response.statusCode)") }
			successHandler(statusCode: response.statusCode, data: data)
		})
	}
}
