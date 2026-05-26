import SwiftUI

struct SDKDependencyVisualizerView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var selectedNode: String?

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                if let project = projectManager.currentProject {
                    DependencyGraphView(project: project, selectedNode: $selectedNode)
                } else if !projectManager.projects.isEmpty {
                    DependencyGraphView(project: projectManager.projects[0], selectedNode: $selectedNode)
                } else {
                    ContentUnavailableView("No Project Found", systemImage: "shippingbox", description: Text("Create a project to visualize its dependencies."))
                }
            }
            .padding(100)
        }
        .navigationTitle("Dependency Visualizer")
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .bottom) {
            if let node = selectedNode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(node).font(.headline)
                        Spacer()
                        Button { selectedNode = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    }
                    Text("This component is a core dependency of the current SDK build.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

private struct DependencyGraphView: View {
    let project: SDKProject
    @Binding var selectedNode: String?

    var body: some View {
        VStack(spacing: 60) {
            // Root
            NodeView(node: DependencyNode(title: project.name, icon: "cube.fill", color: Color.blue, isSelected: selectedNode == project.name))
                .onTapGesture { selectedNode = project.name }

            HStack(alignment: .top, spacing: 40) {
                // Scopes
                VStack(spacing: 40) {
                    Text("Enabled Scopes").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(project.enabledScopes.prefix(5), id: \.self) { scope in
                        NodeView(node: DependencyNode(title: scope, icon: "shield.fill", color: .green, isSelected: selectedNode == scope))
                            .onTapGesture { selectedNode = scope }
                    }
                    if project.enabledScopes.count > 5 {
                        Text("+ \(project.enabledScopes.count - 5) more").font(.caption2).foregroundStyle(.tertiary)
                    }
                }

                // Plugins
                VStack(spacing: 40) {
                    Text("Active Plugins").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(project.enabledPluginIDs.prefix(5), id: \.self) { id in
                        NodeView(node: DependencyNode(title: id.uuidString.prefix(8).description, icon: "puzzlepiece.fill", color: .purple, isSelected: selectedNode == id.uuidString))
                            .onTapGesture { selectedNode = id.uuidString }
                    }
                }

                // Connectors
                VStack(spacing: 40) {
                    Text("Linked Connectors").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(project.enabledConnectorIDs.prefix(5), id: \.self) { id in
                        NodeView(node: DependencyNode(title: id.uuidString.prefix(8).description, icon: "link", color: .orange, isSelected: selectedNode == id.uuidString))
                            .onTapGesture { selectedNode = id.uuidString }
                    }
                }
            }
        }
    }
}

private struct DependencyNode {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
}

private struct NodeView: View {
    let node: DependencyNode

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: node.icon)
                .font(.title2)
                .foregroundStyle(node.isSelected ? .white : node.color)
                .frame(width: 50, height: 50)
                .background(node.isSelected ? node.color : node.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(node.color, lineWidth: 2))

            Text(node.title)
                .font(.caption2.bold())
                .lineLimit(1)
        }
        .frame(width: 80)
        .scaleEffect(node.isSelected ? 1.1 : 1.0)
        .animation(.spring(), value: node.isSelected)
    }
}
