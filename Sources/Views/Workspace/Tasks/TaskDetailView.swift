import SwiftUI

struct WorkspaceTaskDetailView: View {
    @State var task: WorkspaceTask
    @StateObject private var manager = TasksManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    private var priorityColor: Color {
        Color(hex: task.priority.color) ?? .blue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusCard
                detailsCard
                if !task.description.isEmpty {
                    descriptionCard
                }
            }
            .padding()
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil")
                }
                Button {
                    manager.toggleComplete(task)
                    dismiss()
                } label: {
                    Image(systemName: task.completed ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                        .foregroundColor(task.completed ? .secondary : .green)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
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

    private var statusCard: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.completed)

                    HStack {
                        Label(task.priority.rawValue, systemImage: task.priority.icon)
                            .font(.caption.bold())
                            .foregroundColor(priorityColor)
                        if task.completed {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if task.isOverdue {
                            Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(task.completed ? Color.green.opacity(0.15) : priorityColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: task.completed ? "checkmark.circle.fill" : task.priority.icon)
                        .font(.system(size: 24))
                        .foregroundColor(task.completed ? .green : priorityColor)
                }
            }
            .padding()
        }
    }

    private var detailsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Details")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                if let due = task.dueDate {
                    DetailRow(icon: "calendar", label: "Due Date", value: formatDate(due))
                }

                if let cat = manager.category(for: task) {
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .frame(width: 20)
                            .foregroundColor(.secondary)
                        Text("Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(cat.name)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: cat.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                            .foregroundColor(Color(hex: cat.colorHex) ?? .blue)
                            .clipShape(Capsule())
                    }
                }

                DetailRow(icon: "clock", label: "Created", value: formatDate(task.createdAt))
            }
            .padding()
        }
    }

    private var descriptionCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                Text(task.description)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
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
                .foregroundColor(.secondary)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
