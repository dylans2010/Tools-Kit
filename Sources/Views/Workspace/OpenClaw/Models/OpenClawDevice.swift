import Foundation

struct OpenClawDevice: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let host: String
    let port: Int
    var lastConnected: Date?
    var metadata: [String: String]
}
