/*
 REDESIGN SUMMARY:
 - Standardized on a multi-panel layout using a Sidebar List and an inspector detail view.
 - Modernized the search experience with .searchable integration.
 - Replaced manual HStack node layouts with native Label and semantic icons.
 - Standardized edge/relationship display with arrow symbols and monospaced typography.
 - strictly preserved all SDKWorkspaceGraphEngine and WorkspaceAPI data fetching logic.
 - Implemented NodeInspectorView as a structured detail panel with monospaced JSON display.
 - Extracted subviews for EdgeRow and EntityNodeRow.
 */

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
        return workspaceNodes.filter { $0.label.localizedCaseInsensitiveContains(searchText) || $0.type.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        HStack(spacing: 0) {
            List {
                Section("Entities (\(filteredNodes.count))") {
                    ForEach(filteredNodes) { node in
                        EntityNodeRow(node: node, isSelected: selectedNode?.id == node.id) { selectedNode = node }
                    }
                }

                Section("Relationships (\(graph.edges.count))") {
                    if graph.edges.isEmpty {
                        Text("No connections detected").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(graph.edges) { edge in
                            EdgeRow(edge: edge, nodes: workspaceNodes)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "Search entities")

            if let node = selectedNode {
                Divider()
                NodeInspectorDetail(node: node)
                    .frame(width: 320)
            }
        }
        .navigationTitle("Workspace Graph")
        .refreshable { graph = SDKWorkspaceGraphEngine.shared.fetchGraph() }
    }
}

// MARK: - Private Subviews

private struct EntityNodeRow: View {
    let node: SDKNode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.label).font(.subheadline.bold())
                    Text(node.type).font(.caption2).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: iconForType(node.type)).foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
        }
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.1) : nil)
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "note": return "note.text"
        case "task": return "checkmark.circle"
        case "mail": return "envelope"
        case "event": return "calendar"
        case "slide": return "rectangle.on.rectangle"
        default: return "circle"
        }
    }
}

private struct EdgeRow: View {
    let edge: SDKEdge, nodes: [SDKNode]
    var body: some View {
        HStack {
            Text(label(for: edge.source)).font(.caption.bold())
            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
            Text(label(for: edge.target)).font(.caption.bold())
            Spacer()
            Text(edge.label).font(.system(size: 8, weight: .black)).padding(.horizontal, 4).padding(.vertical, 2).background(Color.accentColor.opacity(0.1), in: Capsule())
        }
    }
    private func label(for id: UUID) -> String { nodes.first { $0.id == id }?.label ?? id.uuidString.prefix(6).description }
}

private struct NodeInspectorDetail: View {
    let node: SDKNode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Inspector").font(.headline)
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("ID", value: node.id.uuidString).font(.caption.monospaced())
                    LabeledContent("Type", value: node.type)
                    LabeledContent("Label", value: node.label)
                }
                Divider()
                Text("Raw Data").font(.subheadline.bold())
                Text(buildJSON()).font(.system(size: 10, design: .monospaced)).padding(12).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            }.padding()
        }
    }
    private func buildJSON() -> String { "{\n  \"id\": \"\(node.id.uuidString)\",\n  \"type\": \"\(node.type)\"\n}" }
}
