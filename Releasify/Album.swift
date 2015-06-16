
import UIKit

struct Album {
    var ID: Int
    var title: String
    var artistID: Int
    var releaseDate: Double
    var artwork: String
    var explicit: Int
    var copyright: String
    var iTunesUniqueID: Int
    var iTunesURL: String
    var created: Int
    
    func getProgress (dateAdded: Double) -> Float {
        return Float((Double(NSDate().timeIntervalSince1970) - Double(dateAdded)) / (Double(releaseDate) - Double(dateAdded)))
    }
}