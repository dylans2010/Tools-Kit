import Foundation
import Observation
import Combine

@MainActor
@Observable
public final class SDKDependencyIntelligenceHub {
    public static let shared = SDKDependencyIntelligenceHub()

    private let frameworkRegistry = FrameworkRegistry.shared
    private let libraryRegistry = LibraryRegistry.shared
    private let packageRegistry = PackageRegistry.shared
    private let scanner = SDKSourceScanner.shared

    public var detectedImports: Set<String> = []
    public var isScanning = false

    private init() {
        // Initial scan
        Task {
            await refreshUsageAnalytics()
        }
    }

    public func refreshUsageAnalytics() async {
        isScanning = true
        detectedImports = await scanner.scanForImports()
        isScanning = false
    }

    /// Returns a unified dependency graph nodes
    public func getUnifiedNodes() -> [SDKDependencyNode] {
        var nodes: [SDKDependencyNode] = []

        // Convert Frameworks to nodes
        for fw in frameworkRegistry.frameworks {
            nodes.append(SDKDependencyNode(
                id: fw.id,
                name: fw.name,
                kind: .library, // Mapping to available kinds
                version: fw.version,
                linkedTo: fw.packageDependencies,
                requiredScopes: fw.requiredScopes.map(\.rawValue)
            ))
        }

        // Convert Libraries to nodes
        for lib in libraryRegistry.libraries {
            nodes.append(SDKDependencyNode(
                id: lib.id,
                name: lib.name,
                kind: .library,
                version: lib.version,
                linkedTo: [], // LibraryDescriptor doesn't track dependencies explicitly in its struct yet
                requiredScopes: lib.requiredScopes.map(\.rawValue)
            ))
        }

        // Convert Packages to nodes
        for pkg in packageRegistry.packages {
            nodes.append(SDKDependencyNode(
                id: pkg.id,
                name: pkg.name,
                kind: .library,
                version: pkg.version,
                linkedTo: pkg.dependencyIds,
                requiredScopes: []
            ))
        }

        return nodes
    }

    public func checkIsUnused(name: String) -> Bool {
        return !detectedImports.contains(name)
    }

    public struct SearchResult: Identifiable {
        public let id = UUID()
        public let name: String
        public let type: String
        public let version: String
    }

    public func searchAll(query: String) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        var results: [SearchResult] = []

        let fwMatches = frameworkRegistry.frameworks.filter { $0.name.localizedCaseInsensitiveContains(query) }
        results.append(contentsOf: fwMatches.map { SearchResult(name: $0.name, type: "Framework", version: $0.version) })

        let libMatches = libraryRegistry.libraries.filter { $0.name.localizedCaseInsensitiveContains(query) }
        results.append(contentsOf: libMatches.map { SearchResult(name: $0.name, type: "Library", version: $0.version) })

        let pkgMatches = packageRegistry.packages.filter { $0.name.localizedCaseInsensitiveContains(query) }
        results.append(contentsOf: pkgMatches.map { SearchResult(name: $0.name, type: "Package", version: $0.version) })

        return results
    }

    public func calculateRiskScore(pkg: PackageDescriptor) -> Int {
        var score = 100

        // Deep dependency chain
        let graph = packageRegistry.buildDependencyGraph()
        let depth = calculateDepth(id: pkg.id, graph: graph)
        if depth > 3 { score -= 10 }
        if depth > 5 { score -= 20 }

        // Unstable version
        if pkg.version.hasPrefix("0.") { score -= 15 }

        // Circular dependency involvement
        if let cycle = graph.detectCycle(), cycle.contains(pkg.name) {
            score -= 40
        }

        return max(0, score)
    }

    private func calculateDepth(id: UUID, graph: DependencyGraph) -> Int {
        var maxDepth = 0
        for depId in graph.adjacency[id] ?? [] {
            maxDepth = max(maxDepth, 1 + calculateDepth(id: depId, graph: graph))
        }
        return maxDepth
    }
}
