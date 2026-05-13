import SwiftUI

struct AutomationHomeView: View {
    @StateObject private var dataStore = UnifiedDataStore.shared
    @State private var showingWorkflowBuilder = false
    @State private var activeWorkflows: [AutomationWorkflow] = []
    @State private var executionLog: [AutomationExecution] = []

    var body: some View {
        List {
            Section {
                if activeWorkflows.isEmpty {
                    ContentUnavailableView(
                        "No Active Workflows",
                        systemImage: "bolt.slash",
                        description: Text("Create a workflow to automate repetitive tasks.")
                    )
                } else {
                    ForEach(activeWorkflows) { workflow in
                        HStack {
                            Label(workflow.name, systemImage: workflow.icon)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { workflow.isEnabled },
                                set: { newValue in
                                    if let idx = activeWorkflows.firstIndex(where: { $0.id == workflow.id }) {
                                        activeWorkflows[idx].isEnabled = newValue
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                    .onDelete { offsets in
                        activeWorkflows.remove(atOffsets: offsets)
                    }
                }
            } header: {
                Label("Active Workflows", systemImage: "bolt")
            }

            Section {
                WorkflowTemplateRow(
                    title: "Auto-task from Email",
                    description: "Create a task when an email is marked as priority.",
                    icon: "envelope.badge.shield.half.filled"
                ) {
                    addWorkflow(name: "Auto-task from Email", icon: "envelope.badge.shield.half.filled")
                }
                WorkflowTemplateRow(
                    title: "Commit to Note",
                    description: "Summarize daily commits into a notebook page.",
                    icon: "terminal.fill"
                ) {
                    addWorkflow(name: "Commit to Note", icon: "terminal.fill")
                }
                WorkflowTemplateRow(
                    title: "Meeting Summary",
                    description: "Generate action items after a call ends.",
                    icon: "video.fill"
                ) {
                    addWorkflow(name: "Meeting Summary", icon: "video.fill")
                }
                WorkflowTemplateRow(
                    title: "Daily Digest",
                    description: "Compile workspace activity into a daily report.",
                    icon: "doc.text.magnifyingglass"
                ) {
                    addWorkflow(name: "Daily Digest", icon: "doc.text.magnifyingglass")
                }
                WorkflowTemplateRow(
                    title: "File Backup",
                    description: "Auto-snapshot workspace files on schedule.",
                    icon: "arrow.clockwise.icloud"
                ) {
                    addWorkflow(name: "File Backup", icon: "arrow.clockwise.icloud")
                }
            } header: {
                Label("Templates", systemImage: "rectangle.grid.2x2")
            }

            if !executionLog.isEmpty {
                Section {
                    ForEach(executionLog) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.workflowName)
                                    .font(.subheadline)
                                Text(entry.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.status)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    entry.status == "Success"
                                        ? Color(.systemGreen).opacity(0.15)
                                        : Color(.systemRed).opacity(0.15),
                                    in: Capsule()
                                )
                                .foregroundStyle(entry.status == "Success" ? .primary : .primary)
                        }
                    }
                } header: {
                    Label("Execution History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .navigationTitle("Automation")
        .toolbar {
            Button { showingWorkflowBuilder = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingWorkflowBuilder) {
            WorkflowBuilderView()
        }
        .onAppear {
            // Execution log is populated from real automation runs.
        }
    }

    private func addWorkflow(name: String, icon: String) {
        let workflow = AutomationWorkflow(name: name, icon: icon, isEnabled: true)
        activeWorkflows.append(workflow)
    }
}

struct AutomationWorkflow: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var isEnabled: Bool
}

struct AutomationExecution: Identifiable {
    let id = UUID()
    let workflowName: String
    let status: String
    let timestamp: Date
}

struct WorkflowTemplateRow: View {
    let title: String
    let description: String
    let icon: String
    var onActivate: (() -> Void)? = nil

    var body: some View {
        Button {
            onActivate?()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
