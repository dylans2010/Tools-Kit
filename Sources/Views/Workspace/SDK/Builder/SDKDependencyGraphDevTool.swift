import SwiftUI

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
    @StateObject private var registry = SDKModuleRegistry.shared

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Dependency Graph",
                description: "Visualize the load order and inter-module dependencies of the SDK architecture.",
                icon: "circle.grid.cross.fill"
            )
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(registry.resolvedLoadOrder()) { module in
                        HStack(alignment: .top) {
                            Circle().fill(Color.accentColor).frame(width: 8, height: 8).padding(.top, 6)
                            VStack(alignment: .leading) {
                                Text(module.displayName).font(.headline)
                                if !module.dependencies.isEmpty {
                                    Text("Depends on: \(module.dependencies.joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.leading, CGFloat(module.loadPriority / 10))
                    }
                }
                .padding()
            }
        }
    }
}
