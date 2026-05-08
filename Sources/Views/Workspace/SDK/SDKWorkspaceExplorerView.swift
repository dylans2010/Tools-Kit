import SwiftUI

struct SDKWorkspaceExplorerView: View {
    @State private var graph = SDKWorkspaceGraphEngine.shared.fetchGraph()
    @State private var searchText = ""
    @State private var selectedNode: SDKNode?

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding()

            Divider()

            HStack(spacing: 0) {
                List {
                    Section {
                        ForEach(filteredNodes) { node in
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
                    } header: {
                        Text("Nodes (\(filteredNodes.count))")
                    }

                    Section {
                        if graphEdges.isEmpty {
                            Text("No relationships found").foregroundStyle(.secondary).font(.caption)
                        } else {
                            ForEach(graphEdges) { edge in
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
                    } header: {
                        Text("Relationships (\(graphEdges.count))")
                    }
                }
                .listStyle(.insetGrouped)

                if let node = selectedNode {
                    NodeInspectorView(node: node)
                        .frame(width: 300)
                        .background(Color(.secondarySystemBackground))
                }
            }
        }
        .navigationTitle("Workspace Explorer")
        .onAppear { refreshGraph() }
        .refreshable { refreshGraph() }
    }

    private func refreshGraph() {
        graph = SDKWorkspaceGraphEngine.shared.fetchGraph()
    }

    private var workspaceNodes: [SDKNode] {
        var nodes: [SDKNode] = []
        let notes = WorkspaceAPI.shared.notes.listNotes()
        nodes += notes.map { SDKNode(id: $0.id, label: $0.title, type: "Note") }
        let tasks = WorkspaceAPI.shared.tasks.listTasks()
        nodes += tasks.map { SDKNode(id: $0.id, label: $0.title, type: "Task") }
        let events = WorkspaceAPI.shared.calendar.listEvents()
        nodes += events.map { SDKNode(id: $0.id, label: $0.title, type: "Event") }
        let decks = WorkspaceAPI.shared.slides.listDecks()
        nodes += decks.map { SDKNode(id: $0.id, label: $0.title, type: "Slide") }
        let files = WorkspaceAPI.shared.files.listFiles()
        nodes += files.map { SDKNode(id: UUID(), label: $0.name, type: "File") }
        for gn in graph.nodes where !nodes.contains(where: { $0.id == gn.id }) {
            nodes.append(gn)
        }
        return nodes
    }

    private var filteredNodes: [SDKNode] {
        guard !searchText.isEmpty else { return workspaceNodes }
        return workspaceNodes.filter {
            $0.label.localizedCaseInsensitiveContains(searchText) ||
            $0.type.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var graphEdges: [SDKEdge] {
        return graph.edges
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "note": return "note.text"
        case "task": return "checkmark.circle"
        case "mail": return "envelope"
        case "event": return "calendar"
        case "file": return "doc"
        case "slide": return "rectangle.on.rectangle"
        default: return "circle"
        }
    }

    private func labelForNode(_ id: UUID) -> String {
        return workspaceNodes.first(where: { $0.id == id })?.label ?? graph.nodes.first(where: { $0.id == id })?.label ?? id.uuidString.prefix(8).description
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
                let jsonData = buildNodeJSON()
                Text(jsonData)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(.black.opacity(0.05))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    private func buildNodeJSON() -> String {
        var fields: [String: String] = [
            "id": node.id.uuidString,
            "title": node.label,
            "type": node.type.lowercased()
        ]

        switch node.type.lowercased() {
        case "note":
            if let note = WorkspaceAPI.shared.notes.listNotes().first(where: { $0.id == node.id }) {
                fields["content"] = note.content
                fields["updated_at"] = note.updatedAt.ISO8601Format()
            }
        case "task":
            if let task = WorkspaceAPI.shared.tasks.listTasks().first(where: { $0.id == node.id }) {
                fields["completed"] = "\(task.completed)"
                if let due = task.dueDate {
                    fields["due_date"] = due.ISO8601Format()
                }
            }
        default:
            break
        }

        let entries = fields.sorted(by: { $0.key < $1.key }).map { "    \"\($0.key)\": \"\($0.value)\"" }
        return "{\n" + entries.joined(separator: ",\n") + "\n}"
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
