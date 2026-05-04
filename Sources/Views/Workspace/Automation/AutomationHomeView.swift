import SwiftUI

struct AutomationHomeView: View {
    @State private var workflows: [WorkspaceWorkflow] = []
    @State private var showingWorkflowBuilder = false

    var body: some View {
        List {
            Section("Your Workflows") {
                if workflows.isEmpty {
                    Text("No active workflows.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(workflows) { workflow in
                        WorkflowRow(workflow: workflow)
                    }
                    .onDelete(perform: deleteWorkflows)
                }
            }

            Section("Available Triggers") {
                Label("Note Created", systemImage: "note.text")
                Label("Task Completed", systemImage: "checkmark.circle.fill")
                Label("GitHub Push", systemImage: "terminal.fill")
            }
        }
        .navigationTitle("Automation")
        .toolbar {
            Button(action: { showingWorkflowBuilder = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingWorkflowBuilder) {
            WorkflowBuilderView { newWorkflow in
                workflows.append(newWorkflow)
                saveWorkflows()
            }
        }
        .onAppear(perform: loadWorkflows)
    }

    private func loadWorkflows() {
        workflows = UnifiedDataStore.shared.loadWorkflows()
    }

    private func saveWorkflows() {
        try? UnifiedDataStore.shared.saveWorkflows(workflows)
    }

    private func deleteWorkflows(at offsets: IndexSet) {
        workflows.remove(atOffsets: offsets)
        saveWorkflows()
    }
}

struct WorkflowRow: View {
    let workflow: WorkspaceWorkflow

    var body: some View {
        HStack {
            Image(systemName: workflow.icon)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading) {
                Text(workflow.title)
                    .font(.headline)
                Text("Trigger: \(workflow.trigger.capability).\(workflow.trigger.action)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if workflow.isEnabled {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct WorkflowBuilderView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (WorkspaceWorkflow) -> Void

    @State private var title = ""
    @State private var triggerCapability = "notes"
    @State private var triggerAction = "created"

    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    TextField("Workflow Title", text: $title)
                }

                Section("Trigger") {
                    Picker("Capability", selection: $triggerCapability) {
                        Text("Notes").tag("notes")
                        Text("Tasks").tag("tasks")
                        Text("GitHub").tag("github")
                    }
                    TextField("Action (e.g. created, completed)", text: $triggerAction)
                }

                Section("Action") {
                    Text("Auto-create task on trigger")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Workflow")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = WorkspaceWorkflow(
                            id: UUID(),
                            title: title,
                            description: "Custom automation",
                            icon: "bolt.fill",
                            trigger: .init(capability: triggerCapability, action: triggerAction),
                            actions: [.init(id: UUID(), type: "create_task", parameters: ["title": "Follow up on \(title)"])],
                            isEnabled: true,
                            createdAt: Date()
                        )
                        onSave(new)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
