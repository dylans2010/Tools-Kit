import Foundation

public final class SDKLibraryExecutionEngine {
    private let scopeBinder = SDKLibraryScopeBinder()

    public init() {}

    @discardableResult
    public func executeLibrary(
        _ library: SDKLibraryDefinition,
        function: String?,
        projectScopes: Set<String>,
        pluginScopes: Set<String> = []
    ) async throws -> [String: String] {
        let effectiveScopes = scopeBinder.effectiveScopes(
            projectScopes: projectScopes,
            pluginScopes: pluginScopes,
            libraryScopes: Set(library.linkedScopes)
        )

        try scopeBinder.enforce(library: library, effectiveScopes: effectiveScopes)

        let selectedFunction = function ?? library.exportedFunctions.first?.name ?? "pipeline"
        return [
            "library": library.name,
            "version": library.version,
            "function": selectedFunction,
            "scopes": effectiveScopes.sorted().joined(separator: ",")
        ]
    }
}
