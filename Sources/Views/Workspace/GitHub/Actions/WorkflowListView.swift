import SwiftUI

struct WorkflowListView: View {
    let owner: String
    let repo: String

    @StateObject private var manager = WorkflowManager()

    var body: some View {
        List(manager.workflows) { workflow in
            NavigationLink(destination: WorkflowDetailView(owner: owner, repo: repo, workflow: workflow)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workflow.name).font(.headline)
                    Text(workflow.path).font(.caption).foregroundStyle(.secondary)
                    Text("State: \(workflow.state)").font(.caption2)
                }
            }
        }
        .overlay {
            if manager.isLoading { ProgressView("Loading Workflows...") }
        }
        .navigationTitle("Actions")
        .task { await manager.refresh(owner: owner, repo: repo) }
        .refreshable { await manager.refresh(owner: owner, repo: repo) }
    }
}
