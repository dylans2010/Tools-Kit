import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var songIDs: [UUID]
    var dateCreated: Date
    var artworkSongID: UUID?

    init(id: UUID = UUID(), name: String, songIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.songIDs = songIDs
        self.dateCreated = Date()
        self.artworkSongID = songIDs.first
    }
}
