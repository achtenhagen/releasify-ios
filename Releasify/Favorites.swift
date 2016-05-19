//
//  Favorites.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/13/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class Favorites {
	static let sharedInstance = Favorites()
	private let objectFile = documents + "/favList.archive"
	private let rootKey = "favList"
	var list: [Album]!
	
	// MARK: - Add new item to list
	func addFavorite(album: Album) {
		var exists = false
		for favorite in list {
			if favorite.ID == album.ID {
				exists = true
				break
			}
		}
		if !exists {
			list.append(album)
		}
	}

	// MARK: - Clear the list
	func clearList() {
		list = [Album]()
		save()
	}
	
	// MARK: - Remove item from list with known index
	func removeFavorite(index: Int) {
		list.removeAtIndex(index)
	}

	// MARK: - Remove item from list with unknown index
	func removeFavoriteIfExists(album: Album) {
		for (key, value) in list.enumerate() {
			if value.ID == album.ID {
				removeFavorite(key)
			}
		}
	}
	
	// MARK: - Load favorites list
	func load() {
		list = [Album]()
		if let data = NSData(contentsOfFile: objectFile) {
			let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
			list = unarchiver.decodeObjectForKey(rootKey) as? [Album]
			unarchiver.finishDecoding()
		}
	}
	
	// MARK: - Save favorites list
	func save() {
		let data = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
		archiver.encodeObject(list, forKey: rootKey)
		archiver.finishEncoding()
		let success = data.writeToFile(objectFile, atomically: true)
		if !success {
			fatalError("Failed to unarchive object!")
		}
	}
}
