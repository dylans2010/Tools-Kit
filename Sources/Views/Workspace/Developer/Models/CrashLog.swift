import Foundation

public struct CrashLog: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var version: String
    public var buildNumber: String
    public var exceptionType: String
    public var reason: String
    public var stackTrace: String
    public var deviceModel: String
    public var osVersion: String
    public var timestamp: Date
    public var isSymbolicated: Bool

    public init(id: UUID = UUID(), appID: UUID, version: String, buildNumber: String, exceptionType: String = "", reason: String = "", stackTrace: String, deviceModel: String, osVersion: String, timestamp: Date = Date(), isSymbolicated: Bool = false) {
        self.id = id
        self.appID = appID
        self.version = version
        self.buildNumber = buildNumber
        self.exceptionType = exceptionType
        self.reason = reason
        self.stackTrace = stackTrace
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.timestamp = timestamp
        self.isSymbolicated = isSymbolicated
    }
}
