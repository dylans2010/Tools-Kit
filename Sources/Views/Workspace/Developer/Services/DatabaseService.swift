import Foundation

public class DatabaseService: ObservableObject {
    public static let shared = DatabaseService()
    private let store = DeveloperPersistentStore.shared

    @Published public var schemas: [DatabaseSchema] = []

    private init() { loadSchemas() }

    public func loadSchemas() { self.schemas = store.databaseSchemas }

    public func fetchSchemas(appID: UUID) async throws -> [DatabaseSchema] {
        store.databaseSchemas.filter { $0.appID == appID }
    }

    public func saveSchema(_ schema: DatabaseSchema) async throws {
        var current = store.databaseSchemas
        if let index = current.firstIndex(where: { $0.id == schema.id }) {
            current[index] = schema
        } else {
            current.append(schema)
        }
        store.saveDatabaseSchemas(current)
        await MainActor.run { self.schemas = current }
    }

    public func vacuum(appID: UUID) async throws {
        let current = store.databaseSchemas.filter { $0.appID == appID }
        await MainActor.run { self.schemas = store.databaseSchemas }
        _ = current
    }

    public func createBackup(appID: UUID) async throws {
        let current = store.databaseSchemas.filter { $0.appID == appID }
        await MainActor.run { self.schemas = store.databaseSchemas }
        _ = current
    }
}
