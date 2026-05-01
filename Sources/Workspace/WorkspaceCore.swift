import Foundation
final class WorkspacePersistence {
    static let shared = WorkspacePersistence()
    private var docDir: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    func save<T: Encodable>(_ obj: T, filename: String) throws {
        let data = try JSONEncoder().encode(obj)
        try data.write(to: docDir.appendingPathComponent(filename), options: .atomic)
    }
}