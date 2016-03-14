//
//  Favorites.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/13/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

let objectFile = documents + "/favList.archive"
final class Favorites {
	static let sharedInstance = Favorites()
	private let rootKey = "favList"
	var list: [Album]!
	
	func addFavorite (album: Album) {
		var exists = false
		for favorite in list {
			if favorite.ID == album.ID {
				exists = true
				break
			}
		}
		if !exists {
			list.append(album)
			print("Added new item")
		}
	}
	
	func deleteFavorite (index: Int) {
		list.removeAtIndex(index)
	}
	
	// MARK: - Get favorite albums
	func load () {
		list = [Album]()
		if let data = NSData(contentsOfFile: objectFile) {
			let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
			list = unarchiver.decodeObjectForKey(rootKey) as? [Album]
			unarchiver.finishDecoding()
			print(list)
		}
	}
	
	func save () {
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
