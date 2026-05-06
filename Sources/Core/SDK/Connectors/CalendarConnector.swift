import Foundation
import EventKit

public class CalendarConnector: BaseConnector, ObservableObject {
    public let id = UUID()
    public let name = "Calendar"
    public let type: ConnectorType = .calendar
    @Published public var status: ConnectorStatus = .disconnected
    public var authFields: [AuthField] = []
    @Published public var activityLog: [ConnectorEvent] = []

    private let eventStore = EKEventStore()

    public init() {}

    public func authenticate(credentials: [String : String]) async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        status = granted ? .connected : .error
    }

    public func sync() async throws {
        _ = try await fetchEvents(from: Date(), to: Date().addingTimeInterval(86400))
    }

    public func testConnection() async throws -> Bool {
        return status == .connected
    }

    public func disconnect() {
        status = .disconnected
    }

    public func fetchEvents(from: Date, to: Date) async throws -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}
