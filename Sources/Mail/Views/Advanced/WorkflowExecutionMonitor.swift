import SwiftUI

/// View for monitoring the execution status of active workflows.
struct WorkflowExecutionMonitor: View {
    @State private var activeWorkflows: [WorkflowState] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if activeWorkflows.isEmpty {
                Text("No Active Workflows")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeWorkflows) { workflow in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(workflow.name)
                                .font(.headline)
                            Spacer()
                            statusBadge(for: workflow.status)
                        }

                        ProgressView(value: Double(workflow.currentStepIndex), total: Double(workflow.steps.count))
                            .tint(.blue)

                        HStack {
                            Text("Step \(workflow.currentStepIndex + 1) Of \(workflow.steps.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Pause") {
                                Task { try? await WorkflowAutomationEngine.shared.executeNextStep(workflowID: workflow.id) }
                            }
                            .font(.caption.bold())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Workflow Monitor")
        .onAppear(perform: loadWorkflows)
    }

    private func statusBadge(for status: WorkflowState.WorkflowStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: status).opacity(0.2))
            .foregroundStyle(statusColor(for: status))
            .clipShape(Capsule())
    }

    private func statusColor(for status: WorkflowState.WorkflowStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .active: return .blue
        case .completed: return .green
        case .failed: return .red
        case .paused: return .orange
        }
    }

    private func loadWorkflows() {
        isLoading = true
        Task {
            activeWorkflows = await WorkflowAutomationEngine.shared.getAllWorkflows()
            isLoading = false
        }
    }
}
