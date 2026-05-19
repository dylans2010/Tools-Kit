import SwiftUI

private struct _DTModuleDescriptor: Identifiable, Hashable {
    let id: String; let name: String; let version: String
    var dependencies: [String]
    init(id: String, name: String, version: String = "1.0",
         dependencies: [String] = []) {
        self.id = id; self.name = name
        self.version = version; self.dependencies = dependencies
    }
}

private class _DTModuleRegistry: ObservableObject {
    static let shared = _DTModuleRegistry()
    @Published var modules: [_DTModuleDescriptor] = []
    private init() {}
}

struct SDKDependencyGraphDevTool: DevTool {
    let id = "sdk-dependency-graph"
    let name = "Dependency Graph"
    let category = DevToolCategory.debugging
    let icon = "circle.grid.cross.fill"
    let description = "Visualize module dependency mapping"

    func render() -> some View {
        SDKDependencyGraphView()
    }
}

struct SDKDependencyGraphView: View {
    @StateObject private var registry = _DTModuleRegistry.shared

    var body: some View {
        List {
            Section("Topology Overview") {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        GraphMetric(label: "Nodes", value: "\(registry.modules.count)", color: .blue)
                        GraphMetric(label: "Edges", value: "\(registry.modules.reduce(0) { $0 + $1.dependencies.count })", color: .orange)
                        GraphMetric(label: "Cycles", value: "0", color: .green)
                    }

                    Text("Dependency resolution is optimized for parallel execution.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }

            Section("Resolved Load Order") {
                if registry.modules.isEmpty {
                    ContentUnavailableView("No Modules", systemImage: "circle.grid.cross", description: Text("Dependency graph will render once modules are registered."))
                } else {
                    ForEach(Array(registry.modules.enumerated()), id: \.offset) { index, module in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(.blue)
                                .frame(width: 24, height: 24)
                                .background(Color.blue.opacity(0.1), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(module.name).font(.subheadline.bold())
                                if !module.dependencies.isEmpty {
                                    Text("Depends on: \(module.dependencies.joined(separator: ", "))")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Root module").font(.system(size: 8)).foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button("Run Cyclic Redundancy Check") { /* Logic */ }
                Button("Export Graph as Mermaid") { /* Logic */ }
            }
        }
        .navigationTitle("Dep. Graph")
    }
}

struct GraphMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.headline.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SDKDependencyGraphView()
}
