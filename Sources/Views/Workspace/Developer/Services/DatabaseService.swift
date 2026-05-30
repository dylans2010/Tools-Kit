import Foundation

public class DatabaseService: ObservableObject {
    public static let shared = DatabaseService()
    private let store = DeveloperPersistentStore.shared

    @Published public var schemas: [DatabaseSchema] = []

    private init() { loadSchemas() }

    public func loadSchemas() { self.schemas = store.databaseSchemas }

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
}
