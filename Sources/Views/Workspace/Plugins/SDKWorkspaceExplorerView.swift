import SwiftUI

struct SDKWorkspaceExplorerView: View {
    @State private var graph = SDKWorkspaceGraphEngine.shared.fetchGraph()
    @State private var searchText = ""
    @State private var selectedNode: SDKNode?

    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter
            SearchBar(text: $searchText, placeholder: "Search Workspace Entities...")
                .padding()

            Divider()

            HStack(spacing: 0) {
                // Graph Visualization (Simulated with a list for mobile-first)
                List {
                    Section("Nodes") {
                        ForEach(mockNodes) { node in
                            Button { selectedNode = node } label: {
                                HStack {
                                    Image(systemName: iconForType(node.type))
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading) {
                                        Text(node.label).font(.body)
                                        Text(node.type).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Section("Relationships") {
                        ForEach(mockEdges) { edge in
                            HStack {
                                Text(labelForNode(edge.source))
                                Image(systemName: "arrow.right").font(.caption)
                                Text(labelForNode(edge.target))
                                Spacer()
                                Text(edge.label)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Inspector
                if let node = selectedNode {
                    NodeInspectorView(node: node)
                        .frame(width: 300)
                        .background(Color(.secondarySystemBackground))
                }
            }
        }
        .navigationTitle("Workspace Explorer")
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "Note": return "note.text"
        case "Task": return "checkmark.circle"
        case "Mail": return "envelope"
        case "Event": return "calendar"
        case "File": return "doc"
        default: return "circle"
        }
    }

    private func labelForNode(_ id: UUID) -> String {
        return mockNodes.first(where: { $0.id == id })?.label ?? "Unknown"
    }

    // Real data for explorer from WorkspaceAPI
    private var mockNodes: [SDKNode] {
        let notes = WorkspaceAPI.shared.notes.listNotes().map { SDKNode(id: UUID(uuidString: $0.id) ?? UUID(), label: $0.title, type: "Note") }
        let tasks = WorkspaceAPI.shared.tasks.listTasks().map { SDKNode(id: $0.id, label: $0.title, type: "Task") }
        let events = WorkspaceAPI.shared.calendar.listEvents().map { SDKNode(id: $0.id, label: $0.title, type: "Event") }
        return notes + tasks + events
    }

    private var mockEdges: [SDKEdge] {
        // In a real implementation, this would fetch from IntelligenceFramework.shared
        return []
    }
}

struct NodeInspectorView: View {
    let node: SDKNode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inspector").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "ID", value: node.id.uuidString)
                InfoRow(label: "Type", value: node.type)
                InfoRow(label: "Label", value: node.label)
            }

            Divider()

            Text("Raw Entity Data").font(.subheadline).bold()
            ScrollView {
                Text("""
                {
                    "id": "\(node.id.uuidString)",
                    "title": "\(node.label)",
                    "type": "\(node.type.lowercased())",
                    "created_at": "2023-10-27T10:00:00Z"
                }
                """)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .background(.black.opacity(0.05))
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.caption).monospaced()
        }
    }
}
