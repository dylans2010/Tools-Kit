import SwiftUI

struct WorkflowExecutionView: View {
    let workflow: Workflow
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 20) {
            Text(workflow.name).font(.title)

            if isRunning {
                ProgressView("Running Workflow...")
            }

            Button("Execute Now") {
                Task {
                    isRunning = true
                    await AutomationEngine.shared.execute(workflow: workflow)
                    isRunning = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
        }
        .navigationTitle("Execute")
    }
}
