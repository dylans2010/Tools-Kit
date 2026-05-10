import SwiftUI

struct WorkspaceTaskDetailView: View {
    @State var task: WorkspaceTask
    @StateObject private var manager = TasksManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Label(task.completed ? "Completed" : "In Progress",
                          systemImage: task.completed ? "checkmark.circle.fill" : "circle")
                    Spacer()
                    Label(task.priority.rawValue, systemImage: task.priority.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Details") {
                if let due = task.dueDate {
                    Label(formatDate(due), systemImage: "calendar")
                        .foregroundStyle(task.isOverdue ? .red : .primary)
                }

                if let cat = manager.category(for: task) {
                    Label(cat.name, systemImage: "folder")
                }

                Label(formatDate(task.createdAt), systemImage: "clock")
                    .foregroundStyle(.secondary)
            }

            if !task.description.isEmpty {
                Section("Notes") {
                    Text(task.description)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil")
                }
                Button {
                    manager.toggleComplete(task)
                    dismiss()
                } label: {
                    Image(systemName: task.completed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CreateTaskView(existingTask: task) { updated in
                manager.updateTask(updated)
                task = updated
            }
        }
        .onReceive(manager.$tasks) { tasks in
            if let updated = tasks.first(where: { $0.id == task.id }) {
                task = updated
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
