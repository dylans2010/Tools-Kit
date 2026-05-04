import SwiftUI

struct AutomationHomeView: View {
    @StateObject private var engine = WorkflowEngine.shared
    @State private var showingCreateWorkflow = false

    var body: some View {
        List {
            Section("Workflows") {
                if engine.workflows.isEmpty {
                    Text("No workflows created.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(engine.workflows) { workflow in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(workflow.name)
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { workflow.isEnabled },
                                    set: { _ in /* toggle logic in engine */ }
                                )).labelsHidden()
                            }
                            Text(workflow.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let lastRun = workflow.lastRunAt {
                                Text("Last run: \(lastRun, style: .relative) ago")
                                    .font(.caption2)
                                    .foregroundColor(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Execution Monitor") {
                if engine.activeRuns.isEmpty {
                    Text("No recent runs.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(engine.activeRuns) { run in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(engine.workflows.first(where: { $0.id == run.workflowID })?.name ?? "Unknown")
                                    .font(.subheadline.bold())
                                Text(run.status.rawValue.uppercased())
                                    .font(.caption2.bold())
                                    .foregroundColor(colorForStatus(run.status))
                            }
                            Spacer()
                            Text(run.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Automation Hub")
        .toolbar {
            Button(action: { showingCreateWorkflow = true }) {
                Image(systemName: "plus")
            }
        }
    }

    private func colorForStatus(_ s: WorkflowRun.RunStatus) -> Color {
        switch s {
        case .success: return .green
        case .failure: return .red
        case .running: return .blue
        }
    }
}
