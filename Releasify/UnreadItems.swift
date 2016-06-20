//
//  UnreadItems.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/19/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

final class UnreadItems {
	static let sharedInstance = UnreadItems()
	private let objectFile = documents + "/unreadList.archive"
	private let rootKey = "unreadList"
	var list: [Int]!

	// Add new item to list
	func addItem(ID: Int) {
		if !list.contains(ID) {
			list.append(ID)
		}
	}

	// Clear the list
	func clear() {
		list = [Int]()
		save()
	}

	// Remove item from list
	func removeItem(itemID: Int) -> Bool {
		for (index, item) in list.enumerate() {
			if item == itemID {
				list.removeAtIndex(index)
				return true
			}
		}
		return false
	}

	// Load list
	func load() {
		list = [Int]()
		if let data = NSData(contentsOfFile: objectFile) {
			let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
			list = unarchiver.decodeObjectForKey(rootKey) as? [Int]
			unarchiver.finishDecoding()
		}
	}

	// Save list
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
