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

	// MARK: - Add new item to list
	func addItem(ID: Int) {
		if !list.contains(ID) {
			list.append(ID)
		}
	}

	// MARK: - Clear the list
	func clearList() {
		list = [Int]()
		save()
	}

	// MARK: - Remove item from list
	func removeItem(ID: Int) -> Bool {
		for (index, item) in list.enumerate() {
			if item == ID {
				list.removeAtIndex(index)
				return true
			}
		}
		return false
	}

	// MARK: - Load list
	func load() {
		list = [Int]()
		if let data = NSData(contentsOfFile: objectFile) {
			let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
			list = unarchiver.decodeObjectForKey(rootKey) as? [Int]
			unarchiver.finishDecoding()
		}
	}

	// MARK: - Save list
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
