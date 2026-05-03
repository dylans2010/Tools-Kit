import SwiftUI
import Workspace

// MARK: - Content Graph View

struct ContentGraphView: View {
    @StateObject private var graph = ContentGraphService.shared
    @State private var selectedNode: ContentGraphService.ContentNode?
    @State private var showingAddNode = false
    @State private var searchText = ""
    @State private var selectedType: ContentGraphService.NodeType?

    private var displayedNodes: [ContentGraphService.ContentNode] {
        var nodes = graph.nodes
        if let type = selectedType { nodes = nodes.filter { $0.nodeType == type } }
        if !searchText.isEmpty { nodes = nodes.filter { $0.label.localizedCaseInsensitiveContains(searchText) } }
        return nodes
    }

    var body: some View {
        VStack(spacing: 0) {
            // Type filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedType == nil) { selectedType = nil }
                    ForEach(ContentGraphService.NodeType.allCases, id: \.self) { type in
                        FilterChip(title: type.rawValue, isSelected: selectedType == type) { selectedType = type }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))

            Divider()

            if displayedNodes.isEmpty {
                ContentUnavailableView(
                    "No Nodes",
                    systemImage: "circle.dashed",
                    description: Text("Add nodes to build your content graph.")
                )
            } else {
                List {
                    ForEach(displayedNodes) { node in
                        NodeRow(node: node, edgeCount: graph.edges(for: node.id).count) {
                            selectedNode = node
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { displayedNodes[$0].id }.forEach { graph.removeNode(id: $0) }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search nodes…")
        .navigationTitle("Content Graph")
        .toolbar {
            Button(action: { showingAddNode = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddNode) {
            AddNodeView()
        }
        .sheet(item: $selectedNode) { node in
            NodeDetailView(nodeID: node.id)
        }
    }
}

// MARK: - Node Row

struct NodeRow: View {
    let node: ContentGraphService.ContentNode
    let edgeCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconFor(node.nodeType))
                    .font(.title3)
                    .foregroundStyle(colorFor(node.nodeType))
                    .frame(width: 36, height: 36)
                    .background(colorFor(node.nodeType).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(node.label).font(.subheadline).bold()
                    Text(node.nodeType.rawValue).font(.caption).foregroundStyle(.secondary)
                    if !node.tags.isEmpty {
                        Text(node.tags.prefix(3).joined(separator: " · ")).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(edgeCount)").font(.caption).bold().foregroundStyle(.blue)
                    Text("links").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ type: ContentGraphService.NodeType) -> String {
        switch type {
        case .note: return "note.text"
        case .task: return "checkmark.square.fill"
        case .file: return "doc.fill"
        case .decision: return "chart.bar.fill"
        case .member: return "person.fill"
        }
    }

    private func colorFor(_ type: ContentGraphService.NodeType) -> Color {
        switch type {
        case .note: return .blue
        case .task: return .green
        case .file: return .orange
        case .decision: return .purple
        case .member: return .indigo
        }
    }
}

// MARK: - Node Detail

struct NodeDetailView: View {
    let nodeID: UUID
    @StateObject private var graph = ContentGraphService.shared
    @State private var linkTargetID: UUID?
    @State private var linkType = ContentGraphService.EdgeType.reference
    @State private var showingLinkPicker = false
    @Environment(\.dismiss) var dismiss

    private var node: ContentGraphService.ContentNode? { graph.nodes.first { $0.id == nodeID } }
    private var neighbors: [ContentGraphService.ContentNode] { graph.neighbors(of: nodeID) }
    private var edges: [ContentGraphService.ContentEdge] { graph.edges(for: nodeID) }

    var body: some View {
        NavigationStack {
            List {
                if let node = node {
                    Section("Node Info") {
                        LabeledContent("Type", value: node.nodeType.rawValue)
                        LabeledContent("Created", value: node.createdAt.formatted(date: .abbreviated, time: .omitted))
                        if !node.tags.isEmpty {
                            LabeledContent("Tags", value: node.tags.joined(separator: ", "))
                        }
                    }
                }

                Section("Connections (\(neighbors.count))") {
                    if neighbors.isEmpty {
                        Text("No connections yet.").foregroundStyle(.secondary).font(.caption)
                    } else {
                        ForEach(neighbors) { neighbor in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(neighbor.label).font(.subheadline)
                                    if let edge = edges.first(where: { ($0.sourceID == nodeID && $0.targetID == neighbor.id) || ($0.targetID == nodeID && $0.sourceID == neighbor.id) }) {
                                        Text(edge.edgeType.rawValue).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    Button("Link to Node…") { showingLinkPicker = true }
                        .foregroundStyle(.blue)
                }

                if let node = node, !node.metadata.isEmpty {
                    Section("Metadata") {
                        ForEach(Array(node.metadata.keys.sorted()), id: \.self) { key in
                            LabeledContent(key, value: node.metadata[key] ?? "")
                        }
                    }
                }
            }
            .navigationTitle(node?.label ?? "Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        graph.removeNode(id: nodeID)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLinkPicker) {
                LinkNodePickerView(sourceNodeID: nodeID)
            }
        }
    }
}

// MARK: - Link Node Picker

struct LinkNodePickerView: View {
    let sourceNodeID: UUID
    @StateObject private var graph = ContentGraphService.shared
    @State private var linkType = ContentGraphService.EdgeType.reference
    @Environment(\.dismiss) var dismiss

    private var candidates: [ContentGraphService.ContentNode] {
        graph.nodes.filter { $0.id != sourceNodeID }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Edge Type") {
                    Picker("Type", selection: $linkType) {
                        ForEach(ContentGraphService.EdgeType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("Select Target Node") {
                    ForEach(candidates) { node in
                        Button {
                            graph.linkNodes(source: sourceNodeID, target: node.id, type: linkType)
                            dismiss()
                        } label: {
                            HStack {
                                Text(node.label)
                                Spacer()
                                Text(node.nodeType.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Link Node")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Node

struct AddNodeView: View {
    @StateObject private var graph = ContentGraphService.shared
    @Environment(\.dismiss) var dismiss
    @State private var label = ""
    @State private var nodeType = ContentGraphService.NodeType.note
    @State private var tagText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Node") {
                    TextField("Label", text: $label)
                    Picker("Type", selection: $nodeType) {
                        ForEach(ContentGraphService.NodeType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }
                Section("Tags (comma-separated)") {
                    TextField("e.g. design, sprint-2", text: $tagText)
                }
            }
            .navigationTitle("Add Node")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        graph.addNode(label: label, type: nodeType, tags: tags)
                        dismiss()
                    }
                    .disabled(label.isEmpty)
                }
            }
        }
    }
}

// MARK: - Filter Chip
