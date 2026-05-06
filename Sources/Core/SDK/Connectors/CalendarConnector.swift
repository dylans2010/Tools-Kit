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
        log("Requesting calendar access...", level: .info)

        let granted = try await eventStore.requestFullAccessToEvents()
        if granted {
            status = .connected
            log("Calendar access granted", level: .info)
        } else {
            status = .error
            log("Calendar access denied by user", level: .error)
            throw SDKError.permissionDenied(scope: "calendar.fullAccess")
        }
    }

    public func sync() async throws {
        guard status == .connected else {
            throw SDKError.executionFailed(reason: "Calendar not connected")
        }

        log("Syncing calendar events from EventKit...", level: .info)

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        log("Synced \(events.count) calendar events from EventKit", level: .info)
    }

    public func testConnection() async throws -> Bool {
        return EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    public func disconnect() {
        status = .disconnected
        log("Calendar disconnected", level: .info)
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "CalendarConnector", level: level)
        }
    }
}
