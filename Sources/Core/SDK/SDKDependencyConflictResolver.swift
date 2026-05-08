import Foundation

public final class SDKDependencyConflictResolver {
    public init() {}

    public func conflicts(in nodes: [SDKDependencyNode]) -> [String] {
        let grouped = Dictionary(grouping: nodes, by: { $0.name.lowercased() })
        return grouped.compactMap { key, values in
            let versions = Set(values.map { $0.version })
            guard versions.count > 1 else { return nil }
            return "Version conflict for \(key): \(versions.sorted().joined(separator: ", "))"
        }
    }

    public func suggestion(for conflict: String) -> String {
        return "Normalize to one compatible version and update linked nodes."
    }
}
