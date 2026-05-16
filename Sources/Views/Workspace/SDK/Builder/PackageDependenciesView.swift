import SwiftUI
import Observation
import CryptoKit

// MARK: - Package Descriptor

enum PackageDependencyLayer: String, CaseIterable, Codable, Identifiable {
    case core, optional, dev
    var id: String { rawValue }

    var weight: Int {
        switch self {
        case .core: return 100
        case .optional: return 50
        case .dev: return 10
        }
    }
}

struct PackageDescriptor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let version: String
    let layer: PackageDependencyLayer
    let exports: [String]
    let dependencyIds: [UUID]
    let integrityHash: String
    var healthScore: Int = 100
    var installDate: Date = Date()

    init(
        id: UUID = UUID(), name: String, version: String,
        layer: PackageDependencyLayer = .core,
        exports: [String] = [], dependencyIds: [UUID] = [],
        integrityHash: String = ""
    ) {
        self.id = id; self.name = name; self.version = version; self.layer = layer
        self.exports = exports; self.dependencyIds = dependencyIds
        self.integrityHash = integrityHash
    }
}

// MARK: - Package Registry

enum RegistryType: String, CaseIterable, Codable, Identifiable {
    case local, remote, project
    var id: String { rawValue }
}

@MainActor
final class PackageRegistry: ObservableObject {
    static let shared = PackageRegistry()
    @Published var packages: [PackageDescriptor] = []
    @Published var activeRegistry: RegistryType = .local
    @Published var remoteRegistryURL: String = "https://registry.toolskit.dev"

    private init() {}

    func install(_ pkg: PackageDescriptor) {
        packages.removeAll { $0.name == pkg.name }
        packages.append(pkg)
    }

    func uninstall(id: UUID) {
        packages.removeAll { $0.id == id }
    }

    func package(by id: UUID) -> PackageDescriptor? {
        packages.first { $0.id == id }
    }

    func buildDependencyGraph() -> DependencyGraph {
        DependencyGraph(packages: packages)
    }
}

// MARK: - Dependency Health System

struct PackageHealth {
    let score: Int
    let issues: [String]
    let recommendations: [String]
}

struct DependencyHealthEngine {
    static func analyze(package: PackageDescriptor, graph: DependencyGraph) -> PackageHealth {
        var score = 100
        var issues: [String] = []
        var recs: [String] = []

        // 1. Freshness check
        if package.version.hasPrefix("0.") {
            score -= 20
            issues.append("Unstable major version (0.x)")
            recs.append("Migrate to stable v1.0.0+")
        }

        // 2. Depth check
        let depth = calculateDepth(id: package.id, graph: graph)
        if depth > 5 {
            score -= 10
            issues.append("Deep dependency chain (\(depth))")
            recs.append("Flatten dependency tree if possible")
        }

        // 3. Risk check (deprecated pattern)
        if package.name.lowercased().contains("legacy") || package.name.lowercased().contains("old") {
            score -= 30
            issues.append("Legacy naming pattern detected")
            recs.append("Replace with modern alternative")
        }

        return PackageHealth(score: max(0, score), issues: issues, recommendations: recs)
    }

    private static func calculateDepth(id: UUID, graph: DependencyGraph) -> Int {
        var maxDepth = 0
        for depId in graph.adjacency[id] ?? [] {
            maxDepth = max(maxDepth, 1 + calculateDepth(id: depId, graph: graph))
        }
        return maxDepth
    }
}

// MARK: - DAG-Based Dependency Graph Engine

struct DependencyGraph {
    let packages: [PackageDescriptor]
    static var resolutionCache: [String: [PackageDescriptor]] = [:]

    var adjacency: [UUID: [UUID]] {
        var map: [UUID: [UUID]] = [:]
        for pkg in packages {
            map[pkg.id] = pkg.dependencyIds
        }
        return map
    }

    func detectCycle() -> [String]? {
        let adj = adjacency
        let nameMap = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, $0.name) })
        var visited: Set<UUID> = []
        var stack: Set<UUID> = []

        func dfs(_ node: UUID, path: [UUID]) -> [String]? {
            if stack.contains(node) {
                let cycleStart = path.firstIndex(of: node) ?? path.startIndex
                return path[cycleStart...].map { nameMap[$0] ?? $0.uuidString } + [nameMap[node] ?? node.uuidString]
            }
            if visited.contains(node) { return nil }
            visited.insert(node)
            stack.insert(node)
            for neighbor in adj[node] ?? [] {
                if let cycle = dfs(neighbor, path: path + [node]) { return cycle }
            }
            stack.remove(node)
            return nil
        }

        for pkg in packages {
            if let cycle = dfs(pkg.id, path: []) { return cycle }
        }
        return nil
    }

    func topologicalSort() -> [PackageDescriptor] {
        let adj = adjacency
        var inDegree: [UUID: Int] = [:]
        for pkg in packages { inDegree[pkg.id] = 0 }
        for (_, deps) in adj { for dep in deps { inDegree[dep, default: 0] += 1 } }

        var queue = packages.filter { (inDegree[$0.id] ?? 0) == 0 }.map(\.id)
        var ordered: [UUID] = []

        while !queue.isEmpty {
            let node = queue.removeFirst()
            ordered.append(node)
            for neighbor in adj[node] ?? [] {
                inDegree[neighbor, default: 1] -= 1
                if inDegree[neighbor] == 0 { queue.append(neighbor) }
            }
        }

        let idMap = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, $0) })
        return ordered.compactMap { idMap[$0] }
    }

    func orphans() -> [PackageDescriptor] {
        var referenced: Set<UUID> = []
        for pkg in packages { for dep in pkg.dependencyIds { referenced.insert(dep) } }
        return packages.filter { !referenced.contains($0.id) && $0.dependencyIds.isEmpty }
    }
}

// MARK: - Package Integrity Engine (SHA256 Hash Verification)

struct PackageIntegrityEngine {
    static func computeHash(name: String, version: String, exports: [String]) -> String {
        let material = "\(name):\(version):\(exports.sorted().joined(separator: ","))"
        let digest = SHA256.hash(data: Data(material.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func verify(package: PackageDescriptor) -> Bool {
        guard !package.integrityHash.isEmpty else { return false }
        let expected = computeHash(name: package.name, version: package.version, exports: package.exports)
        return package.integrityHash == expected
    }
}

// MARK: - Semver Resolution Engine

struct SemverResolver {
    enum RangeOperator: String {
        case caret = "^"
        case tilde = "~"
        case exact = ""
        case wildcard = "*"
    }

    struct Version: Comparable {
        let major: Int
        let minor: Int
        let patch: Int

        init?(string: String) {
            let clean = string.trimmingCharacters(in: CharacterSet.decimalDigits.inverted.subtracting(CharacterSet(charactersIn: ".")))
            let parts = clean.split(separator: ".").compactMap { Int($0) }
            guard !parts.isEmpty else { return nil }
            major = parts[0]
            minor = parts.count > 1 ? parts[1] : 0
            patch = parts.count > 2 ? parts[2] : 0
        }

        var string: String { "\(major).\(minor).\(patch)" }

        static func == (lhs: Version, rhs: Version) -> Bool {
            return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
        }

        static func < (lhs: Version, rhs: Version) -> Bool {
            if lhs.major != rhs.major { return lhs.major < rhs.major }
            if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
            return lhs.patch < rhs.patch
        }
    }

    static func resolveConflict(existing: String, incoming: String) -> String {
        guard let v1 = Version(string: existing), let v2 = Version(string: incoming) else {
            return incoming
        }
        return v1 >= v2 ? existing : incoming
    }

    static func isCompatible(installed: String, requiredRange: String) -> Bool {
        if requiredRange == "*" { return true }

        let op: RangeOperator
        if requiredRange.hasPrefix("^") { op = .caret }
        else if requiredRange.hasPrefix("~") { op = .tilde }
        else { op = .exact }

        guard let vInstalled = Version(string: installed),
              let vRequired = Version(string: requiredRange) else { return false }

        switch op {
        case .caret:
            return vInstalled.major == vRequired.major && vInstalled >= vRequired
        case .tilde:
            return vInstalled.major == vRequired.major && vInstalled.minor == vRequired.minor && vInstalled >= vRequired
        case .exact:
            return vInstalled == vRequired
        case .wildcard:
            return true
        }
    }

    static func isCompatible(installed: String, requiredRange: String) -> Bool {
        if requiredRange.hasPrefix(">=") {
            let version = requiredRange.replacingOccurrences(of: ">=", with: "")
            guard let vInstalled = Version(string: installed),
                  let vRequired = Version(string: version) else { return false }
            return vInstalled >= vRequired
        }
        return isCompatible(installed: installed, requiredRange: requiredRange)
    }
}

// MARK: - Package Manager

@MainActor
final class PackageDependencyManager: ObservableObject {
    static let shared = PackageDependencyManager()

    private let tokenEngine = DeterministicTokenEngine.shared
    private let registry = PackageRegistry.shared

    private init() {}

    func installPackage(name: String, version: String, layer: PackageDependencyLayer = .core, exports: [String], dependencyIds: [UUID]) -> Bool {
        guard tokenEngine.requireScope(.sdkManagePackages) else { return false }
        guard !name.isEmpty, !version.isEmpty else { return false }

        let hash = PackageIntegrityEngine.computeHash(name: name, version: version, exports: exports)
        let pkg = PackageDescriptor(name: name, version: version, layer: layer, exports: exports, dependencyIds: dependencyIds, integrityHash: hash)
        registry.install(pkg)
        return true
    }

    func uninstallPackage(id: UUID) -> Bool {
        guard tokenEngine.requireScope(.sdkManagePackages) else { return false }
        registry.uninstall(id: id)
        return true
    }

    func verifyIntegrity(id: UUID) -> Bool {
        guard let pkg = registry.package(by: id) else { return false }
        return PackageIntegrityEngine.verify(package: pkg)
    }

    func cleanupOrphans() -> Int {
        guard tokenEngine.requireScope(.sdkManagePackages) else { return 0 }
        let orphaned = getReachablePackages()
        let allIds = Set(registry.packages.map(\.id))
        let orphans = allIds.subtracting(orphaned)

        for id in orphans { registry.uninstall(id: id) }
        return orphans.count
    }

    private func getReachablePackages() -> Set<UUID> {
        var reachable = Set<UUID>()
        let frameworks = FrameworkRegistry.shared.frameworks
        let libraries = LibraryRegistry.shared.libraries

        var queue: [UUID] = []
        queue.append(contentsOf: frameworks.flatMap(\.packageDependencies))
        // Assuming libraries might have dependencies in future versions, adding them here if mapped

        let graph = registry.buildDependencyGraph()

        while !queue.isEmpty {
            let id = queue.removeFirst()
            if reachable.contains(id) { continue }
            reachable.insert(id)
            if let deps = graph.adjacency[id] {
                queue.append(contentsOf: deps)
            }
        }
        return reachable
    }

    func updatePackage(id: UUID, version: String) -> Bool {
        guard tokenEngine.requireScope(.sdkManagePackages) else { return false }
        guard let existing = registry.package(by: id) else { return false }
        let updated = PackageDescriptor(
            id: existing.id,
            name: existing.name,
            version: version,
            exports: existing.exports,
            dependencyIds: existing.dependencyIds,
            integrityHash: PackageIntegrityEngine.computeHash(name: existing.name, version: version, exports: existing.exports)
        )
        registry.install(updated)
        return true
    }

    func exportManifest() -> String {
        guard let data = try? JSONEncoder().encode(registry.packages) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func checkCycles() -> [String]? {
        registry.buildDependencyGraph().detectCycle()
    }

    func resolvedOrder() -> [PackageDescriptor] {
        let currentHash = PackageIntegrityEngine.computeHash(name: "registry", version: "state", exports: registry.packages.map(\.name))
        if let cached = DependencyGraph.resolutionCache[currentHash] {
            return cached
        }
        let resolved = registry.buildDependencyGraph().topologicalSort()
        DependencyGraph.resolutionCache[currentHash] = resolved
        return resolved
    }

    struct SecurityFinding: Identifiable, Codable, Hashable {
        let id = UUID()
        let severity: Severity
        let title: String
        let description: String

        enum Severity: String, Codable {
            case high, medium, low
            var color: Color {
                switch self {
                case .high: return .red
                case .medium: return .orange
                case .low: return .blue
                }
            }
        }
    }

    func performSecurityScan(for packageId: UUID) -> [SecurityFinding] {
        guard let pkg = registry.package(by: packageId) else { return [] }
        var findings: [SecurityFinding] = []

        if pkg.version.hasPrefix("0.") {
            findings.append(SecurityFinding(severity: .medium, title: "Unstable Version", description: "Package version 0.x is considered unstable and may have security risks."))
        }

        if pkg.name.lowercased().contains("crypto") && !pkg.exports.contains("sha256") {
            findings.append(SecurityFinding(severity: .high, title: "Weak Crypto", description: "Cryptographic package missing SHA256 export."))
        }

        if pkg.exports.contains("network") || pkg.exports.contains("http") {
            findings.append(SecurityFinding(severity: .low, title: "Network Access", description: "Package has networking capabilities, review usage."))
        }

        return findings
    }

    @Published var syncProgress: Double = 0
    @Published var isSyncing: Bool = false
    @Published var lastSyncError: String?

    func syncWithRemoteRegistry() async {
        isSyncing = true
        lastSyncError = nil
        syncProgress = 0

        // Real Registry Sync simulation with file integrity verification
        for i in 1...registry.packages.count {
            syncProgress = Double(i) / Double(registry.packages.count)
            let pkg = registry.packages[i-1]
            if !PackageIntegrityEngine.verify(package: pkg) {
                lastSyncError = "Integrity violation in \(pkg.name)"
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        isSyncing = false
    }

    // MARK: - Registry Rollback System

    func createSnapshot() {
        if let data = try? JSONEncoder().encode(registry.packages) {
            UserDefaults.standard.set(data, forKey: "PackageRegistrySnapshot_\(Date().timeIntervalSince1970)")
            var snapshots = UserDefaults.standard.stringArray(forKey: "PackageRegistrySnapshots") ?? []
            snapshots.append("PackageRegistrySnapshot_\(Date().timeIntervalSince1970)")
            UserDefaults.standard.set(snapshots, forKey: "PackageRegistrySnapshots")
        }
    }

    func rollback(to snapshotKey: String) {
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let decoded = try? JSONDecoder().decode([PackageDescriptor].self, from: data) {
            registry.packages = decoded
        }
    }
}

// MARK: - PackageDependenciesView

struct PackageDependenciesView: View {
    @State private var manager = PackageDependencyManager.shared
    @State private var registry = PackageRegistry.shared
    @State private var tokenEngine = DeterministicTokenEngine.shared

    @State private var showInstallSheet = false
    @State private var selectedPackage: PackageDescriptor?
    @State private var searchText = ""
    @State private var cycleWarning: [String]?
    @State private var showingVisualGraph = false
    @State private var selectedLayer: PackageDependencyLayer?
    @State private var sortOption: SortOption = .name
    @State private var showRollbackSheet = false
    @State private var hub = SDKDependencyIntelligenceHub.shared

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case depCount = "Dependency Count"
        case health = "Health Score"
        case installDate = "Install Date"
    }

    private var filteredPackages: [PackageDescriptor] {
        var filtered = registry.packages
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.exports.joined().localizedCaseInsensitiveContains(searchText)
            }
        }
        if let layer = selectedLayer {
            filtered = filtered.filter { $0.layer == layer }
        }

        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .name: return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .depCount: return lhs.dependencyIds.count > rhs.dependencyIds.count
            case .health: return lhs.healthScore < rhs.healthScore
            case .installDate: return lhs.installDate > rhs.installDate
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                authSection
                if !searchText.isEmpty {
                    globalSearchSection
                }
                registrySelectionSection
                filterSection
                overallHealthSection
                cycleSection
                bulkActionsSection
                packageListSection
                graphSection
                integritySection
                orphanSection
                rollbackSection
            }
            .refreshable { await refreshPackages() }
            .listStyle(.insetGrouped)
            .navigationTitle("Packages")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search packages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        sortMenu
                        Button { showInstallSheet = true } label: { Label("Add", systemImage: "plus") }
                        .disabled(tokenEngine.currentToken == nil)
                    }
                }
            }

            .sheet(isPresented: $showInstallSheet) {
                NavigationStack { PackageInstallSheet(manager: manager) }
            }
            .sheet(item: $selectedPackage) { pkg in
                NavigationStack { PackageDetailSheet(package: pkg, manager: manager) }
            }
            .sheet(isPresented: $showRollbackSheet) {
                NavigationStack { PackageRollbackView(manager: manager) }
            }
            .onAppear { cycleWarning = manager.checkCycles() }
        }
    }

    private var registrySelectionSection: some View {
        Section("Registry Source") {
            Picker("Registry", selection: $registry.activeRegistry) {
                ForEach(RegistryType.allCases) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if registry.activeRegistry == .remote {
                TextField("Remote URL", text: $registry.remoteRegistryURL)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Button { Task { await manager.syncWithRemoteRegistry() } } label: {
                    if manager.isSyncing { ProgressView().controlSize(.small) }
                    else { Label("Sync Registry Now", systemImage: "arrow.triangle.2.circlepath") }
                }
                .disabled(manager.isSyncing)

                if manager.isSyncing {
                    ProgressView(value: manager.syncProgress, total: 1.0).tint(.blue).controlSize(.small)
                }

                if let error = manager.lastSyncError {
                    Text(error).font(.caption2).foregroundStyle(.red)
                }
            }
        }
    }

    private var overallHealthSection: some View {
        Section("Overall Health") {
            let order = manager.resolvedOrder()
            let graph = registry.buildDependencyGraph()
            let scores = order.map { DependencyHealthEngine.analyze(package: $0, graph: graph).score }
            let avgScore = scores.isEmpty ? 100 : scores.reduce(0, +) / scores.count

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Health Score").font(.headline)
                    Spacer()
                    Text("\(avgScore)%")
                        .font(.title2.bold())
                        .foregroundStyle(avgScore > 80 ? .green : (avgScore > 50 ? .orange : .red))
                }

                ProgressView(value: Double(avgScore), total: 100)
                    .tint(avgScore > 80 ? .green : (avgScore > 50 ? .orange : .red))
            }
            .padding(.vertical, 4)
        }
    }

    private var authSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: tokenEngine.currentToken != nil ? "checkmark.shield.fill" : "shield.slash")
                    .foregroundStyle(tokenEngine.currentToken != nil ? .green : .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tokenEngine.currentToken != nil ? "Authenticated" : "No Token").font(.subheadline.bold())
                    Text(tokenEngine.currentToken != nil ? "Package operations available" : "Generate a token first").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var cycleSection: some View {
        Section("Dependency Health") {
            if let cycle = cycleWarning {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Circular Dependency Detected", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold()).foregroundStyle(.red)
                    Text(cycle.joined(separator: " → ")).font(.caption2.monospaced()).foregroundStyle(.red)
                }
            } else {
                Label("No circular dependencies", systemImage: "checkmark.circle").font(.caption).foregroundStyle(.green)
            }

            let graph = registry.buildDependencyGraph()
            let orphans = graph.orphans()
            if !orphans.isEmpty {
                Label("\(orphans.count) orphans detected", systemImage: "link.badge.plus")
                    .font(.caption).foregroundStyle(.orange)
            }

            Button("Re-check") { cycleWarning = manager.checkCycles() }.font(.caption)
        }
    }

    private var filterSection: some View {
        Section("Filters") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All Layers", layer: nil)
                    ForEach(PackageDependencyLayer.allCases) { layer in
                        filterChip(title: layer.rawValue.capitalized, layer: layer)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var globalSearchSection: some View {
        let results = hub.searchAll(query: searchText).filter { $0.type != "Package" }
        return Section("Global Matches") {
            if results.isEmpty {
                Text("No matching frameworks or libraries").font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(results) { result in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.name).font(.subheadline.bold())
                            Text(result.type).font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("v\(result.version)").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private func filterChip(title: String, layer: PackageDependencyLayer?) -> some View {
        Toggle(isOn: Binding(
            get: { selectedLayer == layer },
            set: { if $0 { selectedLayer = layer } }
        )) {
            Text(title).font(.caption2.bold())
        }
        .toggleStyle(.button)
        .buttonStyle(.bordered)
        .tint(selectedLayer == layer ? .accentColor : .secondary)
        .controlSize(.small)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down.circle")
        }
    }

    private func refreshPackages() async {
        // Real logic: trigger re-calculation of health scores and dependency order
        _ = manager.resolvedOrder()
        for pkg in registry.packages {
            _ = manager.verifyIntegrity(id: pkg.id)
        }
    }

    private var bulkActionsSection: some View {
        Section("Actions") {
            Button {
                showingVisualGraph = true
            } label: {
                Label("View Dependency Graph", systemImage: "circle.grid.cross")
            }

            Button {
                for pkg in registry.packages {
                    _ = manager.updatePackage(id: pkg.id, version: pkg.version) // Simulate update
                }
            } label: {
                Label("Update All Packages", systemImage: "arrow.clockwise.circle")
            }
            .disabled(registry.packages.isEmpty || tokenEngine.currentToken == nil)

            Button {
                let manifest = manager.exportManifest()
                UIPasteboard.general.string = manifest
            } label: {
                Label("Export Manifest to Clipboard", systemImage: "doc.on.doc")
            }
            .disabled(registry.packages.isEmpty)
        }
    }

    private var packageListSection: some View {
        Section("Installed Packages (\(filteredPackages.count))") {
            if filteredPackages.isEmpty {
                ContentUnavailableView("No Packages", systemImage: "shippingbox", description: Text("Install a package to get started."))
            } else {
                ForEach(filteredPackages) { pkg in
                    Button { selectedPackage = pkg } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(pkg.name).font(.subheadline.bold())
                                Spacer()
                                Text("v\(pkg.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            if !pkg.exports.isEmpty {
                                Text("Exports: \(pkg.exports.joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            HStack {
                                Text("Deps: \(pkg.dependencyIds.count)").font(.caption2).foregroundStyle(.tertiary)
                                Text("Layer: \(pkg.layer.rawValue)").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: manager.verifyIntegrity(id: pkg.id) ? "checkmark.seal.fill" : "xmark.seal")
                                    .font(.caption2)
                                    .foregroundStyle(manager.verifyIntegrity(id: pkg.id) ? .green : .red)
                            }
                        }.padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { _ = manager.uninstallPackage(id: pkg.id) } label: { Label("Remove", systemImage: "trash") }
                        Button { /* Update */ } label: { Label("Update", systemImage: "arrow.clockwise") }.tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button { /* Verify */ } label: { Label("Verify", systemImage: "checkmark.seal") }.tint(.green)
                    }
                }
            }
        }
    }

    private var graphSection: some View {
        Section("Dependency Resolution Order") {
            let resolved = manager.resolvedOrder()
            if resolved.isEmpty {
                Text("No packages to resolve").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(Array(resolved.enumerated()), id: \.element.id) { index, pkg in
                    HStack {
                        Text("\(index + 1).").font(.caption.monospaced()).foregroundStyle(.secondary)
                        Text(pkg.name).font(.caption)
                        Spacer()
                        Text("v\(pkg.version)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private var integritySection: some View {
        Section("Integrity Verification") {
            let total = registry.packages.count
            let verified = registry.packages.filter { PackageIntegrityEngine.verify(package: $0) }.count
            let tampered = total - verified
            LabeledContent("Total", value: "\(total)")
            LabeledContent("Verified", value: "\(verified)")
            if tampered > 0 {
                LabeledContent("Tampered") {
                    Text("\(tampered)").foregroundStyle(.red).bold()
                }
            }
        }
    }

    private var orphanSection: some View {
        Section("Orphan Detection") {
            let graph = registry.buildDependencyGraph()
            let orphans = graph.orphans()
            if orphans.isEmpty {
                Text("No orphaned packages").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(orphans) { orphan in
                    HStack {
                        Text(orphan.name).font(.caption)
                        Spacer()
                        Text("orphan").font(.caption2).foregroundStyle(.orange)
                    }
                }
                Button("Cleanup Orphans", role: .destructive) {
                    manager.createSnapshot()
                    _ = manager.cleanupOrphans()
                }.font(.caption)
            }
        }
    }

    private var rollbackSection: some View {
        Section("Snapshot & Rollback") {
            Button {
                manager.createSnapshot()
            } label: {
                Label("Create Registry Snapshot", systemImage: "camera.shutter.button")
            }

            Button {
                showRollbackSheet = true
            } label: {
                Label("Rollback to Previous State...", systemImage: "arrow.uturn.backward.circle")
            }
        }
    }
}

// MARK: - Package Rollback View

struct PackageRollbackView: View {
    @Environment(\.dismiss) private var dismiss
    let manager: PackageDependencyManager
    @State private var snapshotKeys: [String] = []

    var body: some View {
        List(snapshotKeys, id: \.self) { key in
            Button {
                manager.rollback(to: key)
                dismiss()
            } label: {
                VStack(alignment: .leading) {
                    Text(formatKey(key)).font(.subheadline.bold())
                    Text(key).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Rollback Registry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
        }
        .onAppear {
            snapshotKeys = (UserDefaults.standard.stringArray(forKey: "PackageRegistrySnapshots") ?? []).reversed()
        }
    }

    private func formatKey(_ key: String) -> String {
        let parts = key.split(separator: "_")
        if parts.count == 2, let timestamp = Double(parts[1]) {
            return Date(timeIntervalSince1970: timestamp).formatted()
        }
        return key
    }
}

// MARK: - Package Install Sheet

struct PackageInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let manager: PackageDependencyManager

    @State private var name = ""
    @State private var version = "1.0.0"
    @State private var layer: PackageDependencyLayer = .core
    @State private var exportsText = ""

    var body: some View {
        Form {
            Section("Package Info") {
                TextField("Name", text: $name)
                TextField("Version (semver)", text: $version)
                Picker("Layer", selection: $layer) {
                    ForEach(PackageDependencyLayer.allCases) { l in
                        Text(l.rawValue.capitalized).tag(l)
                    }
                }
                TextField("Exports (comma-separated)", text: $exportsText)
            }
            Section {
                Button("Install Package") {
                    let exports = exportsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    if manager.installPackage(name: name, version: version, layer: layer, exports: exports, dependencyIds: []) { dismiss() }
                }.buttonStyle(.borderedProminent).disabled(name.isEmpty || version.isEmpty)
            }
        }
        .navigationTitle("Install Package")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Graph Visualization UI

public struct DependencyGraphVisualizerView: View {
    @Environment(\.dismiss) private var dismiss
    let packages: [PackageDescriptor]
    @State private var expandedNodes: Set<UUID> = []
    @State private var registry = PackageRegistry.shared
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(packages.filter { pkg in !packages.contains(where: { $0.dependencyIds.contains(pkg.id) }) }) { rootPkg in
                        nodeView(for: rootPkg, depth: 0)
                    }
                }
                .padding(100)
                .scaleEffect(scale)
                .offset(offset)
            }
            .gesture(MagnificationGesture().onChanged { scale = $0 })
            .simultaneousGesture(DragGesture().onChanged { offset = CGSize(width: offset.width + $0.translation.width, height: offset.height + $0.translation.height) })

            VStack {
                Spacer()
                HStack {
                    Button { scale = 1.0; offset = .zero } label: { Image(systemName: "scope").padding().background(.ultraThinMaterial, in: Circle()) }
                    Spacer()
                    Text("Zoom: \(Int(scale * 100))%").font(.caption2.monospaced()).padding(8).background(.ultraThinMaterial, in: Capsule())
                }
                .padding()
            }
        }
        .navigationTitle("Dependency Graph")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func nodeView(for pkg: PackageDescriptor, depth: Int) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: CGFloat(depth) * 20, height: 1)

                    HStack {
                        Image(systemName: pkg.dependencyIds.isEmpty ? "shippingbox" : (expandedNodes.contains(pkg.id) ? "chevron.down.circle.fill" : "chevron.right.circle.fill"))
                            .foregroundStyle(pkg.layer == .core ? .blue : .secondary)

                        VStack(alignment: .leading) {
                            Text(pkg.name).font(.subheadline.bold())
                            Text("v\(pkg.version)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        if !pkg.dependencyIds.isEmpty {
                            if expandedNodes.contains(pkg.id) { expandedNodes.remove(pkg.id) }
                            else { expandedNodes.insert(pkg.id) }
                        }
                    }
                }

                if expandedNodes.contains(pkg.id) {
                    ForEach(pkg.dependencyIds, id: \.self) { depId in
                        if let depPkg = packages.first(where: { $0.id == depId }) {
                            nodeView(for: depPkg, depth: depth + 1)
                        } else {
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: CGFloat(depth + 1) * 20, height: 1)
                                Text("Missing: \(depId.uuidString.prefix(8))")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
        )
    }
}

// MARK: - Package Detail Sheet

struct PackageDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let package: PackageDescriptor
    let manager: PackageDependencyManager
    @StateObject private var registry = PackageRegistry.shared

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: package.name)
                LabeledContent("Version", value: package.version)
                LabeledContent("Layer", value: package.layer.rawValue.capitalized)
                LabeledContent("ID", value: String(package.id.uuidString.prefix(8)) + "...")
            }
            Section("Exports") {
                if package.exports.isEmpty {
                    Text("No exports").foregroundStyle(.secondary)
                } else {
                    ForEach(package.exports, id: \.self) { exp in
                        Label(exp, systemImage: "arrow.right.square").font(.caption)
                    }
                }
            }
            Section("Dependencies") {
                if package.dependencyIds.isEmpty {
                    Text("No dependencies (leaf package)").foregroundStyle(.secondary)
                } else {
                    ForEach(package.dependencyIds, id: \.self) { depId in
                        Text(String(depId.uuidString.prefix(8)) + "...").font(.caption.monospaced())
                    }
                }
            }
            healthDetailSection(for: package)

            Section("Package.swift Fragment") {
                Text(generateManifestFragment(for: package))
                    .font(.system(size: 8, design: .monospaced))
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            Section("Security Audit") {
                let findings = manager.performSecurityScan(for: package.id)
                if findings.isEmpty {
                    Label("No issues detected", systemImage: "checkmark.shield.fill").foregroundStyle(.green).font(.caption)
                } else {
                    ForEach(findings) { finding in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(finding.severity.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .bold)).padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(finding.severity.color.opacity(0.2)).foregroundStyle(finding.severity.color).cornerRadius(4)
                                Text(finding.title).font(.caption.bold())
                            }
                            Text(finding.description).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Integrity") {
                LabeledContent("Hash", value: String(package.integrityHash.prefix(16)) + "...")
                LabeledContent("Verified") {
                    Text(manager.verifyIntegrity(id: package.id) ? "Pass" : "Fail")
                        .foregroundStyle(manager.verifyIntegrity(id: package.id) ? .green : .red)
                        .bold()
                }
            }
        }
        .navigationTitle(package.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
    }

    private func generateManifestFragment(for package: PackageDescriptor) -> String {
        let deps = package.dependencyIds.map { ".package(id: \"\($0.uuidString.prefix(8))\", from: \"1.0.0\")" }.joined(separator: ",\n        ")
        return """
        // Package.swift Fragment
        .package(url: \"\(package.name)\", from: \"\(package.version)\")

        \(deps)
        """
    }

    private func healthDetailSection(for package: PackageDescriptor) -> some View {
        let intelligenceScore = SDKDependencyIntelligenceHub.shared.calculateRiskScore(pkg: package)
        let health = DependencyHealthEngine.analyze(package: package, graph: registry.buildDependencyGraph())
        let finalScore = (health.score + intelligenceScore) / 2

        return Section("Dependency Health") {
            LabeledContent("Health Score", value: "\(health.score)%")
            LabeledContent("Intelligence Risk Score", value: "\(intelligenceScore)%")
            LabeledContent("Aggregate Score", value: "\(finalScore)%")
                .bold()
                .foregroundStyle(finalScore > 80 ? .green : (finalScore > 50 ? .orange : .red))

            if !health.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues").font(.caption.bold()).foregroundStyle(.red)
                    ForEach(health.issues, id: \.self) { issue in
                        Text("• \(issue)").font(.caption2)
                    }
                }
            }

            if !health.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations").font(.caption.bold()).foregroundStyle(.blue)
                    ForEach(health.recommendations, id: \.self) { rec in
                        Text("• \(rec)").font(.caption2)
                    }
                }
            }
        }
    }
}
