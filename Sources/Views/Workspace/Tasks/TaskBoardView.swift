import SwiftUI

struct TaskBoardView: View {
    @StateObject private var manager = TasksManager.shared
    @State private var showingCreate = false

    enum BoardColumn: String, CaseIterable {
        case todo = "To Do"
        case inProgress = "In Progress"
        case done = "Done"

        var icon: String {
            switch self {
            case .todo: return "circle"
            case .inProgress: return "clock.fill"
            case .done: return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .todo: return .blue
            case .inProgress: return .orange
            case .done: return .green
            }
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(BoardColumn.allCases, id: \.self) { column in
                    BoardColumnView(column: column, tasks: tasks(for: column), manager: manager)
                        .frame(width: 280)
                }
            }
            .padding()
        }
        .navigationTitle("Board")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateTaskView { task in
                manager.addTask(task)
            }
        }
    }

    private func tasks(for column: BoardColumn) -> [WorkspaceTask] {
        switch column {
        case .todo:
            return manager.tasks.filter { !$0.completed && !$0.isOverdue }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .inProgress:
            return manager.tasks.filter { !$0.completed && $0.isOverdue }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .done:
            return manager.completedTasks
        }
    }
}

struct BoardColumnView: View {
    let column: TaskBoardView.BoardColumn
    let tasks: [WorkspaceTask]
    @ObservedObject var manager: TasksManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: column.icon)
                    .foregroundColor(column.color)
                Text(column.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(column.color.opacity(0.15))
                    .foregroundColor(column.color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 10) {
                    if tasks.isEmpty {
                        Text("No Tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(tasks) { task in
                            BoardTaskCard(task: task, manager: manager)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.top, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct BoardTaskCard: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.subheadline.bold())
                    .strikethrough(task.completed)
                Spacer()
                Image(systemName: task.priority.icon)
                    .font(.caption)
                    .foregroundColor(Color(hex: task.priority.color) ?? .blue)
            }

            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let due = task.dueDate {
                Label(shortDate(due), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(task.isOverdue ? .red : .secondary)
            }

            Button {
                manager.toggleComplete(task)
            } label: {
                Label(task.completed ? "Mark Incomplete" : "Mark Done",
                      systemImage: task.completed ? "arrow.uturn.backward" : "checkmark")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(task.completed ? Color(.tertiarySystemBackground) : Color.green.opacity(0.15))
                    .foregroundColor(task.completed ? .secondary : .green)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
