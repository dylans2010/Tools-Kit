import SwiftUI
import CryptoKit

// MARK: - Package Descriptor

struct PackageDescriptor: Identifiable, Codable {
    let id: UUID
    let name: String
    let version: String
    let exports: [String]
    let dependencyIds: [UUID]
    let integrityHash: String

    init(
        id: UUID = UUID(), name: String, version: String,
        exports: [String] = [], dependencyIds: [UUID] = [],
        integrityHash: String = ""
    ) {
        self.id = id; self.name = name; self.version = version
        self.exports = exports; self.dependencyIds = dependencyIds
        self.integrityHash = integrityHash
    }
}

// MARK: - Package Registry

@MainActor
final class PackageRegistry: ObservableObject {
    static let shared = PackageRegistry()
    @Published var packages: [PackageDescriptor] = []

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

// MARK: - DAG-Based Dependency Graph Engine

struct DependencyGraph {
    let packages: [PackageDescriptor]

    var adjacency: [UUID: [UUID]] {
        var map: [UUID: [UUID]] = [:]
        for pkg in packages { map[pkg.id] = pkg.dependencyIds }
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
    struct Version: Comparable {
        let major: Int
        let minor: Int
        let patch: Int

        init?(string: String) {
            let parts = string.split(separator: ".").compactMap { Int($0) }
            guard parts.count >= 3 else { return nil }
            major = parts[0]; minor = parts[1]; patch = parts[2]
        }

        var string: String { "\(major).\(minor).\(patch)" }

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

    static func isCompatible(installed: String, required: String) -> Bool {
        guard let v1 = Version(string: installed), let v2 = Version(string: required) else { return false }
        return v1.major == v2.major && v1 >= v2
    }
}

// MARK: - Package Manager

@MainActor
final class PackageDependencyManager: ObservableObject {
    static let shared = PackageDependencyManager()

    private let tokenEngine = DeterministicTokenEngine.shared
    private let registry = PackageRegistry.shared

    private init() {}

    func installPackage(name: String, version: String, exports: [String], dependencyIds: [UUID]) -> Bool {
        guard tokenEngine.requireScope(.sdkManagePackages) else { return false }
        guard !name.isEmpty, !version.isEmpty else { return false }

        let hash = PackageIntegrityEngine.computeHash(name: name, version: version, exports: exports)
        let pkg = PackageDescriptor(name: name, version: version, exports: exports, dependencyIds: dependencyIds, integrityHash: hash)
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
        let graph = registry.buildDependencyGraph()
        let orphaned = graph.orphans()
        for orphan in orphaned { registry.uninstall(id: orphan.id) }
        return orphaned.count
    }

    func checkCycles() -> [String]? {
        registry.buildDependencyGraph().detectCycle()
    }

    func resolvedOrder() -> [PackageDescriptor] {
        registry.buildDependencyGraph().topologicalSort()
    }
}

// MARK: - PackageDependenciesView

struct PackageDependenciesView: View {
    @StateObject private var manager = PackageDependencyManager.shared
    @StateObject private var registry = PackageRegistry.shared
    @StateObject private var tokenEngine = DeterministicTokenEngine.shared

    @State private var showInstallSheet = false
    @State private var selectedPackage: PackageDescriptor?
    @State private var searchText = ""
    @State private var cycleWarning: [String]?

    private var filteredPackages: [PackageDescriptor] {
        if searchText.isEmpty { return registry.packages }
        return registry.packages.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.exports.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                authSection
                cycleSection
                packageListSection
                graphSection
                integritySection
                orphanSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Packages")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search packages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showInstallSheet = true } label: { Label("Add", systemImage: "plus") }
                    .disabled(tokenEngine.currentToken == nil)
                }
            }
            .sheet(isPresented: $showInstallSheet) {
                NavigationStack { PackageInstallSheet(manager: manager) }
            }
            .sheet(item: $selectedPackage) { pkg in
                NavigationStack { PackageDetailSheet(package: pkg, manager: manager) }
            }
            .onAppear { cycleWarning = manager.checkCycles() }
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
            Button("Re-check") { cycleWarning = manager.checkCycles() }.font(.caption)
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
                                Spacer()
                                Image(systemName: manager.verifyIntegrity(id: pkg.id) ? "checkmark.seal.fill" : "xmark.seal")
                                    .font(.caption2)
                                    .foregroundStyle(manager.verifyIntegrity(id: pkg.id) ? .green : .red)
                            }
                        }.padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { _ = manager.uninstallPackage(id: pkg.id) } label: { Label("Remove", systemImage: "trash") }
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
                    _ = manager.cleanupOrphans()
                }.font(.caption)
            }
        }
    }
}

// MARK: - Package Install Sheet

struct PackageInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let manager: PackageDependencyManager

    @State private var name = ""
    @State private var version = "1.0.0"
    @State private var exportsText = ""

    var body: some View {
        Form {
            Section("Package Info") {
                TextField("Name", text: $name)
                TextField("Version (semver)", text: $version)
                TextField("Exports (comma-separated)", text: $exportsText)
            }
            Section {
                Button("Install Package") {
                    let exports = exportsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    if manager.installPackage(name: name, version: version, exports: exports, dependencyIds: []) { dismiss() }
                }.buttonStyle(.borderedProminent).disabled(name.isEmpty || version.isEmpty)
            }
        }
        .navigationTitle("Install Package")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Package Detail Sheet

struct PackageDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let package: PackageDescriptor
    let manager: PackageDependencyManager

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: package.name)
                LabeledContent("Version", value: package.version)
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
}
