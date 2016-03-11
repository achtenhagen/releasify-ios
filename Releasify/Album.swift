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
	func getFormattedDatePosted (dateAdded: Int) -> String {
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
	func getFormattedReleaseDate () -> String {
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
	
	// MARK: - Compute the floor of 2 numbers
	func component(x: Double, v: Double) -> Double {
		return floor(x / v)
	}
	
	// MARK: - Return the boolean value whether the album has been released
	func isAvailable() -> Bool {
		return releaseDate - NSDate().timeIntervalSince1970 > 0 ? false : true
	}
}
