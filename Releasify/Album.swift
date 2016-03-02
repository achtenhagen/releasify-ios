//
//  Album.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/31/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import Foundation

struct Album {
	var ID: Int
	var title: String
	var artistID: Int
	var releaseDate: Double
	var artwork: String
	var explicit: Int
	var copyright: String
	var iTunesUniqueID: Int
	var iTunesUrl: String
	var created: Int
	
	// MARK: - Return the decimal progress relative to the date added
	func getProgressSinceDate(dateAdded: Double) -> Float {
		return Float((Double(NSDate().timeIntervalSince1970) - Double(dateAdded)) / (Double(releaseDate) - Double(dateAdded)))
	}
	
	// MARK: - Return the formatted date posted
	func getDatePosted (dateAdded: Int) -> String {
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
	
	// MARK: - Return the boolean value whether the object is available
	func isAvailable() -> Bool {
		return releaseDate - NSDate().timeIntervalSince1970 > 0 ? false : true
	}
}