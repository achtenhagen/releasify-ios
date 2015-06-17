
import UIKit

let documents = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! NSString
let databasePath = documents.stringByAppendingPathComponent("db.sqlite")
let artworkDirectoryPath = documents.stringByAppendingPathComponent("artwork")

final class AppDB {
    
    class var sharedInstance : AppDB {
        struct Static {
            static let instance = AppDB()
        }
        return Static.instance
    }
    
    struct Artist {
        var ID: Int32
        var title: NSString
        var iTunesUniqueID: Int32
    }
    
    var database:COpaquePointer = nil
    var result  = Int32()
    var artists = [Artist]()
    var albums  = [Album]()

    func connect () -> Bool {
        return sqlite3_open(databasePath, &self.database) == SQLITE_OK
    }
    
    func disconnect () {
        sqlite3_close(self.database)
        self.database = nil
    }
    
    func create () {
        connect()
        let artistTableQuery = "CREATE TABLE IF NOT EXISTS artists (id INTEGER PRIMARY KEY, title VARCHAR(100) NOT NULL, iTunes_unique_id INTEGER, last_updated INTEGER, created INTEGER)"
        var errMsg:UnsafeMutablePointer<Int8> = nil
        sqlite3_exec(database, artistTableQuery, nil, nil, &errMsg)
        
        let albumTableQuery = "CREATE TABLE IF NOT EXISTS albums (id INTEGER PRIMARY KEY, title varchar(100) NOT NULL, release_date int(11) DEFAULT NULL, artwork varchar(250) DEFAULT NULL, explicit tinyint(1) NOT NULL DEFAULT '0', copyright varchar(250) DEFAULT NULL, iTunes_unique_id int(11) DEFAULT NULL, iTunes_url varchar(250) DEFAULT NULL, created int(11) NOT NULL)"
        sqlite3_exec(database, albumTableQuery, nil, nil, &errMsg)
        
        let albumArtistTableQuery = "CREATE TABLE IF NOT EXISTS album_artists (id INTEGER PRIMARY KEY AUTOINCREMENT, album_id int(11) NOT NULL, artist_id int(11) NOT NULL, created int(11) NOT NULL)"
        sqlite3_exec(database, albumArtistTableQuery, nil, nil, &errMsg)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(artworkDirectoryPath) {
            NSFileManager.defaultManager().createDirectoryAtPath(artworkDirectoryPath, withIntermediateDirectories: false, attributes: nil, error: nil)
        }
        disconnect()
    }
    
    // -- Albums -- //
    
    func addAlbum (albumItem: Album) -> Int {
        connect()
        var newAlbumID = 0
        let albumExistsQuery = "SELECT COUNT(id) FROM albums WHERE id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, albumExistsQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(albumItem.ID))
            var numRows:Int32 = 0
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
                        addContributingArtist(Int32(albumItem.ID), artistID: Int32(albumItem.artistID))
                    }
                }
            }
        }
        disconnect()
        return newAlbumID
    }
    
    func deleteAlbum (id: Int32) {
        connect()
        let delete = "DELETE FROM albums WHERE id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, delete, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
        }
        if sqlite3_step(statement) != SQLITE_DONE {
            println("Failed to delete from db.")
        }
        sqlite3_finalize(statement)
        disconnect()
    }
    
    func getAlbums () {
        albums = [Album]()
        var timestamp: String = String(stringInterpolationSegment: Int(NSDate().timeIntervalSince1970))
        var query = "SELECT * FROM albums WHERE release_date - \(timestamp) > 0 ORDER BY release_date ASC"
        getAlbumsComponent(query)
        query = "SELECT * FROM albums WHERE release_date - \(timestamp) < 0 AND release_date - \(timestamp) > -2592000 ORDER BY release_date DESC"
        getAlbumsComponent(query)
        println("Albums in db: \(albums.count)")
    }
    
    func getAlbumsComponent(query: String) {
        connect()
        var count = 0
        var statement:COpaquePointer = nil
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
                albums.append(Album(
                    ID: ID,
                    title: albumTitle!,
                    artistID: getAlbumArtistId(Int32(ID)),
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
    
    func getAlbumDateAdded (albumID: Int32) -> Double {
        connect()
        var created:Int32 = 0
        let query = "SELECT created FROM albums WHERE id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, albumID)
            if sqlite3_step(statement) == SQLITE_ROW {
                created = sqlite3_column_int(statement, 0)
            }
            sqlite3_finalize(statement)
        }
        disconnect()
        return Double(created)
    }
    
    // -- Artists -- //
    
    func addArtist (ID: Int32, artistTitle: NSString, iTunesUniqueID: Int32) -> Int {
        connect()
        var newItemID = 0
        let timeStamp = Int32(NSDate().timeIntervalSince1970)
        let artistExistsQuery = "SELECT COUNT(id) FROM artists WHERE iTunes_unique_id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, artistExistsQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, iTunesUniqueID)
            var numRows:Int32 = 0
            if sqlite3_step(statement) == SQLITE_ROW {
                numRows = sqlite3_column_int(statement, 0)
            }
            sqlite3_finalize(statement)
            if numRows == 0 {
                let query = "INSERT INTO artists (id, title, iTunes_unique_id, last_updated, created) VALUES (?, ?, ?, ?, ?)"
                statement = nil
                if sqlite3_prepare_v2(self.database, query, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_int(statement, 1, ID)
                    sqlite3_bind_text(statement, 2, artistTitle.UTF8String, -1, nil)
                    sqlite3_bind_int(statement, 3, iTunesUniqueID)
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
        return newItemID
    }
    
    // Adds a contributing artist to the database.
    func addContributingArtist (albumID: Int32, artistID: Int32) {
        connect()
        let timeStamp = Int32(NSDate().timeIntervalSince1970)
        var statement:COpaquePointer = nil
        var query = "SELECT COUNT(artist_id) FROM album_artists WHERE album_id = ? AND artist_id = ?"
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, albumID)
            sqlite3_bind_int(statement, 2, artistID)
            var numRows:Int32 = 0
            if sqlite3_step(statement) == SQLITE_ROW {
                numRows = sqlite3_column_int(statement, 0)
            }
            sqlite3_finalize(statement)
            if numRows == 0 {
                query = "INSERT INTO album_artists (album_id, artist_id, created) VALUES (?, ?, ?)"
                if sqlite3_prepare_v2(self.database, query, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_int(statement, 1, albumID)
                    sqlite3_bind_int(statement, 2, artistID)
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
    
    func deleteArtist (id: Int32) {
        connect()
        let delete = "DELETE FROM artists WHERE id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, delete, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
        }
        if sqlite3_step(statement) != SQLITE_DONE {
            println("Failed to delete from db.")
        }
        sqlite3_finalize(statement)
        disconnect()
    }
    
    func getAlbumArtist (albumID: Int32) -> String {
        connect()
        var artistTitle = String()
        let query = "SELECT title FROM artists WHERE id IN (SELECT artist_id FROM album_artists WHERE album_id = ?)"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, albumID)
            if sqlite3_step(statement) == SQLITE_ROW {
                artistTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 0)))!
            }
            sqlite3_finalize(statement)
        }
        disconnect()
        return artistTitle
    }
    
    func getAlbumArtistId (albumID: Int32) -> Int {
        connect()
        var artistID = 0
        let query = "SELECT artist_id FROM album_artists WHERE album_id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, albumID)
            if sqlite3_step(statement) == SQLITE_ROW {
                artistID = Int(sqlite3_column_int(statement, 0))
            }
            sqlite3_finalize(statement)
        }
        disconnect()
        return artistID
    }
    
    func getArtistByUniqueID (uniqueID: Int32) -> Int {
        connect()
        var artistID:Int32 = 0
        let query = "SELECT id FROM artists WHERE iTunes_unique_id = ?"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, uniqueID)
            if sqlite3_step(statement) == SQLITE_ROW {
                artistID = sqlite3_column_int(statement, 0)
            }
            sqlite3_finalize(statement)
        }
        disconnect()
        return Int(artistID)
    }
    
    func getArtists () {
        connect()
        self.artists = [Artist]()
        var count = 0
        let query = "SELECT id,title,iTunes_unique_id,last_updated FROM artists ORDER BY title COLLATE NOCASE"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let IDRow = sqlite3_column_int(statement, 0)
                let artistRow = sqlite3_column_text(statement, 1)
                let artistTitle = String.fromCString(UnsafePointer<CChar>(artistRow))
                let uniqueID = sqlite3_column_int(statement, 2)
                artists.append(Artist(ID: IDRow, title: artistTitle!, iTunesUniqueID: uniqueID))
                count++
            }
            sqlite3_finalize(statement)
        }
        println("Artists in db: \(count)")
        disconnect()
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
        if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
            return true
        }
        return false
    }
    
    func deleteArtwork (hash: String) {
        let artworkPath = artworkDirectoryPath.stringByAppendingPathComponent("/\(hash).jpg")
        if NSFileManager.defaultManager().fileExistsAtPath(artworkPath) {
            NSFileManager.defaultManager().removeItemAtPath(artworkPath, error: nil)
            println("Successfully removed artwork.")
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
        connect()
        let truncateTablequery = "DELETE FROM \(table);"
        var statement:COpaquePointer = nil
        var errMsg:UnsafeMutablePointer<Int8> = nil
        if sqlite3_exec(database, truncateTablequery, nil, nil, &errMsg) != SQLITE_OK {
            println(String.fromCString(UnsafePointer<Int8>(errMsg)))
        }
        disconnect()
    }
}