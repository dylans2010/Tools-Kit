import SwiftUI

struct ProjectTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ProjectsManager.shared

    let projectID: UUID
    let task: ProjectTask?

    @State private var title: String
    @State private var description: String
    @State private var status: TaskStatus
    @State private var priority: ProjectTask.TaskPriority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var assignedTo: String
    @State private var tagInput: String = ""
    @State private var tags: [String]

    init(projectID: UUID, task: ProjectTask?) {
        self.projectID = projectID
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _description = State(initialValue: task?.description ?? "")
        _status = State(initialValue: task?.status ?? .todo)
        _priority = State(initialValue: task?.priority ?? .medium)
        _dueDate = State(initialValue: task?.dueDate)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _assignedTo = State(initialValue: task?.assignedTo ?? "")
        _tags = State(initialValue: task?.tags ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Status & Priority") {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Priority", selection: $priority) {
                        ForEach(ProjectTask.TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: .date)
                    }
                }

                Section("Assignment") {
                    TextField("Assigned To", text: $assignedTo)
                }

                Section("Tags") {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                    }
                    .onDelete { indexSet in
                        tags.remove(atOffsets: indexSet)
                    }
                    HStack {
                        TextField("Add tag...", text: $tagInput)
                        Button("Add") {
                            let t = tagInput.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            tags.append(t)
                            tagInput = ""
                        }
                        .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(task == nil ? "Add" : "Save") {
                        saveTask()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        if let existing = task {
            var updated = existing
            updated.title = title
            updated.description = description
            updated.status = status
            updated.priority = priority
            updated.dueDate = hasDueDate ? dueDate : nil
            updated.assignedTo = assignedTo
            updated.tags = tags
            manager.updateTask(updated, in: projectID)
        } else {
            let newTask = ProjectTask(
                title: title,
                description: description,
                status: status,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                assignedTo: assignedTo,
                tags: tags
            )
            manager.addTask(to: projectID, task: newTask)
        }
    }
}
