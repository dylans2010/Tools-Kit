import SwiftUI

struct IntegrationsHomeView: View {
    @StateObject private var dataStore = UnifiedDataStore.shared
    @State private var showingWorkflowBuilder = false

    var body: some View {
        List {
            Section("My Workflows") {
                if dataStore.integrationWorkflows.isEmpty {
                    Text("No workflows created yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(dataStore.integrationWorkflows) { workflow in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workflow.name)
                                    .font(.subheadline.bold())
                                Text(workflow.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(workflow.isEnabled))
                                .labelsHidden()
                        }
                    }
                }

                Button("Create New Workflow") {
                    showingWorkflowBuilder = true
                }
            }

            Section("Connections") {
                NavigationLink("Manage Connections") {
                    IntegrationConnectionsView()
                }
            }
        }
        .navigationTitle("Integrations")
        .sheet(isPresented: $showingWorkflowBuilder) {
            WorkflowBuilderView()
        }
    }
}

struct IntegrationConnectionsView: View {
    var body: some View {
        List {
            Label("GitHub", systemImage: "terminal.fill")
            Label("Slack", systemImage: "message.fill")
            Label("Gmail", systemImage: "envelope.fill")
            Label("Calendar", systemImage: "calendar")
        }
        .navigationTitle("Connections")
    }
}
