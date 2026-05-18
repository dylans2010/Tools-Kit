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
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Task Automation",
                description: "Design automated workflows and define triggers for repetitive SDK maintenance tasks.",
                icon: "bolt.shield.fill"
            )
            .padding()

            List {
                Section("Active Workflows") {
                    ForEach($viewModel.workflows) { $wf in
                        HStack {
                            Image(systemName: wf.icon)
                                .foregroundStyle(wf.isEnabled ? .green : .secondary)
                            VStack(alignment: .leading) {
                                Text(wf.name).font(.subheadline.bold())
                                Text(wf.trigger).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $wf.isEnabled).labelsHidden()
                        }
                    }
                }

                Section("Quick Actions") {
                    Button("Trigger Health Check") { }
                    Button("Trigger Cache Purge") { }
                }
            }
        }
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
        WorkflowItem(name: "Nightly Sync", trigger: "02:00 AM Daily", icon: "moon.fill", isEnabled: true),
        WorkflowItem(name: "Critical Error Alert", trigger: "On Error Event", icon: "exclamationmark.triangle.fill", isEnabled: true)
    ]
}
