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
            case .inProgress: return "clock"
            case .done: return "checkmark.circle.fill"
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
            ToolbarItem(placement: .primaryAction) {
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
                Label(column.rawValue, systemImage: column.icon)
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 10) {
                    if tasks.isEmpty {
                        Text("No Tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            }

            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let due = task.dueDate {
                Label(shortDate(due), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(task.isOverdue ? .red : .secondary)
            }

            Button {
                manager.toggleComplete(task)
            } label: {
                Label(task.completed ? "Mark Incomplete" : "Mark Done",
                      systemImage: task.completed ? "arrow.uturn.backward" : "checkmark")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
