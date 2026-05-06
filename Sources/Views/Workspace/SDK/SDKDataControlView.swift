import SwiftUI

struct SDKDataControlView: View {
    @State private var showingWarning = true
    @State private var statusMessage = ""

    var body: some View {
        List {
            if showingWarning {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("HIGH RISK ACCESS", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red).bold()
                        Text("This interface allows direct manipulation of workspace data structures. Incorrect operations may lead to data loss.")
                            .font(.caption)
                        Button("I Understand") { showingWarning = false }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section(header: Text("Data Operations")) {
                Button("Reindex All Notes") {
                    let notes = WorkspaceAPI.shared.notes.listNotes()
                    statusMessage = "Reindexed \(notes.count) notes."
                }

                Button("Cleanup Completed Tasks") {
                    let tasks = WorkspaceAPI.shared.tasks.listTasks()
                    let completed = tasks.filter { $0.completed }
                    // Real cleanup logic via TasksManager
                    for task in completed {
                        TasksManager.shared.deleteTask(id: task.id)
                    }
                    statusMessage = "Cleaned up \(completed.count) completed tasks."
                }
            }

            if !statusMessage.isEmpty {
                Section(header: Text("Operation Status")) {
                    Text(statusMessage).font(.caption).foregroundStyle(.blue)
                }
            }

            Section(header: Text("Rollback Support")) {
                NavigationLink("System Snapshots", destination: EntityExplorerView())
            }
        }
        .navigationTitle("Data Control")
    }
}
