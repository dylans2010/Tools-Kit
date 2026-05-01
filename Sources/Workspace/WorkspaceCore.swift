import Foundation

/// Robust persistence manager for complex models.
final class WorkspacePersistence {
    static let shared = WorkspacePersistence()

    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func save<T: Encodable>(_ object: T, filename: String) throws {
        let url = documentsDirectory.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(filename: String, as type: T.Type) throws -> T {
        let url = documentsDirectory.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}

/// Basic text diffing utility.
struct DiffEngine {
    enum DiffOp {
        case insert(String)
        case delete(String)
        case equal(String)
    }

    static func computeDiff(old: String, new: String) -> [DiffOp] {
        // Implementation of simple line-based diff
        let oldLines = old.components(separatedBy: .newlines)
        let newLines = new.components(separatedBy: .newlines)

        var ops: [DiffOp] = []
        // Simple mock for now, but better than nothing
        for line in oldLines {
            if newLines.contains(line) {
                ops.append(.equal(line))
            } else {
                ops.append(.delete(line))
            }
        }
        for line in newLines {
            if !oldLines.contains(line) {
                ops.append(.insert(line))
            }
        }
        return ops
    }
}
