import SwiftUI

struct TaskBoardView: View {
    @ObservedObject var manager: TasksManager
    @State private var showingCreate = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(WorkspaceTask.BoardStatus.allCases, id: \.self) { status in
                    BoardColumn(status: status, manager: manager)
                }
            }
            .padding()
        }
        .navigationTitle("Board")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingCreate) { CreateTaskView(manager: manager) }
    }
}

private struct BoardColumn: View {
    let status: WorkspaceTask.BoardStatus
    @ObservedObject var manager: TasksManager

    private var tasks: [WorkspaceTask] {
        manager.tasks.filter { $0.boardStatus == status && !($0.completed && status != .done) }
    }

    private var columnColor: Color {
        switch status {
        case .todo: return .blue
        case .inProgress: return .orange
        case .done: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(status.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(columnColor.opacity(0.15))
                    .foregroundColor(columnColor)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)

            ForEach(tasks) { task in
                BoardCard(task: task, manager: manager)
            }

            if tasks.isEmpty {
                Text("No tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .frame(width: 250)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct BoardCard: View {
    let task: WorkspaceTask
    @ObservedObject var manager: TasksManager

    private var priorityColor: Color { Color(hex: task.priority.color) ?? .blue }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.subheadline.bold())
                .lineLimit(2)
                .strikethrough(task.completed)

            HStack {
                Label(task.priority.rawValue, systemImage: task.priority.icon)
                    .font(.caption)
                    .foregroundColor(priorityColor)
                Spacer()
                Menu {
                    ForEach(WorkspaceTask.BoardStatus.allCases, id: \.self) { status in
                        Button(status.rawValue) { manager.moveTask(task, to: status) }
                    }
                } label: {
                    Image(systemName: "arrow.right.circle").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 8)
    }
}
