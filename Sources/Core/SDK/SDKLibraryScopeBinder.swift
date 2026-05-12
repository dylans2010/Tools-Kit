import Foundation

public struct SDKLibraryScopeBinder: Sendable {
    public init() {}

    public func effectiveScopes(projectScopes: Set<String>, pluginScopes: Set<String>, libraryScopes: Set<String>) -> Set<String> {
        return projectScopes.union(pluginScopes).union(libraryScopes)
    }

    public func enforce(library: SDKLibraryDefinition, effectiveScopes: Set<String>) throws {
        let required = Set(library.linkedScopes)
        let missing = required.subtracting(effectiveScopes)
        guard missing.isEmpty else {
            throw SDKError.permissionDenied(scope: missing.sorted().joined(separator: ","))
        }
    }
}
