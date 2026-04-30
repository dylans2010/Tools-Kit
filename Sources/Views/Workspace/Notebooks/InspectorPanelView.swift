import SwiftUI

struct InspectorPanelView: View {
    let block: NotebookBlock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Block Metadata") {
                    LabeledContent("ID", value: block.id.uuidString).font(.caption)
                    LabeledContent("Kind", value: block.kind.rawValue.capitalized)
                    LabeledContent("Created", value: block.createdAt, format: .dateTime)
                }

                Section("Configuration") {
                    ForEach(block.metadata.keys.sorted(), id: \.self) { key in
                        TextField(key, text: .constant(block.metadata[key] ?? ""))
                    }
                }

                Section("Advanced") {
                    Button("View Execution Logs") {}
                    Button("Inspect AI Context") {}
                }
            }
            .navigationTitle("Block Inspector")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DebugPanelView: View {
    @ObservedObject var vc = VersionControlManager.shared
    @ObservedObject var ai = AIContextEngine.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Version Control") {
                    LabeledContent("Active Branches", value: "\(vc.branches.count)")
                    LabeledContent("Total Commits", value: "\(vc.commits.count)")
                }

                Section("AI Context") {
                    LabeledContent("Indexed Entities", value: "\(ai.semanticIndex.count)")
                }
            }
            .navigationTitle("Workspace Debug")
        }
    }
}
