import SwiftUI
import Observation
import CryptoKit
import Combine

// MARK: - UNIFIED DEPENDENCY CORE (Shared logically across files)

struct DRCEPackageDescriptor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let version: String
    let layer: DRCEPackageLayer
    let dependencyIds: [UUID]
    var healthScore: Int = 100
    var volatility: Double = 0.1

    init(id: UUID = UUID(), name: String, version: String, layer: DRCEPackageLayer = .core, dependencyIds: [UUID] = [], healthScore: Int = 100, volatility: Double = 0.1) {
        self.id = id; self.name = name; self.version = version; self.layer = layer; self.dependencyIds = dependencyIds
        self.healthScore = healthScore; self.volatility = volatility
    }
}

enum DRCEPackageLayer: String, CaseIterable, Codable, Identifiable {
    case core, optional, dev; var id: String { rawValue }
}

// MARK: - 4. Core Engine Layer

struct DRCEGraphEngine {
    let packages: [DRCEPackageDescriptor]
    private static var closureCache: [UUID: Set<UUID>] = [:]

    func transitiveClosure(for id: UUID) -> Set<UUID> {
        if let cached = Self.closureCache[id] { return cached }
        var result = Set<UUID>(); var stack = [id]
        let adj = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, Set($0.dependencyIds)) })
        while !stack.isEmpty {
            let current = stack.removeLast()
            for neighbor in adj[current] ?? [] {
                if !result.contains(neighbor) { result.insert(neighbor); stack.append(neighbor) }
            }
        }
        Self.closureCache[id] = result; return result
    }

    func detectCycle() -> [String]? {
        let adj = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, Set($0.dependencyIds)) })
        let nameMap = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, $0.name) })
        var visited = Set<UUID>(); var stack = Set<UUID>()
        func dfs(_ node: UUID, path: [UUID]) -> [String]? {
            if stack.contains(node) {
                let start = path.firstIndex(of: node) ?? 0
                return path[start...].map { nameMap[$0] ?? "" } + [nameMap[node] ?? ""]
            }
            if visited.contains(node) { return nil }; visited.insert(node); stack.insert(node)
            for neighbor in adj[node] ?? [] { if let cycle = dfs(neighbor, path: path + [node]) { return cycle } }
            stack.remove(node); return nil
        }
        for pkg in packages { if let cycle = dfs(pkg.id, path: []) { return cycle } }
        return nil
    }
    static func invalidateCache() { closureCache.removeAll() }
}

struct DRCEBuildOptimizer {
    let packages: [DRCEPackageDescriptor]
    func computeOrder() -> [DRCEPackageDescriptor] {
        var inDegree = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, 0) })
        for pkg in packages { for dep in pkg.dependencyIds { inDegree[dep, default: 0] += 1 } }
        var queue = packages.filter { (inDegree[$0.id] ?? 0) == 0 }
        var result: [DRCEPackageDescriptor] = []
        while !queue.isEmpty {
            let node = queue.removeFirst(); result.append(node)
            for pkg in packages where pkg.dependencyIds.contains(node.id) {
                inDegree[pkg.id, default: 1] -= 1
                if inDegree[pkg.id] == 0, let p = packages.first(where: { $0.id == pkg.id }) { queue.append(p) }
            }
        }
        return result.reversed()
    }
}

// MARK: - 3. Service Layer

@MainActor
final class DRCEDependencyService: ObservableObject {
    static let shared = DRCEDependencyService()
    @Published var packages: [DRCEPackageDescriptor] = []
    private let eventBus = SDKEventBus.shared
    private init() {
        if let data = UserDefaults.standard.data(forKey: "DRCE_Pkgs"), let d = try? JSONDecoder().decode([DRCEPackageDescriptor].self, from: data) { self.packages = d }
    }
    func save() {
        DRCEGraphEngine.invalidateCache()
        if let data = try? JSONEncoder().encode(packages) { UserDefaults.standard.set(data, forKey: "DRCE_Pkgs") }
        eventBus.publish(SDKBusEvent(channel: "drce", name: "updated", data: ["count": "\(packages.count)"]))
    }
    func install(pkg: DRCEPackageDescriptor) { packages.removeAll { $0.name == pkg.name }; packages.append(pkg); save() }
}

// MARK: - 2. ViewModel Layer

@MainActor
final class PackageDependenciesViewModel: ObservableObject {
    @Published var searchText: String = ""
    private let service = DRCEDependencyService.shared
    var filteredPackages: [DRCEPackageDescriptor] { service.packages.filter { $0.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty } }
}

// MARK: - 1. Presentation Layer

struct PackageDependenciesView: View {
    @StateObject private var viewModel = PackageDependenciesViewModel()
    @StateObject private var service = DRCEDependencyService.shared
    @State private var showInstall = false

    var body: some View {
        NavigationStack {
            List {
                Section("Metrics") {
                    HStack {
                        metricTile(label: "Nodes", value: "\(service.packages.count)", color: .blue)
                        metricTile(label: "Healthy", value: "\(service.packages.filter{$0.healthScore > 80}.count)", color: .green)
                    }
                }
                Section("Graph") {
                    ForEach(viewModel.filteredPackages) { pkg in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pkg.name).font(.subheadline.bold())
                                Text("v\(pkg.version)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if DRCEGraphEngine(packages: service.packages).detectCycle() != nil { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                        }
                    }
                }
            }
            .navigationTitle("DRCE Engine")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button { showInstall = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showInstall) { DRCEInstallSheet() }
        }
    }
    private func metricTile(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading) { Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary); Text(value).font(.title2.bold()).foregroundStyle(color) }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DRCEInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""; @State private var version = "1.0.0"
    var body: some View {
        Form {
            TextField("Name", text: $name); TextField("Version", text: $version)
            Button("Install") { DRCEDependencyService.shared.install(pkg: DRCEPackageDescriptor(name: name, version: version)); dismiss() }.disabled(name.isEmpty)
        }.navigationTitle("New Package").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Legacy Compatibility

@MainActor final class PackageRegistry { static let shared = PackageRegistry(); var packages: [DRCEPackageDescriptor] { DRCEDependencyService.shared.packages } }
@MainActor final class PackageDependencyManager { static let shared = PackageDependencyManager() }
typealias PackageDescriptor = DRCEPackageDescriptor
typealias PackageDependencyLayer = DRCEPackageLayer
