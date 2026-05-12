import Foundation

struct LyricLine: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var timestamp: TimeInterval
    var text: String

    init(timestamp: TimeInterval, text: String) {
        self.id = UUID()
        self.timestamp = timestamp
        self.text = text
    }
}
