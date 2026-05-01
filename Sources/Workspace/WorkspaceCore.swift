import Foundation

final class WorkspacePersistence {
    static let shared = WorkspacePersistence()
    private var docDir: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    func save<T: Encodable>(_ obj: T, filename: String) throws {
        let data = try JSONEncoder().encode(obj)
        try data.write(to: docDir.appendingPathComponent(filename), options: .atomic)
    }
    func load<T: Decodable>(filename: String, as type: T.Type) throws -> T {
        let data = try Data(contentsOf: docDir.appendingPathComponent(filename))
        return try JSONDecoder().decode(type, from: data)
    }
}

struct DiffEngine {
    enum DiffOp { case insert(String), delete(String), equal(String) }
    static func computeDiff(old: String, new: String) -> [DiffOp] {
        let oldL = old.components(separatedBy: .newlines); let newL = new.components(separatedBy: .newlines)
        return oldL.map { newL.contains($0) ? .equal($0) : .delete($0) } + newL.filter { !oldL.contains($0) }.map { .insert($0) }
    }
}