//
//  Album.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/31/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import Foundation

class Album: NSObject, NSCoding {
	var ID: Int
	var title: String
	var artistID: Int
	var releaseDate: Double
	var artwork: String
	var artworkUrl: String?
	var explicit: Int
	var copyright: String
	var iTunesUniqueID: Int
	var iTunesUrl: String
	var created: Int
	
	init(ID: Int, title: String, artistID: Int, releaseDate: Double, artwork: String, artworkUrl: String,
	     explicit: Int, copyright: String, iTunesUniqueID: Int, iTunesUrl: String, created: Int) {
			self.ID = ID
			self.title = title
			self.artistID = artistID
			self.releaseDate = releaseDate
			self.artwork = artwork
			self.artworkUrl = artworkUrl
			self.explicit = explicit
			self.copyright = copyright
			self.iTunesUniqueID = iTunesUniqueID
			self.iTunesUrl = iTunesUrl
			self.created = created
	}
	
	required init(coder decoder: NSCoder) {
		self.ID = decoder.decodeObjectForKey("ID") as! Int
		self.title = decoder.decodeObjectForKey("title") as! String
		self.artistID = decoder.decodeObjectForKey("artistID") as! Int
		self.releaseDate = decoder.decodeObjectForKey("releaseDate") as! Double
		self.artwork = decoder.decodeObjectForKey("artwork") as! String
		if let url = decoder.decodeObjectForKey("artworkUrl") as? String { self.artworkUrl = url }
		self.explicit = decoder.decodeObjectForKey("explicit") as! Int
		self.copyright = decoder.decodeObjectForKey("copyright") as! String
		self.iTunesUniqueID = decoder.decodeObjectForKey("iTunesUniqueID") as! Int
		self.iTunesUrl = decoder.decodeObjectForKey("iTunesUrl") as! String
		self.created = decoder.decodeObjectForKey("created") as! Int
	}
	
	func encodeWithCoder(coder: NSCoder) {
		coder.encodeObject(ID, forKey: "ID")
		coder.encodeObject(title, forKey: "title")
		coder.encodeObject(artistID, forKey: "artistID")
		coder.encodeObject(releaseDate, forKey: "releaseDate")
		coder.encodeObject(artwork, forKey: "artwork")
		coder.encodeObject(artworkUrl, forKey: "artworkUrl")
		coder.encodeObject(explicit, forKey: "explicit")
		coder.encodeObject(copyright, forKey: "copyright")
		coder.encodeObject(iTunesUniqueID, forKey: "iTunesUniqueID")
		coder.encodeObject(iTunesUrl, forKey: "iTunesUrl")
		coder.encodeObject(created, forKey: "created")
	}
	
	// MARK: - Return the decimal progress relative to the date added
	func getProgressSinceDate(dateAdded: Double) -> Float {
		return Float((Double(NSDate().timeIntervalSince1970) - Double(dateAdded)) / (Double(releaseDate) - Double(dateAdded)))
	}
	
	// MARK: - Return the formatted date posted
	func getFormattedDatePosted(dateAdded: Int) -> String {
		var timeDiff = Int(NSDate().timeIntervalSince1970) - dateAdded
		if timeDiff < 60 {
			if timeDiff == 1 {
				return "1 second ago"
			} else if timeDiff > 1 {
				return "\(timeDiff) seconds ago"
			}
			return "just a moment ago"
		}
		timeDiff = timeDiff / 60
		if timeDiff < 60 {
			if timeDiff == 1 { return "1 minute ago" }
			return "\(timeDiff) minutes ago"
		} else {
			timeDiff = timeDiff / 60
			if timeDiff < 24 {
				if timeDiff == 1 { return "1 hour ago" }
				return "\(timeDiff) hours ago"
			}
		}		
		timeDiff = timeDiff / 24
		if timeDiff < 365 {
			if timeDiff / 7 >= 1 {
				timeDiff = timeDiff / 7
				if timeDiff == 1 { return "1 week ago" }
				return "\(timeDiff) weeks ago"
			} else {
				if timeDiff == 1 { return "yesterday" }
				return "\(timeDiff) days ago"
			}
		}
		return "a while ago"
	}
	
	// MARK: - Return the formatted release date
	func getFormattedReleaseDate() -> String {
		let timeDiff = releaseDate - NSDate().timeIntervalSince1970
		if timeDiff > 0 {
			let weeks   = component(Double(timeDiff), v: 7 * 24 * 60 * 60)
			let days    = component(Double(timeDiff), v: 24 * 60 * 60) % 7
			let hours   = component(Double(timeDiff),      v: 60 * 60) % 24
			let minutes = component(Double(timeDiff),           v: 60) % 60
			let seconds = component(Double(timeDiff),            v: 1) % 60
			if Int(weeks) > 0 {
				return Int(weeks) == 1 ? "\(Int(weeks)) week" : "\(Int(weeks)) weeks"
			} else if Int(days) > 0 && Int(days) <= 7 {
				return Int(days) == 1  ? "\(Int(days)) day" : "\(Int(days)) days"
			} else if Int(hours) > 0 && Int(hours) <= 24 {
				if Int(hours) >= 12 {
					return "Today"
				} else {
					return Int(hours) == 1 ? "\(Int(hours)) hour" : "\(Int(hours)) hours"
				}
			} else if Int(minutes) > 0 && Int(minutes) <= 60 {
				return "\(Int(minutes)) minute"
			} else if Int(seconds) > 0 && Int(seconds) <= 60 {
				return "\(Int(seconds)) second"
			}
		}
		let dateFormat = NSDateFormatter()
		dateFormat.dateFormat = "MMM dd"
		return dateFormat.stringFromDate(NSDate(timeIntervalSince1970: releaseDate))
	}

	// Return release date represented as 4 digit year
	func releaseDateAsYear(timestamp: Double) -> String {
		let dateFormat = NSDateFormatter()
		dateFormat.dateFormat = "yyyy"
		return dateFormat.stringFromDate(NSDate(timeIntervalSince1970: timestamp))
	}
	
	// MARK: - Compute the floor of 2 numbers
	func component(x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	// MARK: - Return the boolean value whether the album has been released
	func isReleased() -> Bool {
		return releaseDate - NSDate().timeIntervalSince1970 > 0 ? false : true
	}
}
