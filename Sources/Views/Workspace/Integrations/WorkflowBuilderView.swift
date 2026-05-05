import SwiftUI

struct WorkflowBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataStore = UnifiedDataStore.shared

    @State private var name = ""
    @State private var description = ""
    @State private var triggerSource = "note.created"
    @State private var actionDestination = "slack"

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Workflow Name", text: $name)
                    TextField("Description", text: $description)
                }

                Section("Trigger") {
                    Picker("When this happens", selection: $triggerSource) {
                        Text("Note Created").tag("note.created")
                        Text("Task Completed").tag("task.completed")
                        Text("File Uploaded").tag("file.uploaded")
                    }
                }

                Section("Action") {
                    Picker("Do this", selection: $actionDestination) {
                        Text("Post to Slack").tag("slack")
                        Text("Send Email").tag("gmail")
                        Text("Create GitHub Issue").tag("github.issue")
                    }
                }
            }
            .navigationTitle("New Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkflow()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveWorkflow() {
        let trigger = IntegrationTrigger(type: .internalApp, source: triggerSource)
        let action = IntegrationAction(type: .external, destination: actionDestination)

        let workflow = IntegrationWorkflow(
            name: name,
            description: description,
            trigger: trigger,
            actions: [action]
        )

        try? dataStore.saveIntegrationWorkflow(workflow)
        dismiss()
    }
}
