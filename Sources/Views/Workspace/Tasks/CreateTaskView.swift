import SwiftUI

struct CreateTaskView: View {
    @ObservedObject var manager: TasksManager
    @Environment(\.dismiss) private var dismiss

    var editingTask: WorkspaceTask?

    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: WorkspaceTask.TaskPriority = .medium
    @State private var selectedCategoryID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Finish report", text: $title)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(WorkspaceTask.TaskPriority.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: p.icon).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategoryID) {
                        Text("None").tag(UUID?.none)
                        ForEach(manager.categories) { cat in
                            Text(cat.name).tag(Optional(cat.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(editingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingTask == nil ? "Create" : "Save") { save() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let t = editingTask {
                    title = t.title
                    description = t.description
                    hasDueDate = t.dueDate != nil
                    dueDate = t.dueDate ?? Date()
                    priority = t.priority
                    selectedCategoryID = t.categoryID
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var existing = editingTask {
            existing.title = trimmed
            existing.description = description
            existing.dueDate = hasDueDate ? dueDate : nil
            existing.priority = priority
            existing.categoryID = selectedCategoryID
            manager.updateTask(existing)
        } else {
            let task = WorkspaceTask(
                title: trimmed,
                description: description,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                categoryID: selectedCategoryID
            )
            manager.addTask(task)
        }
        dismiss()
    }
}
