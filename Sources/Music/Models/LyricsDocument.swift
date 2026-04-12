import Foundation

enum LyricsSourceType: String, Codable, CaseIterable {
    case manual
    case imported
    case synced
    case lrclib = "LRCLIB"

    var displayName: String {
        switch self {
        case .manual:   return "Manual"
        case .imported: return "Imported"
        case .synced:   return "Synced"
        case .lrclib:   return "LRCLIB"
        }
    }
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
        self.songID = songID
        self.lines = lines
        self.sourceType = sourceType
        self.offset = offset
    }
}
