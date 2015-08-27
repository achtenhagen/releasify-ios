
import UIKit

let documents = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! NSString
let databasePath = documents.stringByAppendingPathComponent("db.sqlite")
let artworkDirectoryPath = documents.stringByAppendingPathComponent("artwork")

final class AppDB {
    
    static let sharedInstance = AppDB()
    
    struct Artist {
        var ID: Int
        var title: String
        var iTunesUniqueID: Int
    }
    
    var database: COpaquePointer = nil
    var result = Int32()
    var artists = [Artist]()
	var albums  = [Int:[Album]]()

    private func connected () -> Bool {
        return sqlite3_open(databasePath, &database) == SQLITE_OK
    }
    
    private func disconnect () {
        sqlite3_close(self.database)
       database = nil
    }
	
	init() {
		if connected() {
			var errMsg: UnsafeMutablePointer<Int8> = nil
			let artistTableQuery = "CREATE TABLE IF NOT EXISTS artists (id INTEGER PRIMARY KEY, title VARCHAR(100) NOT NULL, iTunes_unique_id INTEGER, last_updated INTEGER, created INTEGER)"
			sqlite3_exec(database, artistTableQuery, nil, nil, &errMsg)
			
			let albumTableQuery = "CREATE TABLE IF NOT EXISTS albums (id INTEGER PRIMARY KEY, title varchar(100) NOT NULL, release_date int(11) DEFAULT NULL, artwork varchar(250) DEFAULT NULL, explicit tinyint(1) NOT NULL DEFAULT '0', copyright varchar(250) DEFAULT NULL, iTunes_unique_id int(11) DEFAULT NULL, iTunes_url varchar(250) DEFAULT NULL, created int(11) NOT NULL)"
			sqlite3_exec(database, albumTableQuery, nil, nil, &errMsg)
			
			let albumArtistTableQuery = "CREATE TABLE IF NOT EXISTS album_artists (id INTEGER PRIMARY KEY AUTOINCREMENT, album_id int(11) NOT NULL, artist_id int(11) NOT NULL, created int(11) NOT NULL)"
			sqlite3_exec(database, albumArtistTableQuery, nil, nil, &errMsg)
			
			let pendingArtistsTableQuery = "CREATE TABLE IF NOT EXISTS pending_artists (id INTEGER PRIMARY KEY, created int(11) NOT NULL)"
			sqlite3_exec(database, pendingArtistsTableQuery, nil, nil, &errMsg)
			
			if !NSFileManager.defaultManager().fileExistsAtPath(artworkDirectoryPath) {
				NSFileManager.defaultManager().createDirectoryAtPath(artworkDirectoryPath, withIntermediateDirectories: false, attributes: nil, error: nil)
			}
			disconnect()
			removeExpiredAlbums()
		}
	}
	
    // -- Albums -- //
	
    func addAlbum (albumItem: Album) -> Int {
        var newAlbumID = 0
        if connected() {
            let albumExistsQuery = "SELECT COUNT(id) FROM albums WHERE id = ?"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, albumExistsQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(albumItem.ID))
                var numRows: Int32 = 0
                if sqlite3_step(statement) == SQLITE_ROW {
                    numRows = sqlite3_column_int(statement, 0)
                }
                sqlite3_finalize(statement)
                if numRows == 0 {
                    let newAlbumQuery = "INSERT INTO albums (id, title, release_date, artwork, explicit, copyright, iTunes_unique_id, iTunes_url, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
                    statement = nil
                    if sqlite3_prepare_v2(self.database, newAlbumQuery, -1, &statement, nil) == SQLITE_OK {
                        sqlite3_bind_int(statement, 1, Int32(albumItem.ID))
                        sqlite3_bind_text(statement, 2, NSString(string: albumItem.title).UTF8String, -1, nil)
                        sqlite3_bind_int(statement, 3, Int32(albumItem.releaseDate))
                        sqlite3_bind_text(statement, 4, NSString(string: albumItem.artwork).UTF8String, -1, nil)
                        sqlite3_bind_int(statement, 5, Int32(albumItem.explicit))
                        sqlite3_bind_text(statement, 6, NSString(string: albumItem.copyright).UTF8String, -1, nil)
                        sqlite3_bind_int(statement, 7, Int32(albumItem.iTunesUniqueID))
                        sqlite3_bind_text(statement, 8, NSString(string: albumItem.iTunesURL).UTF8String, -1, nil)
                        sqlite3_bind_int(statement, 9, Int32(albumItem.created))
                        if sqlite3_step(statement) == SQLITE_DONE {
                            newAlbumID = Int(sqlite3_last_insert_rowid(self.database))
                        }
                        sqlite3_finalize(statement)
                        if newAlbumID > 0 {
                            println("Album added successfully.")
                            addContributingArtist(albumItem.ID, artistID: albumItem.artistID)
                        }
                    }
                }
            }
            disconnect()
        }
        return newAlbumID
    }
    
    func deleteAlbum (albumID: Int) {
        if connected() {
            let query = "DELETE FROM albums WHERE id = ?"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(albumID))
            }
            if sqlite3_step(statement) != SQLITE_DONE {
                println("Failed to delete from db.")
            }
            sqlite3_finalize(statement)
            disconnect()
        }
    }
    
    func getAlbums () {
		albums = [Int:[Album]]()
        var timestamp = String(stringInterpolationSegment: Int(NSDate().timeIntervalSince1970))
        var query = "SELECT * FROM albums WHERE release_date - \(timestamp) > 0 ORDER BY release_date ASC LIMIT 64"
		getAlbumsComponent(0, query: query)
        query = "SELECT * FROM albums WHERE release_date - \(timestamp) < 0 AND release_date - \(timestamp) > -2592000 ORDER BY release_date DESC LIMIT 50"
        getAlbumsComponent(1, query: query)
        println("Albums in db: \(albums[0]!.count + albums[1]!.count)")
    }
    
	func getAlbumsComponent(section: Int, query: String) {
		albums[section] = [Album]()
        if connected() {
            var count = 0
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let ID = Int(sqlite3_column_int(statement, 0))
                    let albumTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
                    let releaseDate = Double(sqlite3_column_int(statement, 2))
                    let created = Int(sqlite3_column_int(statement, 8))
                    let artwork = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))
                    let explicit = Int(sqlite3_column_int(statement, 4))
                    let copyright = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 5)))
                    let iTunesUniqueID = Int(sqlite3_column_int(statement, 6))
                    let iTunesURL = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 7)))
                    albums[section]!.append(Album(
                        ID: ID,
                        title: albumTitle!,
                        artistID: getAlbumArtistId(ID),
                        releaseDate: releaseDate,
                        artwork: artwork!,
                        explicit: explicit,
                        copyright: copyright!,
                        iTunesUniqueID: iTunesUniqueID,
                        iTunesURL: iTunesURL!,
                        created: created)
                    )
                    count++
                }
                sqlite3_finalize(statement)
            }
            disconnect()
        }
    }
    
    func getAlbumDateAdded (albumID: Int) -> Double {
        var created: Int32 = 0
        if connected() {
            let query = "SELECT created FROM albums WHERE id = ?"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(albumID))
                if sqlite3_step(statement) == SQLITE_ROW {
                    created = sqlite3_column_int(statement, 0)
                }
                sqlite3_finalize(statement)
            }
            disconnect()
        }
        return Double(created)
    }
    
    func lookupAlbum (albumID: Int) -> Bool {
        var numRows: Int32 = 0
        if connected() {
            let query = "SELECT COUNT(id) FROM albums WHERE id = ?"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(albumID))
                if sqlite3_step(statement) == SQLITE_ROW {
                    numRows = sqlite3_column_int(statement, 0)
                }
                sqlite3_finalize(statement)
            }
            disconnect()
        }
        return numRows == 1
    }
	
	// Removes albums that are older than 4 weeks.
	func removeExpiredAlbums () {
		var expiredAlbums = [Int:String]()
		if connected() {
			let timestamp = String(stringInterpolationSegment: Int(NSDate().timeIntervalSince1970))
			var query = "SELECT id,artwork FROM albums WHERE \(timestamp) - release_date > 2592000"
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
				albumIndex++
				deleteArtwork(album.1)
				albumList += String(album.0)
				if albumIndex != expiredAlbums.count {
					albumList += ", "
				}
			}
			if expiredAlbums.count > 0 {
				query = "DELETE FROM albums WHERE id IN (\(albumList))"
				if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
					if sqlite3_step(statement) != SQLITE_DONE {
						println("Failed to remove expired albums.")
						return
					}
					sqlite3_finalize(statement)
				}
			}
			disconnect()
		}
	}
	
    // -- Artists -- //
	
    func addArtist (ID: Int, artistTitle: String, iTunesUniqueID: Int) -> Int {
        var newItemID = 0
        if connected() {
            let timeStamp = Int32(NSDate().timeIntervalSince1970)
            let artistExistsQuery = "SELECT COUNT(id) FROM artists WHERE iTunes_unique_id = ?"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, artistExistsQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(iTunesUniqueID))
                var numRows: Int32 = 0
                if sqlite3_step(statement) == SQLITE_ROW {
                    numRows = sqlite3_column_int(statement, 0)
                }
                sqlite3_finalize(statement)
                if numRows == 0 {
                    let query = "INSERT INTO artists (id, title, iTunes_unique_id, last_updated, created) VALUES (?, ?, ?, ?, ?)"
                    statement = nil
                    if sqlite3_prepare_v2(self.database, query, -1, &statement, nil) == SQLITE_OK {
                        sqlite3_bind_int(statement, 1, Int32(ID))
                        sqlite3_bind_text(statement, 2, (artistTitle as NSString).UTF8String, -1, nil)
                        sqlite3_bind_int(statement, 3, Int32(iTunesUniqueID))
                        sqlite3_bind_int(statement, 4, 0)
                        sqlite3_bind_int(statement, 5, timeStamp)
                        if sqlite3_step(statement) == SQLITE_DONE {
                            newItemID = Int(sqlite3_last_insert_rowid(self.database))
                        }
                        sqlite3_finalize(statement)
                    }
                }
            }
            disconnect()
        }
        return newItemID
    }
    
    func addContributingArtist (albumID: Int, artistID: Int) {
        if connected() {
            let timeStamp = Int32(NSDate().timeIntervalSince1970)
            var statement: COpaquePointer = nil
            var query = "SELECT COUNT(artist_id) FROM album_artists WHERE album_id = ? AND artist_id = ?"
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(albumID))
                sqlite3_bind_int(statement, 2, Int32(artistID))
                var numRows: Int32 = 0
                if sqlite3_step(statement) == SQLITE_ROW {
                    numRows = sqlite3_column_int(statement, 0)
                }
                sqlite3_finalize(statement)
                if numRows == 0 {
                    query = "INSERT INTO album_artists (album_id, artist_id, created) VALUES (?, ?, ?)"
                    if sqlite3_prepare_v2(self.database, query, -1, &statement, nil) == SQLITE_OK {
                        sqlite3_bind_int(statement, 1, Int32(albumID))
                        sqlite3_bind_int(statement, 2, Int32(artistID))
                        sqlite3_bind_int(statement, 3, timeStamp)
                        if sqlite3_step(statement) == SQLITE_DONE {
                            println("Successfully added a contributing artist.")
                        }
                        sqlite3_finalize(statement)
                    }
                }
            }
            disconnect()
        }
    }
    
    func addPendingArtist (ID: Int) {
        if connected() {
            let timestamp = Int32(NSDate().timeIntervalSince1970)
            let artistExistsQuery = "SELECT COUNT(id) FROM pending_artists WHERE id = ?"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, artistExistsQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(ID))
                var numRows: Int32 = 0
                if sqlite3_step(statement) == SQLITE_ROW {
                    numRows = sqlite3_column_int(statement, 0)
                }
                sqlite3_finalize(statement)
                if numRows == 0 {
                    let query = "INSERT INTO pending_artists (id, created) VALUES (?, ?)"
                    statement = nil
                    if sqlite3_prepare_v2(self.database, query, -1, &statement, nil) == SQLITE_OK {
                        sqlite3_bind_int(statement, 1, Int32(ID))
                        sqlite3_bind_int(statement, 2, timestamp)
                        if sqlite3_step(statement) != SQLITE_DONE {
                            println("Failed to insert pending artist.")
                        }
                        sqlite3_finalize(statement)
                    }
                }
            }
            disconnect()
        }
        println("Successfully added a pending artist.")
    }
    
    func deleteArtist (ID: Int) {
        if connected() {
            var query = "DELETE FROM artists WHERE id = ?"
            var statement: COpaquePointer = nil
			
			if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(ID))
            }
			
			if sqlite3_step(statement) != SQLITE_DONE {
                println("Failed to delete from db.")
            }
            sqlite3_finalize(statement)
            
            query = "DELETE FROM albums WHERE id IN (SELECT album_id FROM album_artists WHERE artist_id = ?)"
            statement = nil
			
			if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(ID))
            }
			
			if sqlite3_step(statement) != SQLITE_DONE {
                println("Failed to delete from db.")
            }
			
			sqlite3_finalize(statement)
            disconnect()
        }
    }
    
    func getAlbumArtist (albumID: Int) -> String {
        var artistTitle = String()
        if connected() {
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
        }
        return artistTitle
    }
    
    func getAlbumArtistId (albumID: Int) -> Int {
        var artistID = 0
        if connected() {
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
        }
        return artistID
    }
    
    func getArtistByUniqueID (uniqueID: Int) -> Int {
        var artistID = 0
        if connected() {
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
        }
        return artistID
    }
    
    func getArtists () {
        if connected() {
            self.artists = [Artist]()
            let query = "SELECT id,title,iTunes_unique_id,last_updated FROM artists ORDER BY title COLLATE NOCASE"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let IDRow = Int(sqlite3_column_int(statement, 0))
                    let artistRow = sqlite3_column_text(statement, 1)
                    let artistTitle = String.fromCString(UnsafePointer<CChar>(artistRow))
                    let uniqueID = Int(sqlite3_column_int(statement, 2))
                    artists.append(Artist(ID: IDRow, title: artistTitle!, iTunesUniqueID: uniqueID))
                }
                sqlite3_finalize(statement)
            }
            println("Artists in db: \(artists.count)")
            disconnect()
        }
    }
    
    func getPendingArtists () -> [Int] {
        var pendingArtists = [Int]()
        if connected() {
            let query = "SELECT id FROM pending_artists"
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let IDRow = sqlite3_column_int(statement, 0)
                    pendingArtists.append(Int(IDRow))
                }
                sqlite3_finalize(statement)
            }
            println("Pending artists in db: \(pendingArtists.count)")
            disconnect()
        }
        return pendingArtists
    }
    
    // -- Artwork -- //
    
    func addArtwork (hash: String, artwork: UIImage) {
        let artworkPath = artworkDirectoryPath.stringByAppendingPathComponent("/\(hash).jpg")
        if !NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
            UIImageJPEGRepresentation(artwork, 1.0).writeToFile(artworkPath, atomically: true)
        }
    }
    
    func checkArtwork (hash: String) -> Bool {
        let artworkPath = artworkDirectoryPath.stringByAppendingPathComponent("/\(hash).jpg")
        return NSFileManager.defaultManager().fileExistsAtPath(artworkPath)
    }
    
    func deleteArtwork (hash: String) {
        let artworkPath = artworkDirectoryPath.stringByAppendingPathComponent("/\(hash).jpg")
		let artworkPathHD = artworkDirectoryPath.stringByAppendingPathComponent("/\(hash)_large.jpg")
        if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
            NSFileManager.defaultManager().removeItemAtPath(artworkPath, error: nil)
            println("Successfully removed artwork: \(hash).")
        }
		if NSFileManager.defaultManager().fileExistsAtPath(artworkPathHD) {
			NSFileManager.defaultManager().removeItemAtPath(artworkPathHD, error: nil)
			println("Successfully removed HD artwork: \(hash).")
		}
    }
	
    func getArtwork (hash: String) -> UIImage? {
        let artworkPath = artworkDirectoryPath.stringByAppendingPathComponent("/\(hash).jpg")
        if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
            return UIImage(contentsOfFile: artworkPath)!
        }
        return nil
    }
    
    // -- Table Operations -- //
    
    func truncate (table: String) {
        if connected() {
            let query = "DELETE FROM \(table)"
            var errMsg: UnsafeMutablePointer<Int8> = nil
            if sqlite3_exec(database, query, nil, nil, &errMsg) != SQLITE_OK {
                println(String.fromCString(UnsafePointer<Int8>(errMsg)))
            }
            disconnect()
        }
    }
}
