import SwiftUI

struct TaskDetailView: View {
    @State var task: WorkspaceTask
    @ObservedObject var manager: TasksManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status row
                HStack {
                    Button {
                        manager.toggleComplete(task)
                        if let updated = manager.tasks.first(where: { $0.id == task.id }) {
                            task = updated
                        }
                    } label: {
                        Label(
                            task.completed ? "Completed" : "Mark Complete",
                            systemImage: task.completed ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.subheadline.bold())
                        .foregroundColor(task.completed ? .green : .accentColor)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    priorityBadge
                }
                .padding(.horizontal)

                // Title & description
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2.bold())
                        .strikethrough(task.completed)
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Metadata
                metadataSection

                // Board status
                boardStatusSection
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: {
            if let updated = manager.tasks.first(where: { $0.id == task.id }) {
                task = updated
            }
        }) {
            CreateTaskView(manager: manager, editingTask: task)
        }
    }

    private var priorityBadge: some View {
        let color = Color(hex: task.priority.color) ?? .blue
        return Label(task.priority.rawValue, systemImage: task.priority.icon)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
    }

    private var metadataSection: some View {
        VStack(spacing: 0) {
            if let due = task.dueDate {
                metaRow(icon: "calendar", label: "Due Date", value: DateFormatter.localizedString(from: due, dateStyle: .medium, timeStyle: .none))
            }
            if let cat = manager.category(for: task.categoryID) {
                metaRow(icon: "tag", label: "Category", value: cat.name)
            }
            metaRow(icon: "clock", label: "Created", value: DateFormatter.localizedString(from: task.createdAt, dateStyle: .medium, timeStyle: .short))
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon).foregroundColor(.accentColor).frame(width: 24)
                Text(label).foregroundColor(.secondary)
                Spacer()
                Text(value).font(.subheadline)
            }
            .padding()
            Divider().padding(.leading, 52)
        }
    }

    private var boardStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Board Status").font(.headline).padding(.horizontal)
            HStack(spacing: 10) {
                ForEach(WorkspaceTask.BoardStatus.allCases, id: \.self) { status in
                    Button {
                        manager.moveTask(task, to: status)
                        if let updated = manager.tasks.first(where: { $0.id == task.id }) {
                            task = updated
                        }
                    } label: {
                        Text(status.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(task.boardStatus == status ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(task.boardStatus == status ? .white : .primary)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
