import Foundation

/// Advanced query engine for SDK models.
/// Provides filtering, sorting, and pagination logic for data sets.
public final class SDKQueryEngine {

    public enum SortOrder {
        case ascending
        case descending
    }

    /// Filters a collection based on a predicate.
    public static func filter<T: SDKModel>(_ models: [T], predicate: (T) -> Bool) -> [T] {
        return models.filter(predicate)
    }

    /// Sorts a collection by a key path.
    public static func sort<T: SDKModel, V: Comparable>(_ models: [T], by keyPath: KeyPath<T, V>, order: SortOrder = .ascending) -> [T] {
        return models.sorted { a, b in
            let vA = a[keyPath: keyPath]
            let vB = b[keyPath: keyPath]
            return order == .ascending ? vA < vB : vA > vB
        }
    }

    /// Paginates a collection.
    public static func paginate<T>(_ items: [T], page: Int, pageSize: Int) -> [T] {
        let startIndex = max(0, page * pageSize)
        let endIndex = min(items.count, startIndex + pageSize)
        guard startIndex < items.count else { return [] }
        return Array(items[startIndex..<endIndex])
    }

    /// Complex search across multiple fields.
    public static func search<T: SDKModel>(_ models: [T], query: String, fields: [KeyPath<T, String>]) -> [T] {
        let loweredQuery = query.lowercased()
        if loweredQuery.isEmpty { return models }

        return models.filter { model in
            fields.contains { field in
                model[keyPath: field].lowercased().contains(loweredQuery)
            }
        }
    }
}
