import Foundation

struct Song: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    var fileURL: URL
    var artworkData: Data?
    var dateAdded: Date
    var playCount: Int

    init(id: UUID = UUID(), title: String, artist: String, duration: TimeInterval,
         fileURL: URL, artworkData: Data? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.fileURL = fileURL
        self.artworkData = artworkData
        self.dateAdded = Date()
        self.playCount = 0
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
