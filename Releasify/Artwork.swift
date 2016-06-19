//
//  Artwork.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/18/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import UIKit

// MARK: - Artwork

// Add album artwork
func addArtwork(hash: String, artwork: UIImage) -> Bool {
	let artworkPath = artworkDirectoryPath + "/\(hash).jpg"
	if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
		deleteArtwork(hash)
	}
	return UIImageJPEGRepresentation(artwork, 1.0)!.writeToFile(artworkPath, atomically: true)
}

// Delete album artwork
func deleteArtwork(hash: String) {
	let artworkPath = artworkDirectoryPath + "/\(hash).jpg"
	if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
		do {
			try NSFileManager.defaultManager().removeItemAtPath(artworkPath)
		} catch _ {
			if debug { print("Failed to remove artwork: \(hash).") }
		}
	}
}

// MARK: - Check album artwork file path
func checkArtwork(hash: String) -> Bool {
	let artworkPath = artworkDirectoryPath + "/\(hash).jpg"
	return NSFileManager.defaultManager().fileExistsAtPath(artworkPath)
}

// MARK: - Check album artwork file path and return image
func getArtwork(hash: String) -> UIImage? {
	let artworkPath = artworkDirectoryPath + "/\(hash).jpg"
	if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) { return UIImage(contentsOfFile: artworkPath)! }
	return nil
}