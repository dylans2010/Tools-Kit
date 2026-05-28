import SwiftUI

struct SDKWorkspaceExplorerView: View {
    @State private var graph = SDKWorkspaceGraphEngine.shared.fetchGraph()
    @State private var searchText = ""
    @State private var selectedNode: SDKNode?

    private var workspaceNodes: [SDKNode] {
        var nodes: [SDKNode] = []
        nodes += WorkspaceAPI.shared.notes.listNotes().map { SDKNode(id: $0.id, label: $0.title, type: "Note") }
        nodes += WorkspaceAPI.shared.tasks.listTasks().map { SDKNode(id: $0.id, label: $0.title, type: "Task") }
        nodes += WorkspaceAPI.shared.calendar.listEvents().map { SDKNode(id: $0.id, label: $0.title, type: "Event") }
        nodes += WorkspaceAPI.shared.slides.listDecks().map { SDKNode(id: $0.id, label: $0.title, type: "Slide") }
        for gn in graph.nodes where !nodes.contains(where: { $0.id == gn.id }) { nodes.append(gn) }
        return nodes
    }

    private var filteredNodes: [SDKNode] {
        guard !searchText.isEmpty else { return workspaceNodes }
        return workspaceNodes.filter {
            $0.label.localizedCaseInsensitiveContains(searchText) ||
            $0.type.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let compactLayout = geometry.size.width < 700

            Group {
                if compactLayout {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            nodeListSection

                            if let node = selectedNode {
                                NodeInspectorDetail(node: node)
                            } else {
                                ContentUnavailableView(
                                    "No Node Selected",
                                    systemImage: "sidebar.right",
                                    description: Text("Select an entity to inspect details.")
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                } else {
                    HStack(spacing: 0) {
                        nodeListSection
                            .frame(width: min(max(320, geometry.size.width * 0.45), 520))
                        Divider()
                        Group {
                            if let node = selectedNode {
                                NodeInspectorDetail(node: node)
                            } else {
                                ContentUnavailableView(
                                    "No Node Selected",
                                    systemImage: "sidebar.right",
                                    description: Text("Select an entity to inspect details.")
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .safeAreaInset(edge: .bottom) { EmptyView().frame(height: 0) }
        }
        .navigationTitle("Workspace Graph")
        .searchable(text: $searchText, prompt: "Search entities")
        .refreshable { graph = SDKWorkspaceGraphEngine.shared.fetchGraph() }
    }

    private var nodeListSection: some View {
        List {
            Section(header: Text("Entities (\(filteredNodes.count))")) {
                ForEach(filteredNodes) { node in
                    Button {
                        selectedNode = node
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.label)
                                Text(node.type)
                                    .font(.caption)
                            }
                            Spacer()
                            if selectedNode?.id == node.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("Relationships (\(graph.edges.count))")) {
                if graph.edges.isEmpty {
                    Text("No connections detected")
                        .font(.caption)
                } else {
                    ForEach(graph.edges) { edge in
                        EdgeRow(edge: edge, nodes: workspaceNodes)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct EdgeRow: View {
    let edge: SDKEdge
    let nodes: [SDKNode]

    var body: some View {
        HStack {
            Text(label(for: edge.source))
                .font(.caption)
            Image(systemName: "arrow.right")
                .font(.caption)
            Text(label(for: edge.target))
                .font(.caption)
            Spacer()
            Text(edge.label)
                .font(.caption2)
        }
    }

    private func label(for id: UUID) -> String {
        nodes.first { $0.id == id }?.label ?? id.uuidString.prefix(6).description
    }
}

private struct NodeInspectorDetail: View {
    let node: SDKNode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Inspector")
                    .font(.headline)
                LabeledContent("ID", value: node.id.uuidString)
                LabeledContent("Type", value: node.type)
                LabeledContent("Label", value: node.label)

                Text("Raw Data")
                    .font(.subheadline)
                Text(buildJSON())
                    .font(.system(.caption, design: .monospaced))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func buildJSON() -> String {
        "{\n  \"id\": \"\(node.id.uuidString)\",\n  \"type\": \"\(node.type)\"\n}"
    }
}
