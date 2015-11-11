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
	
	func getProgress (dateAdded: Double) -> Float {
		return Float((Double(NSDate().timeIntervalSince1970) - Double(dateAdded)) / (Double(releaseDate) - Double(dateAdded)))
	}
}