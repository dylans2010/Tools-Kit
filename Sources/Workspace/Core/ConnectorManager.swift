import Foundation
import Combine

final class ConnectorManager: ObservableObject {
    static let shared = ConnectorManager()

    @Published private(set) var connectors: [ConnectorDefinition] = []
    private let storageKey = "connectors_v1"

    private init() {
        loadConnectors()
    }

    func saveConnector(_ connector: ConnectorDefinition) {
        if let index = connectors.firstIndex(where: { $0.id == connector.id }) {
            connectors[index] = connector
        } else {
            connectors.append(connector)
        }
        saveToDisk()
    }

    func deleteConnector(id: UUID) {
        connectors.removeAll { $0.id == id }
        saveToDisk()
    }

    func toggleConnector(id: UUID) {
        guard let index = connectors.firstIndex(where: { $0.id == id }) else { return }
        connectors[index].isEnabled.toggle()
        saveToDisk()
    }

    private func saveToDisk() {
        try? UnifiedDataStore.shared.save(connectors, key: storageKey)
    }

    private func loadConnectors() {
        connectors = (try? UnifiedDataStore.shared.load([ConnectorDefinition].self, key: storageKey)) ?? []
    }
}
