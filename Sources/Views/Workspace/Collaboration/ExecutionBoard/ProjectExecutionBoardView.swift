import SwiftUI

struct ProjectExecutionBoardView: View {
    @StateObject private var manager = ExecutionBoardManager.shared
    let spaceID: UUID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(BoardColumn.allCases, id: \.self) { column in
                    BoardColumnView(column: column, tasks: (manager.tasksBySpace[spaceID] ?? []).filter { $0.status == column }) { taskID in
                        // Handle task move
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Execution Board")
        .toolbar {
            Button(action: { manager.addTask(spaceID: spaceID, title: "New Task") }) {
                Image(systemName: "plus")
            }
        }
    }
}

struct BoardColumnView: View {
    let column: BoardColumn
    let tasks: [BoardTask]
    let onMove: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(column.rawValue).font(.headline)
                Spacer()
                Text("\(tasks.count)").font(.caption).foregroundColor(.secondary)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        BoardTaskCard(task: task)
                    }
                }
            }
        }
        .frame(width: 280)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BoardTaskCard: View {
    let task: BoardTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title).font(.subheadline).bold()
            if !task.dependencies.isEmpty {
                HStack {
                    Image(systemName: "link")
                    Text("\(task.dependencies.count) deps").font(.caption2)
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}
