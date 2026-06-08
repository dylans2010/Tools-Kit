import Foundation

public struct DiagnosticsData: Codable {
    public let deviceName: String
    public let osVersion: String
    public let appVersion: String
    public let buildNumber: String
    public let memoryUsage: String
    public let cpuUsage: String
    public let networkStatus: String
    public let logs: [String]
    public let timestamp: Date
}
