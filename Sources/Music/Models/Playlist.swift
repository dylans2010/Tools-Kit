import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var songIDs: [UUID]
    var dateCreated: Date
    var artworkSongID: UUID?
    var customArtworkData: Data?
    /// URL of the backing folder inside Documents/Music/.
    /// Not persisted in Codable storage — reconstructed from disk on each launch.
    var folderURL: URL? = nil

    // Exclude folderURL from Codable serialisation.
    private enum CodingKeys: String, CodingKey {
        case id, name, songIDs, dateCreated, artworkSongID, customArtworkData
    }

    init(id: UUID = UUID(), name: String, songIDs: [UUID] = [], folderURL: URL? = nil) {
        self.id = id
        self.name = name
        self.songIDs = songIDs
        self.dateCreated = Date()
        self.artworkSongID = songIDs.first
        self.folderURL = folderURL
    }

    // Equatable ignores folderURL (value is derived from name+disk).
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.songIDs == rhs.songIDs &&
        lhs.dateCreated == rhs.dateCreated &&
        lhs.artworkSongID == rhs.artworkSongID &&
        lhs.customArtworkData == rhs.customArtworkData
    }
}
