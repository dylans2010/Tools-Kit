import Foundation

public final class SDKLibraryDependencyBridge {
    public init() {}

    public func projectNodes(from libraries: [SDKLibraryDefinition]) -> [SDKDependencyNode] {
        var nodes: [SDKDependencyNode] = []
        var idByName: [String: UUID] = [:]

        for library in libraries {
            idByName[library.name] = library.id
        }

        for library in libraries {
            let linked = library.dependencies.compactMap { idByName[$0] }
            nodes.append(
                SDKDependencyNode(
                    id: library.id,
                    name: library.name,
                    kind: .library,
                    version: library.version,
                    linkedTo: linked,
                    requiredScopes: library.linkedScopes,
                    preRunHook: "\(library.name).prepare",
                    postRunHook: "\(library.name).teardown",
                    lazyLoaded: false,
                    conditionalExpression: ""
                )
            )
        }

        return nodes
    }
}
