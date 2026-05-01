import SwiftUI

struct ExportPipelineView: View {
    @StateObject private var manager = ExportPipelineManager.shared

    var body: some View {
        List {
            Section(header: Text("Render Queue")) {
                if manager.activeTasks.isEmpty {
                    Text("No active exports.")
                        .foregroundColor(.secondary)
                }

                ForEach(manager.activeTasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(task.projectName).bold()
                            Spacer()
                            Text(task.status.rawValue.capitalized)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }

                        ProgressView(value: task.progress)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button("Cancel", role: .destructive) {
                            manager.cancelTask(id: task.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Export Pipeline")
    }
}
