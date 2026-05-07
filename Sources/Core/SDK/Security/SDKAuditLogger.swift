import Foundation

@MainActor
public final class SDKAuditLogger: ObservableObject {
    public static let shared = SDKAuditLogger()

    public struct Event: Identifiable, Codable {
        public enum EventType: String, Codable, CaseIterable {
            case dataAccess
            case scopeUsage
            case externalAPICall
            case execution
            case privacy
            case security
        }

        public let id: UUID
        public let timestamp: Date
        public let projectID: UUID?
        public let eventType: EventType
        public let scope: String
        public let message: String
        public let metadata: [String: String]
    }

    @Published public private(set) var events: [Event] = []

    private let fileName = "sdk_audit_events_v1.json"

    private init() {
        load()
    }

    public func log(eventType: Event.EventType, projectID: UUID?, scope: String, message: String, metadata: [String: String] = [:]) {
        let event = Event(
            id: UUID(),
            timestamp: Date(),
            projectID: projectID,
            eventType: eventType,
            scope: scope,
            message: message,
            metadata: metadata
        )
        events.insert(event, at: 0)
        if events.count > 5000 {
            events = Array(events.prefix(5000))
        }
        persist()
    }

    public func query(projectID: UUID? = nil, eventType: Event.EventType? = nil, from: Date? = nil, to: Date? = nil) -> [Event] {
        events.filter { event in
            if let projectID, event.projectID != projectID { return false }
            if let eventType, event.eventType != eventType { return false }
            if let from, event.timestamp < from { return false }
            if let to, event.timestamp > to { return false }
            return true
        }
    }

    private func persist() {
        try? WorkspacePersistence.shared.save(events, to: fileName)
    }

    private func load() {
        if let loaded = try? WorkspacePersistence.shared.load([Event].self, from: fileName) {
            events = loaded
        }
    }
}
