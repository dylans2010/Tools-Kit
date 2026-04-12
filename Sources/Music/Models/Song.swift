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

    private enum CodingKeys: String, CodingKey {
        case id, title, artist, duration, fileURL, artworkData, dateAdded, playCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        fileURL = try container.decode(URL.self, forKey: .fileURL)
        artworkData = try container.decodeIfPresent(Data.self, forKey: .artworkData)
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        playCount = try container.decodeIfPresent(Int.self, forKey: .playCount) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(duration, forKey: .duration)
        try container.encode(fileURL, forKey: .fileURL)
        try container.encodeIfPresent(artworkData, forKey: .artworkData)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(playCount, forKey: .playCount)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
