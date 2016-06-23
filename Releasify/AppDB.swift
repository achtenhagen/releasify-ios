//
//  AppDB.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 3/31/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

let debug = true
let documents = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, .UserDomainMask, true)[0] as String
let databasePath = documents + "/db.sqlite"
let artworkDirectoryPath = documents + "/Caches"

final class AppDB {
	static let sharedInstance = AppDB()
	var database: COpaquePointer = nil
	var artists: [Artist]!
	var albums: [Album]!
	
	private func connected() -> Bool {
		return sqlite3_open(databasePath, &database) == SQLITE_OK
	}
	
	private func disconnect() {
		sqlite3_close(database)
		database = nil
	}

	// MARK: - Initialization

	init() {
		if !connected() { fatalError("Unable to connect to database") }
		artists = [Artist]()
		albums  = [Album]()
		var errMsg: UnsafeMutablePointer<Int8> = nil
		var query = "CREATE TABLE IF NOT EXISTS artists (id INTEGER PRIMARY KEY, title VARCHAR(100) NOT NULL, iTunes_unique_id INTEGER, last_updated INTEGER, created INTEGER)"
		sqlite3_exec(database, query, nil, nil, &errMsg)
		
		query = "CREATE TABLE IF NOT EXISTS albums (id INTEGER PRIMARY KEY, title varchar(100) NOT NULL, release_date int(11) DEFAULT NULL, artwork varchar(250) DEFAULT NULL, artwork_url varchar(250) DEFAULT NULL, explicit tinyint(1) NOT NULL DEFAULT '0', copyright varchar(250) DEFAULT NULL, iTunes_unique_id int(11) DEFAULT NULL, iTunes_url varchar(250) DEFAULT NULL, created int(11) NOT NULL)"
		sqlite3_exec(database, query, nil, nil, &errMsg)
		
		query = "CREATE TABLE IF NOT EXISTS album_artists (id INTEGER PRIMARY KEY AUTOINCREMENT, album_id int(11) NOT NULL, artist_id int(11) NOT NULL, created int(11) NOT NULL)"
		sqlite3_exec(database, query, nil, nil, &errMsg)
		
		query = "CREATE TABLE IF NOT EXISTS pending_artists (id INTEGER PRIMARY KEY, created int(11) NOT NULL)"
		sqlite3_exec(database, query, nil, nil, &errMsg)
		
		if !NSFileManager.defaultManager().fileExistsAtPath(artworkDirectoryPath) {
			do {
				try NSFileManager.defaultManager().createDirectoryAtPath(artworkDirectoryPath, withIntermediateDirectories: false, attributes: nil)
			} catch {
				if debug { print("Error: Unable to create artwork directory!") }
			}
		}
		disconnect()
	}

	// MARK: -  Albums
	
	// Add new album
	func addAlbum(album: Album) -> Int {
		if !connected() { return 0 }
		var newAlbumID = 0
		let albumExistsQuery = "SELECT COUNT(id) FROM albums WHERE id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, albumExistsQuery, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(album.ID))
			var numRows = 0
			if sqlite3_step(statement) == SQLITE_ROW {
				numRows = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
			if numRows > 0 { return 0 }
			let newAlbumQuery = "INSERT INTO albums (id, title, release_date, artwork, artwork_url, explicit, copyright, iTunes_unique_id, iTunes_url, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
			statement = nil
			if sqlite3_prepare_v2(database, newAlbumQuery, -1, &statement, nil) == SQLITE_OK {
				sqlite3_bind_int(statement, 1, Int32(album.ID))
				sqlite3_bind_text(statement, 2, (album.title as NSString).UTF8String, -1, nil)
				sqlite3_bind_int(statement, 3, Int32(album.releaseDate))
				sqlite3_bind_text(statement, 4, (album.artwork as NSString).UTF8String, -1, nil)
				sqlite3_bind_text(statement, 5, (album.artworkUrl! as NSString).UTF8String, -1, nil)
				sqlite3_bind_int(statement, 6, Int32(album.explicit))
				sqlite3_bind_text(statement, 7, (album.copyright as NSString).UTF8String, -1, nil)
				sqlite3_bind_int(statement, 8, Int32(album.iTunesUniqueID))
				sqlite3_bind_text(statement, 9, (album.iTunesUrl as NSString).UTF8String, -1, nil)
				sqlite3_bind_int(statement, 10, Int32(album.created))
				if sqlite3_step(statement) == SQLITE_DONE {
					newAlbumID = Int(sqlite3_last_insert_rowid(database))
				}
				sqlite3_finalize(statement)
				if newAlbumID > 0 {
					addContributingArtist(album.ID, artistID: album.artistID)
				}
			}
		}
		disconnect()
		return newAlbumID
	}
	
	// Get album by ID
	func getAlbumBy(ID: Int) -> Album? {
		if !connected() { return nil }
		var album: Album?
		let query = "SELECT * FROM albums WHERE id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(ID))
			if sqlite3_step(statement) != SQLITE_ROW {
				if debug { print("Failed to get album from db.") }
				disconnect()
				return nil
			}
			let ID = Int(sqlite3_column_int(statement, 0))
			let albumTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
			let releaseDate = Double(sqlite3_column_int(statement, 2))
			let created = Int(sqlite3_column_int(statement, 9))
			let artwork = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))
			let artworkUrl = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 4)))
			let explicit = Int(sqlite3_column_int(statement, 5))
			let copyright = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 6)))
			let iTunesUniqueID = Int(sqlite3_column_int(statement, 7))
			let iTunesURL = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 8)))
			album = Album(ID: ID, title: albumTitle!, artistID: getAlbumArtistID(ID), releaseDate: releaseDate,
			              artwork: artwork!, artworkUrl: artworkUrl!, explicit: explicit, copyright: copyright!,
			              iTunesUniqueID: iTunesUniqueID, iTunesUrl: iTunesURL!, created: created)
			sqlite3_finalize(statement)
		}
		disconnect()
		return album
	}
	
	// Get albums
	func getAlbums() {
		albums = [Album]()
		if let upcomingAlbums = getAlbumsComponent("SELECT * FROM albums ORDER BY created DESC LIMIT 100") {
			albums.appendContentsOf(upcomingAlbums)
		}
		if debug { print("Albums in db: \(albums!.count)") }
	}
	
	// Get albums by artist ID
	func getAlbumsBy(artistID: Int = 0) -> [Album]? {
		if artistID == 0 { return nil }
		let query = "SELECT * FROM albums WHERE id IN (SELECT album_id FROM album_artists WHERE artist_id = \(artistID))"
		guard let artistAlbums = getAlbumsComponent(query) else { return nil }
		return artistAlbums
	}
	
	// Get albums based on input query
	func getAlbumsComponent(query: String) -> [Album]? {
		if !connected() { return nil }
		var tmpAlbums: [Album] = [Album]()
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) != SQLITE_OK {
			disconnect()
			return nil
		}
		while sqlite3_step(statement) == SQLITE_ROW {
			let ID = Int(sqlite3_column_int(statement, 0))
			let albumTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
			let releaseDate = Double(sqlite3_column_int(statement, 2))
			let created = Int(sqlite3_column_int(statement, 9))
			let artwork = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))
			var artworkUrl = String()
			if let url = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 4))) {
				artworkUrl = url
			}
			let explicit = Int(sqlite3_column_int(statement, 5))
			let copyright = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 6)))
			let iTunesUniqueID = Int(sqlite3_column_int(statement, 7))
			let iTunesURL = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 8)))
			tmpAlbums.append(Album(ID: ID, title: albumTitle!, artistID: getAlbumArtistID(ID), releaseDate: releaseDate,
				artwork: artwork!, artworkUrl: artworkUrl, explicit: explicit, copyright: copyright!, iTunesUniqueID: iTunesUniqueID,
				iTunesUrl: iTunesURL!, created: created))
		}
		sqlite3_finalize(statement)
		disconnect()
		return tmpAlbums
	}
	
	// Get date added property from album ID
	func getAlbumDateAdded(albumID: Int) -> Double? {
		if !connected() { return nil }
		var created = 0
		let query = "SELECT created FROM albums WHERE id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(albumID))
			if sqlite3_step(statement) == SQLITE_ROW {
				created = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
		}
		disconnect()
		return Double(created)
	}

	// Return the album to be displayed in the today widget
	func getWidgetAlbum() -> Album? {
		if !connected() { return nil }
		var album: Album?
		let timestamp = String(Int(NSDate().timeIntervalSince1970))
		let query = "SELECT * FROM albums WHERE release_date - \(timestamp) > 0 ORDER BY release_date ASC LIMIT 1"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			if sqlite3_step(statement) != SQLITE_ROW {
				if debug { print("Failed to get album from db.") }
				disconnect()
				return nil
			}
			let ID = Int(sqlite3_column_int(statement, 0))
			let albumTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
			let releaseDate = Double(sqlite3_column_int(statement, 2))
			let created = Int(sqlite3_column_int(statement, 9))
			let artwork = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))
			let artworkUrl = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 4)))
			let explicit = Int(sqlite3_column_int(statement, 5))
			let copyright = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 6)))
			let iTunesUniqueID = Int(sqlite3_column_int(statement, 7))
			let iTunesURL = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 8)))
			album = Album(ID: ID, title: albumTitle!, artistID: getAlbumArtistID(ID), releaseDate: releaseDate,
				artwork: artwork!, artworkUrl: artworkUrl!, explicit: explicit, copyright: copyright!, iTunesUniqueID: iTunesUniqueID,
				iTunesUrl: iTunesURL!, created: created)
			sqlite3_finalize(statement)
		}
		disconnect()
		return album
	}
	
	// Lookup album
	func lookupAlbumBy(albumID: Int) -> Bool {
		if !connected() { return false }
		var numRows = 0
		let query = "SELECT COUNT(id) FROM albums WHERE id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(albumID))
			if sqlite3_step(statement) == SQLITE_ROW {
				numRows = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
		}
		disconnect()
		return numRows == 1
	}

	// Remove album
	func removeAlbum(albumID: Int, index: Int? = nil) {
		if !connected() { return }
		let query = "DELETE FROM albums WHERE id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(albumID))
			if sqlite3_step(statement) == SQLITE_DONE {
				if let i = index {
					albums.removeAtIndex(i)
				}
			} else {
				if debug { print("SQLite: Failed to delete from `albums`.") }
			}
			sqlite3_finalize(statement)
		}
		disconnect()
	}
	
	// Remove albums that are older than 4 weeks
	func removeExpiredAlbums() {
		if !connected() { return }
		var expiredAlbums = [Int:String]()
		let timestamp = String(stringInterpolationSegment: Int(NSDate().timeIntervalSince1970))
		var query = "SELECT id, artwork FROM albums WHERE \(timestamp) - release_date > 2628000"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			while sqlite3_step(statement) == SQLITE_ROW {
				let ID = Int(sqlite3_column_int(statement, 0))
				let artwork = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
				expiredAlbums[ID] = artwork!
			}
			sqlite3_finalize(statement)
		}
		var albumList = String()
		var albumIndex = 0
		for album in expiredAlbums {
			albumIndex += 1
			deleteArtwork(album.1)
			albumList += String(album.0)
			if albumIndex != expiredAlbums.count { albumList += ", " }
		}
		if expiredAlbums.count > 0 {
			query = "DELETE FROM albums WHERE id IN (\(albumList))"
			if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
				if sqlite3_step(statement) != SQLITE_DONE {
					if debug { print("SQLite: Failed to delete from `albums`.") }
					return
				}
				sqlite3_finalize(statement)
			}
		}
		disconnect()
	}
	
	// MARK: - Artists

	// Add new artist
	func addArtist(ID: Int, artistTitle: String, iTunesUniqueID: Int) -> Int {
		if !connected() { return 0 }
		var newItemID = 0
		let timeStamp = Int32(NSDate().timeIntervalSince1970)
		let artistExistsQuery = "SELECT COUNT(id) FROM artists WHERE iTunes_unique_id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, artistExistsQuery, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(iTunesUniqueID))
			var numRows = 0
			if sqlite3_step(statement) == SQLITE_ROW {
				numRows = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
			if numRows == 0 {
				let query = "INSERT INTO artists (id, title, iTunes_unique_id, last_updated, created) VALUES (?, ?, ?, ?, ?)"
				statement = nil
				if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
					sqlite3_bind_int(statement, 1, Int32(ID))
					sqlite3_bind_text(statement, 2, (artistTitle as NSString).UTF8String, -1, nil)
					sqlite3_bind_int(statement, 3, Int32(iTunesUniqueID))
					sqlite3_bind_int(statement, 4, 0)
					sqlite3_bind_int(statement, 5, timeStamp)
					if sqlite3_step(statement) == SQLITE_DONE {
						newItemID = Int(sqlite3_last_insert_rowid(database))
					}
					sqlite3_finalize(statement)
				}
			}
		}
		disconnect()
		return newItemID
	}
	
	// Link album with artist
	func addContributingArtist(albumID: Int, artistID: Int) {
		if !connected() { return }
		let timeStamp = Int32(NSDate().timeIntervalSince1970)
		var statement: COpaquePointer = nil
		var query = "SELECT COUNT(artist_id) FROM album_artists WHERE album_id = ? AND artist_id = ?"
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(albumID))
			sqlite3_bind_int(statement, 2, Int32(artistID))
			var numRows = 0
			if sqlite3_step(statement) == SQLITE_ROW {
				numRows = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
			if numRows == 0 {
				query = "INSERT INTO album_artists (album_id, artist_id, created) VALUES (?, ?, ?)"
				if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
					sqlite3_bind_int(statement, 1, Int32(albumID))
					sqlite3_bind_int(statement, 2, Int32(artistID))
					sqlite3_bind_int(statement, 3, timeStamp)
					if sqlite3_step(statement) != SQLITE_DONE {
						if debug { print("Failed to a contributing artist.") }
					}
					sqlite3_finalize(statement)
				}
			}
		}
		disconnect()
	}
	
	// Add pending artist to be removed
	func addPendingArtist(ID: Int) {
		if !connected() { return }
		let timestamp = Int32(NSDate().timeIntervalSince1970)
		let artistExistsQuery = "SELECT COUNT(id) FROM pending_artists WHERE id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, artistExistsQuery, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(ID))
			var numRows = 0
			if sqlite3_step(statement) == SQLITE_ROW {
				numRows = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
			if numRows == 0 {
				let query = "INSERT INTO pending_artists (id, created) VALUES (?, ?)"
				statement = nil
				if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
					sqlite3_bind_int(statement, 1, Int32(ID))
					sqlite3_bind_int(statement, 2, timestamp)
					if sqlite3_step(statement) != SQLITE_DONE {
						if debug { print("Failed to insert pending artist.") }
					}
					sqlite3_finalize(statement)
				}
			}
		}
		disconnect()
		if debug { print("Successfully added a pending artist.") }
	}
	
	// Get album artist from album ID
	func getAlbumArtist(albumID: Int) -> String? {
		if !connected() { return nil }
		var artistTitle = String()
		let query = "SELECT title FROM artists WHERE id IN (SELECT artist_id FROM album_artists WHERE album_id = ?)"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(albumID))
			if sqlite3_step(statement) == SQLITE_ROW {
				artistTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 0)))!
			}
			sqlite3_finalize(statement)
		}
		disconnect()
		return artistTitle
	}
	
	// Get artist ID from album ID
	func getAlbumArtistID(albumID: Int) -> Int {
		if !connected() { return 0 }
		var artistID = 0
		let query = "SELECT artist_id FROM album_artists WHERE album_id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(albumID))
			if sqlite3_step(statement) == SQLITE_ROW {
				artistID = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
		}
		disconnect()
		return artistID
	}
	
	// Get artist ID from artist iTunes ID
	func getArtistByUniqueID(uniqueID: Int) -> Int {
		if !connected() { return 0 }
		var artistID = 0
		let query = "SELECT id FROM artists WHERE iTunes_unique_id = ?"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(uniqueID))
			if sqlite3_step(statement) == SQLITE_ROW {
				artistID = Int(sqlite3_column_int(statement, 0))
			}
			sqlite3_finalize(statement)
		}
		disconnect()
		return artistID
	}
	
	// Get all artists
	func getArtists() {
		if !connected() { return }
		artists = [Artist]()
		let query = "SELECT id,title,iTunes_unique_id,last_updated FROM artists ORDER BY title COLLATE NOCASE"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			while sqlite3_step(statement) == SQLITE_ROW {
				let IDRow = Int(sqlite3_column_int(statement, 0))
				let artistRow = sqlite3_column_text(statement, 1)
				let artistTitle = String.fromCString(UnsafePointer<CChar>(artistRow))
				let uniqueID = Int(sqlite3_column_int(statement, 2))
				let avatar = "artist_0" + String(arc4random_uniform(5) + 1)
				artists.append(Artist(ID: IDRow, title: artistTitle!, iTunesUniqueID: uniqueID, avatar: avatar))
			}
			sqlite3_finalize(statement)
		}
		if debug { print("Artists in db: \(artists.count)") }
		disconnect()
	}
	
	// Get all artists pending removal
	func getPendingArtists() -> [Int] {
		if !connected() { return [Int]() }
		var pendingArtists = [Int]()
		let query = "SELECT id FROM pending_artists"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			while sqlite3_step(statement) == SQLITE_ROW {
				pendingArtists.append(Int(sqlite3_column_int(statement, 0)))
			}
			sqlite3_finalize(statement)
		}
		if debug { print("Pending artists in db: \(pendingArtists.count)") }
		disconnect()
		return pendingArtists
	}

	// Remove artist
	func removeArtist(ID: Int, completion: ((albumIDs: [Int]) -> Void)) {
		if !connected() { return }
		var albumIDs = [Int]()
		var query = "SELECT id,artwork FROM albums WHERE id IN (SELECT album_id FROM album_artists WHERE artist_id = ?)"
		var statement: COpaquePointer = nil
		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(ID))
			while sqlite3_step(statement) == SQLITE_ROW {
				let albumID = Int(sqlite3_column_int(statement, 0))
				let artwork = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
				albumIDs.append(albumID)
				deleteArtwork(artwork!)
			}
			sqlite3_finalize(statement)
		}

		query = "DELETE FROM albums WHERE id IN (SELECT album_id FROM album_artists WHERE artist_id = ?)"
		statement = nil

		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(ID))
			if sqlite3_step(statement) != SQLITE_DONE {
				if debug { print("SQLite: Failed to delete from `albums`.") }
			}
			sqlite3_finalize(statement)
		}

		query = "DELETE FROM album_artists WHERE artist_id = ?"
		statement = nil

		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(ID))
			if sqlite3_step(statement) != SQLITE_DONE {
				if debug { print("SQLite: Failed to delete from `album_artists`.") }
			}
			sqlite3_finalize(statement)
		}

		query = "DELETE FROM artists WHERE id = ?"
		statement = nil

		if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
			sqlite3_bind_int(statement, 1, Int32(ID))
			if sqlite3_step(statement) != SQLITE_DONE {
				if debug { print("SQLite: Failed to delete from `artists`.") }
			}
			sqlite3_finalize(statement)
		}
		disconnect()
		completion(albumIDs: albumIDs)
	}

	// MARK: - Miscellaneous

	// Flush all tables
	func reset() {
		truncate("artists")
		truncate("pending_artists")
		truncate("albums")
		truncate("album_artists")
	}

	// Truncate table
	private func truncate(name: String) {
		if !connected() { return }
		let query = "DELETE FROM \(name)"
		var errMsg: UnsafeMutablePointer<Int8> = nil
		if sqlite3_exec(database, query, nil, nil, &errMsg) != SQLITE_OK {
			if debug { print("SQLite: \(String.fromCString(UnsafePointer<Int8>(errMsg)))") }
		}
		disconnect()
	}

	// Upgrade database to version 2
	func upgrade_db_v2() {
		if !connected() { fatalError("Unable to connect to database") }
		if debug { print("Begin upgrade") }
		var errMsg: UnsafeMutablePointer<Int8> = nil
		var query = "DROP TABLE albums"
		sqlite3_exec(database, query, nil, nil, &errMsg)
		// Create albums table with updated schema
		query = "CREATE TABLE IF NOT EXISTS albums (id INTEGER PRIMARY KEY, title varchar(100) NOT NULL, release_date int(11) DEFAULT NULL, artwork varchar(250) DEFAULT NULL, artwork_url varchar(250) DEFAULT NULL, explicit tinyint(1) NOT NULL DEFAULT '0', copyright varchar(250) DEFAULT NULL, iTunes_unique_id int(11) DEFAULT NULL, iTunes_url varchar(250) DEFAULT NULL, created int(11) NOT NULL)"
		sqlite3_exec(database, query, nil, nil, &errMsg)
		disconnect()

		// Delete old artwork
		let fileManager = NSFileManager.defaultManager()
		if let enumerator = fileManager.enumeratorAtPath(documents + "/artwork") {
			while let element = enumerator.nextObject() as? String {
				if element.hasSuffix("jpg") {
					let filePath = documents + "/artwork/" + element
					do {
						try NSFileManager.defaultManager().removeItemAtPath(filePath)
					} catch _ {
						// Log to blackbox
					}
				}
			}
		}
		if debug { print("Upgrade complete") }
	}
}
