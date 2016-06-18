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
	func add(album: Album) {
		if !isFavorite(album) {
			list.append(album)
		}
	}

	// MARK: - Clear the list
	func clearList() {
		list = [Album]()
		save()
	}

	// MARK: - Check if album is present in list
	func isFavorite(album: Album) -> Bool {
		for favorite in list {
			if favorite.ID == album.ID {
				return true
			}
		}
		return false
	}
	
	// MARK: - Remove item from list with known index
	func remove(index: Int) {
		list.removeAtIndex(index)
		save()
	}

	// MARK: - Remove item from list with unknown index
	func removeFavoriteIfExists(albumID: Int) -> Bool {
		for (key, value) in list.enumerate() {
			if value.ID == albumID {
				remove(key)
				return true
			}
		}
		return false
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
