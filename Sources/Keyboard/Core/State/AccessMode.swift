import Foundation

enum AccessLevel: String, Codable, Sendable {
    case restricted
    case full
}

struct AccessConfiguration: Codable, Sendable {
    let mode: AccessMode
    let level: AccessLevel
}
