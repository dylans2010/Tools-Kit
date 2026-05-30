import Foundation

public struct CrashLog: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var version: String
    public var buildNumber: String
    public var stackTrace: String
    public var deviceModel: String
    public var osVersion: String
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID, version: String, buildNumber: String, stackTrace: String, deviceModel: String, osVersion: String, timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.version = version
        self.buildNumber = buildNumber
        self.stackTrace = stackTrace
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.timestamp = timestamp
    }
}
