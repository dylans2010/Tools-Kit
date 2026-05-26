import SwiftUI

struct NotebookTaskConsolidationView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var tasks: [NotebookTask] = []

    struct NotebookTask: Identifiable {
        let id = UUID()
        let pageID: UUID
        let pageTitle: String
        let content: String
        var isCompleted: Bool
    }

    var body: some View {
        List {
            Section("Global Tasks") {
                if tasks.isEmpty {
                    ContentUnavailableView("No Tasks Found", systemImage: "checklist", description: Text("Tasks extracted from all your notebook pages will appear here."))
                } else {
                    ForEach(tasks) { task in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? .green : .secondary)
                                .onTapGesture { toggleTask(task) }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.content)
                                    .strikethrough(task.isCompleted)
                                Text(task.pageTitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Task Consolidation")
        .onAppear(perform: scanForTasks)
    }

    private func scanForTasks() {
        var foundTasks: [NotebookTask] = []

        for notebook in manager.notebooks {
            for folder in notebook.folders {
                for page in folder.pages {
                    let lines = page.content.components(separatedBy: "\n")
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasPrefix("- [ ] ") {
                            foundTasks.append(NotebookTask(pageID: page.id, pageTitle: page.title, content: String(trimmed.dropFirst(6)), isCompleted: false))
                        } else if trimmed.hasPrefix("- [x] ") {
                            foundTasks.append(NotebookTask(pageID: page.id, pageTitle: page.title, content: String(trimmed.dropFirst(6)), isCompleted: true))
                        }
                    }
                }
            }
        }
        tasks = foundTasks
    }

    private func toggleTask(_ task: NotebookTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()

            // Find the page and update its content
            for notebook in manager.notebooks {
                for folder in notebook.folders {
                    if let pageIndex = folder.pages.firstIndex(where: { $0.id == task.pageID }) {
                        var page = folder.pages[pageIndex]
                        let oldTag = task.isCompleted ? "- [ ] " : "- [x] "
                        let newTag = task.isCompleted ? "- [x] " : "- [ ] "
                        page.content = page.content.replacingOccurrences(of: oldTag + task.content, with: newTag + task.content)
                        page.updatedAt = Date()
                        manager.updatePage(page, in: folder.id, notebookID: notebook.id)
                        return
                    }
                }
            }
        }
    }
}
