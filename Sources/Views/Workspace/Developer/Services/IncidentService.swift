import Foundation

public class IncidentService: ObservableObject {
    public static let shared = IncidentService()
    private let store = DeveloperPersistentStore.shared

    @Published public var incidents: [Incident] = []

    private init() { loadIncidents() }

    public func loadIncidents() { self.incidents = store.incidents }

    public func reportIncident(_ incident: Incident) async throws {
        var current = store.incidents
        current.insert(incident, at: 0)
        store.saveIncidents(current)
        await MainActor.run { self.incidents = current }
    }

    public func updateIncident(_ incident: Incident) async throws {
        var current = store.incidents
        if let index = current.firstIndex(where: { $0.id == incident.id }) {
            current[index] = incident
            current[index].updatedAt = Date()
            store.saveIncidents(current)
            await MainActor.run { self.incidents = current }
        }
    }
}
