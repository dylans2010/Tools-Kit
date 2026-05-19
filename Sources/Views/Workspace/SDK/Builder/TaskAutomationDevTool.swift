import SwiftUI

struct TaskAutomationDevTool: DevTool {
    let id = "task-automation"
    let name = "Task Automation"
    let category = DevToolCategory.automation
    let icon = "bolt.shield.fill"
    let description = "Configure and trigger SDK workflows"

    func render() -> some View {
        TaskAutomationView()
    }
}

struct TaskAutomationView: View {
    @StateObject private var viewModel = TaskAutomationViewModel()

    var body: some View {
        List {
            Section("Operational Health") {
                HStack(spacing: 20) {
                    AutoMetric(label: "Success Rate", value: "99.2%", color: .green)
                    AutoMetric(label: "Scheduled", value: "\(viewModel.workflows.filter(\.isEnabled).count)", color: .blue)
                    AutoMetric(label: "Avg. Runtime", value: "1.2s", color: .orange)
                }
                .padding(.vertical, 8)
            }

            Section("Active Workflows") {
                if viewModel.workflows.isEmpty {
                    ContentUnavailableView("No Workflows", systemImage: "bolt.slash", description: Text("Automated SDK tasks will appear here."))
                } else {
                    ForEach($viewModel.workflows) { $wf in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: wf.icon)
                                    .foregroundStyle(wf.isEnabled ? .blue : .secondary)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wf.name).font(.subheadline.bold())
                                    Text(wf.trigger).font(.system(size: 9)).foregroundStyle(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $wf.isEnabled).labelsHidden()
                                    .controlSize(.small)
                            }

                            if wf.isEnabled {
                                ProgressView(value: 0.7)
                                    .tint(.blue)
                                    .controlSize(.small)

                                HStack {
                                    Text("Next run: 2h 14m").font(.system(size: 8)).foregroundStyle(.tertiary)
                                    Spacer()
                                    Button("Run Now") { viewModel.trigger(wf) }
                                        .font(.system(size: 8, weight: .bold))
                                        .buttonStyle(.bordered)
                                        .controlSize(.mini)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Global Controls") {
                Button { } label: {
                    Label("Force System Health Check", systemImage: "heart.text.square")
                }

                Button(role: .destructive) { } label: {
                    Label("Emergency Stop All Tasks", systemImage: "stop.circle.fill")
                }
            }
        }
        .navigationTitle("Automation")
    }
}

struct AutoMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.headline.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct WorkflowItem: Identifiable {
    let id = UUID()
    let name: String
    let trigger: String
    let icon: String
    var isEnabled: Bool
}

class TaskAutomationViewModel: ObservableObject {
    @Published var workflows: [WorkflowItem] = [
        WorkflowItem(name: "State Persistence", trigger: "Every 5 minutes", icon: "arrow.clockwise.circle.fill", isEnabled: true),
        WorkflowItem(name: "Cloud Sync", trigger: "On network available", icon: "cloud.fill", isEnabled: true),
        WorkflowItem(name: "Metric Aggregator", trigger: "Hourly", icon: "chart.bar.fill", isEnabled: false),
        WorkflowItem(name: "Cache Pruning", trigger: "Daily at 03:00", icon: "trash.fill", isEnabled: true)
    ]

    func trigger(_ wf: WorkflowItem) {
        // Simulation
    }
}

#Preview {
    TaskAutomationView()
}
