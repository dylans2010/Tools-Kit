import Foundation

public struct BridgeDevice: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var platform: BridgePlatform
    public var hostURL: URL
    public var port: Int
    public var lastConnected: Date?
    public var isTrusted: Bool

    public init(id: UUID = UUID(), name: String, platform: BridgePlatform, hostURL: URL, port: Int, lastConnected: Date? = nil, isTrusted: Bool = false) {
        self.id = id
        self.name = name
        self.platform = platform
        self.hostURL = hostURL
        self.port = port
        self.lastConnected = lastConnected
        self.isTrusted = isTrusted
    }
}
