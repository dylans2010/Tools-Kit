import Foundation
import Combine

public protocol BaseConnector: AnyObject, ObservableObject, Identifiable {
    var id: UUID { get }
    var name: String { get }
    var type: ConnectorType { get }
    var status: ConnectorStatus { get set }
    var isConnected: Bool { get }
    var identifier: String { get }
    var requiredScopes: [String] { get }
    var authFields: [AuthField] { get }
    var activityLog: [ConnectorEvent] { get }

    func authenticate(credentials: [String: String]) async throws
    func sync() async throws
    func testConnection() async throws -> Bool
    func disconnect()
}

public extension BaseConnector {
    var requiredScopes: [String] { [] }
    var isConnected: Bool { status == .connected }
    var identifier: String { id.uuidString }
}

public enum ConnectorType: String, CaseIterable, Codable {
    case gmail, webhook, github, localFileSystem, calendar, rest, mqtt
}

public enum ConnectorStatus: String, Codable {
    case disconnected, connecting, connected, error
}

public struct AuthField: Codable, Hashable {
    public var label: String
    public var placeholder: String
    public var isSecure: Bool
    public var key: String
}

public struct ConnectorEvent: Identifiable, Codable {
    public var id: UUID
    public var timestamp: Date
    public var message: String
    public var level: LogLevel
}
