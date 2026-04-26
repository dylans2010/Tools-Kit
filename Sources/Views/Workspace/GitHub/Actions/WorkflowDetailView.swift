import SwiftUI

struct WorkflowDetailView: View {
    let owner: String
    let repo: String
    let workflow: GitHubWorkflow

    @State private var showRunSheet = false

    var body: some View {
        Form {
            Section("Workflow") {
                Text(workflow.name)
                Text(workflow.path).font(.caption)
                Text("Created: \(workflow.createdAt.formatted())")
                Text("Updated: \(workflow.updatedAt.formatted())")
            }

            Section("Execution") {
                Button("Run Workflow") { showRunSheet = true }
                NavigationLink("View Runs") {
                    WorkflowRunView(owner: owner, repo: repo, workflowID: workflow.id)
                }
            }
        }
        .navigationTitle(workflow.name)
        .sheet(isPresented: $showRunSheet) {
            RunWorkflowView(owner: owner, repo: repo, workflowID: "\(workflow.id)")
        }
    }
}
