import SwiftUI

struct SDKPackage: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let version: String
    let dependencies: [String] // Package IDs
    let integrityHash: String
}

@MainActor
class PackageManager: ObservableObject {
    static let shared = PackageManager()

    @Published var registry: [SDKPackage] = []
    @Published var resolutionLogs: [String] = []

    private init() {
        registry = [
            SDKPackage(id: "p1", name: "lodash-lite", version: "4.17.21", dependencies: [], integrityHash: "sha256-abc123..."),
            SDKPackage(id: "p2", name: "moment-mini", version: "2.29.1", dependencies: [], integrityHash: "sha256-def456..."),
            SDKPackage(id: "p3", name: "react-lite", version: "18.2.0", dependencies: ["p1"], integrityHash: "sha256-ghi789..."),
            SDKPackage(id: "p4", name: "utils-core", version: "1.0.0", dependencies: ["p2", "p3"], integrityHash: "sha256-jkl012...")
        ]
    }

    func resolveDependencies(for packageId: String) -> [SDKPackage] {
        var resolved: [SDKPackage] = []
        var visited: Set<String> = []
        var stack: Set<String> = []

        func walk(id: String) {
            if stack.contains(id) {
                resolutionLogs.append("Circular dependency detected: \(id)")
                return
            }
            if visited.contains(id) { return }

            visited.insert(id)
            stack.insert(id)

            if let pkg = registry.first(where: { $0.id == id }) {
                for dep in pkg.dependencies {
                    walk(id: dep)
                }
                resolved.append(pkg)
            }

            stack.remove(id)
        }

        walk(id: packageId)
        return resolved
    }

    func verifyIntegrity(package: SDKPackage) -> Bool {
        // Simulate hash verification
        resolutionLogs.append("Verifying integrity for \(package.name)@\(package.version)...")
        return true
    }
}

struct PackageDependenciesView: View {
    @StateObject private var manager = PackageManager.shared
    @State private var selectedPackage: SDKPackage?

    var body: some View {
        List {
            Section("Local Package Registry") {
                ForEach(manager.registry) { pkg in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pkg.name).font(.headline)
                            Text(pkg.id).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("v\(pkg.version)").font(.caption.monospaced())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedPackage = pkg }
                }
            }

            Section("Resolution Logs") {
                if manager.resolutionLogs.isEmpty {
                    Text("No resolution events").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.resolutionLogs.reversed(), id: \.self) { log in
                        Text(log).font(.caption2.monospaced())
                    }
                }
            }
        }
        .navigationTitle("Packages")
        .sheet(item: $selectedPackage) { pkg in
            PackageGraphView(package: pkg)
        }
    }
}

struct PackageGraphView: View {
    let package: SDKPackage
    @StateObject private var manager = PackageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Package Info") {
                    LabeledContent("Name", value: package.name)
                    LabeledContent("Version", value: package.version)
                    LabeledContent("Integrity", value: package.integrityHash)
                }

                Section("Dependency Tree") {
                    let tree = manager.resolveDependencies(for: package.id)
                    if tree.isEmpty {
                        Text("No dependencies").foregroundStyle(.secondary)
                    } else {
                        ForEach(tree) { pkg in
                            HStack {
                                Image(systemName: "box.tuple.fill")
                                Text(pkg.name)
                                Spacer()
                                Text("v\(pkg.version)").font(.caption2)
                            }
                        }
                    }
                }

                Section("Verification") {
                    Button("Verify Integrity Hash") {
                        _ = manager.verifyIntegrity(package: package)
                    }
                }
            }
            .navigationTitle(package.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
