import SwiftUI

struct AutomationHomeView: View {
    @StateObject private var engine = AutomationEngine.shared

    var body: some View {
        List {
            Section("Active Workflows") {
                if engine.workflows.isEmpty {
                    Text("No workflows configured").foregroundColor(.secondary)
                }
                ForEach(engine.workflows) { workflow in
                    NavigationLink(destination: WorkflowExecutionView(workflow: workflow)) {
                        Text(workflow.name)
                    }
                }
            }

            Section("Creation") {
                NavigationLink(destination: WorkflowBuilderView()) {
                    Label("Build New Workflow", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Automation")
    }
}
