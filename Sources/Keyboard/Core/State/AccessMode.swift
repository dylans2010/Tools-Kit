import Foundation

enum AccessLevel: String, Codable {
    case restricted
    case full
}

struct AccessConfiguration: Codable {
    let mode: AccessMode
    let level: AccessLevel
}
