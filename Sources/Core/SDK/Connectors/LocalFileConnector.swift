import Foundation
import Combine
import SwiftUI

public final class LocalFileConnector: BaseConnector {
    public let id = UUID()
    public let name = "Local Files"
    public let type: ConnectorType = .localFileSystem
    @Published public var status: ConnectorStatus = .connected

    public var authFields: [AuthField] { [] }

    @Published public var activityLog: [ConnectorEvent] = []

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        status = .connected
    }

    public func sync() async throws {
        log("Scanning workspace files...", level: .info)
        let files = WorkspaceAPI.shared.files.listFiles()
        log("Found \(files.count) files in workspace", level: .info)
    }

    public func testConnection() async throws -> Bool {
        return true
    }

    public func disconnect() {
        status = .disconnected
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "LocalFileConnector", level: level)
        }
    }
}
