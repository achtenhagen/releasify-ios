//
//  Artist.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 9/7/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import Foundation

struct Artist {
	var ID: Int
	var title: String
	var iTunesUniqueID: Int
	var avatar: String?

	init(ID: Int, title: String, iTunesUniqueID: Int, avatar: String? = nil) {
		self.ID = ID
		self.title = title
		self.iTunesUniqueID = iTunesUniqueID
		self.avatar = avatar
	}
}