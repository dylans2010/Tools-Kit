import Foundation

/// High-fidelity, JSON-based persistence engine for Workspace modules.
/// Manages storage in the application's document directory.
final class WorkspacePersistence {
    static let shared = WorkspacePersistence()

    private let fileManager = FileManager.default

    private init() {}

    /// Returns the URL for the documents directory.
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Saves an encodable object to a specific file path.
    func save<T: Encodable>(_ object: T, to filename: String) throws {
        let url = documentsDirectory.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    /// Loads a decodable object from a specific file path.
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let url = documentsDirectory.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Deletes a file from the documents directory.
    func delete(filename: String) throws {
        let url = documentsDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    /// Checks if a file exists.
    func exists(filename: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }
}
