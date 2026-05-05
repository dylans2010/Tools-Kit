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

            Section("Execution History") {
                HistoryRow(name: "Daily Sync", status: "Success", time: "2h ago")
                HistoryRow(name: "Slack Notify", status: "Failed", time: "5h ago")
                HistoryRow(name: "GitHub Issue Creator", status: "Success", time: "1d ago")
            }

            Section("Performance Analytics") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Executions").font(.caption).foregroundColor(.secondary)
                        Text("1,248").font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Success Rate").font(.caption).foregroundColor(.secondary)
                        Text("99.2%").font(.headline).foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
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

struct HistoryRow: View {
    let name: String
    let status: String
    let time: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.subheadline)
                Text(time).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(status)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(status == "Success" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .foregroundColor(status == "Success" ? .green : .red)
                .cornerRadius(4)
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
