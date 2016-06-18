//
//  SearchResult.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/18/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import Foundation

struct SearchResult {
	var artist: Artist!
	var albums: [Album]?

	init(artist: Artist, albums: [Album]? = nil) {
		self.artist = artist
		self.albums = albums
	}
}
