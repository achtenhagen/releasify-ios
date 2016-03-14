//
//  Favorites.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/13/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

let objectFile = documents + "/favList.archive"
final class Favorites : NSObject, NSCoding {
	static let sharedInstance = Favorites()
	private let rootKey = "favList"
	var list: [Album]!
	
	override init() {
		
	}
	
	required init(coder decoder: NSCoder) {
		list = decoder.decodeObjectForKey(rootKey) as? [Album]
		print(list)
	}
	
	func encodeWithCoder(coder: NSCoder) {
		if list != nil {
			coder.encodeObject(list, forKey: rootKey)
		}
	}
	
	func addFavorite (album: Album) {
		list.append(album)
	}
	
	func deleteFavorite (index: Int) {
		list.removeAtIndex(index)
	}
	
	// MARK: - Get favorite albums
	func getFavorites () {
		list = [Album]()
		if let data = NSData(contentsOfFile: objectFile) {
			let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
			list = unarchiver.decodeObjectForKey(rootKey) as? [Album]
			unarchiver.finishDecoding()
		}
	}
	
	func storeFavorites () {
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
