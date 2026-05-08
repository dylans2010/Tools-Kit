import SwiftUI

struct CreateTaskView: View {
    var existingTask: WorkspaceTask? = nil
    var onSave: (WorkspaceTask) -> Void

    @StateObject private var manager = TasksManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var hasDueDate = false
    @State private var dueDate: Date = Date()
    @State private var priority: WorkspaceTask.TaskPriority = .medium
    @State private var categoryID: UUID? = nil

    private var isEditing: Bool { existingTask != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Notes (Optional)")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                    }
                } header: {
                    Text("Task Details")
                }

                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(WorkspaceTask.TaskPriority.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: p.icon)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Priority")
                }

                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                } header: {
                    Text("Due Date")
                }

                Section {
                    Picker("Category", selection: $categoryID) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(manager.categories) { cat in
                            Label(cat.name, systemImage: "folder.fill")
                                .tag(Optional(cat.id))
                        }
                    }
                } header: {
                    Text("Category")
                }

                Section {
                    Button(action: save) {
                        Text(isEditing ? "Save Changes" : "Create Task")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let t = existingTask {
                    title = t.title
                    description = t.description
                    priority = t.priority
                    categoryID = t.categoryID
                    if let due = t.dueDate {
                        hasDueDate = true
                        dueDate = due
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var task = existingTask ?? WorkspaceTask(title: trimmed)
        task.title = trimmed
        task.description = description
        task.priority = priority
        task.categoryID = categoryID
        task.dueDate = hasDueDate ? dueDate : nil
        onSave(task)
        dismiss()
    }
}
