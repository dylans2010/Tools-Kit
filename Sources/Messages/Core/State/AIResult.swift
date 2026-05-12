import Foundation

struct AIResult: Codable, Sendable {
    let id: UUID
    let input: String
    let output: String
    let subtype: PayloadSubtype
    let timestamp: Date

    init(input: String, output: String, subtype: PayloadSubtype) {
        self.id = UUID()
        self.input = input
        self.output = output
        self.subtype = subtype
        self.timestamp = Date()
    }
}
