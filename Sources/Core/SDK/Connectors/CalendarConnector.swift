import Foundation
import Combine
import EventKit

public final class CalendarConnector: BaseConnector {
    public let id = UUID()
    public let name = "Calendar"
    public let type: ConnectorType = .calendar
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] { [] }

    @Published public var activityLog: [ConnectorEvent] = []
    private let eventStore = EKEventStore()

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        status = .connecting
        let granted = try await eventStore.requestFullAccessToEvents()
        status = granted ? .connected : .error
        log(granted ? "Calendar access granted" : "Calendar access denied", level: granted ? .info : .error)
    }

    public func sync() async throws {
        guard status == .connected else { return }
        log("Syncing calendar events...", level: .info)
        // Mock sync
        log("Calendar sync complete", level: .info)
    }

    public func testConnection() async throws -> Bool {
        return EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    public func disconnect() {
        status = .disconnected
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "CalendarConnector", level: level)
        }
    }
}
