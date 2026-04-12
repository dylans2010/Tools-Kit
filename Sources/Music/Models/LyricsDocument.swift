import Foundation

enum LyricsSourceType: String, Codable, CaseIterable {
    case manual
    case imported
    case synced
    case lrclib = "LRCLIB"
}

struct LyricsDocument: Identifiable, Codable {
    var id: UUID = UUID()
    var songID: String
    var lines: [LyricLine]
    var sourceType: LyricsSourceType
    var offset: Double

    init(songID: String,
         lines: [LyricLine] = [],
         sourceType: LyricsSourceType = .manual,
         offset: Double = 0) {
        self.id = UUID()
        self.songID = songID
        self.lines = lines
        self.sourceType = sourceType
        self.offset = offset
    }
}
