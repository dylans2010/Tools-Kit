import SwiftUI

struct IntegrationsHomeView: View {
    @StateObject private var dataStore = UnifiedDataStore.shared
    @State private var showingWorkflowBuilder = false

    var body: some View {
        List {
            Section {
                if dataStore.integrationWorkflows.isEmpty {
                    ContentUnavailableView(
                        "No Workflows",
                        systemImage: "square.grid.3x3.topleft.filled",
                        description: Text("Create a workflow to connect your services.")
                    )
                } else {
                    ForEach(dataStore.integrationWorkflows) { workflow in
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workflow.name)
                                        .font(.subheadline.bold())
                                    Text(workflow.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "bolt.circle")
                            }
                            Spacer()
                            Toggle("", isOn: .constant(workflow.isEnabled))
                                .labelsHidden()
                        }
                    }
                }

                Button {
                    showingWorkflowBuilder = true
                } label: {
                    Label("Create New Workflow", systemImage: "plus.circle")
                }
            } header: {
                Label("My Workflows", systemImage: "bolt.horizontal")
            }

            Section {
                ForEach(dataStore.executionHistory) { entry in
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(.subheadline)
                                Text(entry.time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: entry.status == "Success" ? "checkmark.circle" : "xmark.circle")
                        }
                        Spacer()
                        Text(entry.status)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                entry.status == "Success"
                                    ? Color(.systemGreen).opacity(0.1)
                                    : Color(.systemRed).opacity(0.1),
                                in: Capsule()
                            )
                    }
                }
            } header: {
                Label("Execution History", systemImage: "clock.arrow.circlepath")
            }

            Section {
                LabeledContent {
                    Text("\(dataStore.totalExecutions)")
                        .font(.headline)
                } label: {
                    Label("Total Executions", systemImage: "number")
                }
                LabeledContent {
                    Text(String(format: "%.1f%%", dataStore.successRate))
                        .font(.headline)
                } label: {
                    Label("Success Rate", systemImage: "chart.bar")
                }
            } header: {
                Label("Performance Analytics", systemImage: "chart.xyaxis.line")
            }

            Section {
                NavigationLink {
                    IntegrationConnectionsView()
                } label: {
                    Label("Manage Connections", systemImage: "link")
                }
            } header: {
                Label("Connections", systemImage: "cable.connector")
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
            Section {
                Label("GitHub", systemImage: "terminal.fill")
                Label("Slack", systemImage: "message.fill")
                Label("Gmail", systemImage: "envelope.fill")
                Label("Calendar", systemImage: "calendar")
                Label("Jira", systemImage: "checklist")
                Label("Notion", systemImage: "doc.text")
            } header: {
                Label("Available Services", systemImage: "square.grid.3x3")
            }
        }
        .navigationTitle("Connections")
    }
}
