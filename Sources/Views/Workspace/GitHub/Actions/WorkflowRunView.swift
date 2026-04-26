import SwiftUI

struct WorkflowRunView: View {
    let owner: String
    let repo: String
    let workflowID: Int

    @StateObject private var manager = WorkflowRunManager()

    var body: some View {
        List(manager.runs) { run in
            NavigationLink(destination: WorkflowLogsView(owner: owner, repo: repo, runID: run.id)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(run.name ?? "Run #\(run.runNumber)").font(.headline)
                    Text("Branch: \(run.headBranch)").font(.caption)
                    Text("Status: \(run.status ?? "queued") / \(run.conclusion ?? "-")").font(.caption2)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 4) {
                Text("Success rate: \(Int(manager.analytics.successRate * 100))%")
                Text("Avg duration: \(Int(manager.analytics.averageDurationSeconds))s").font(.caption)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
        }
        .onAppear { manager.startPolling(owner: owner, repo: repo, workflowID: workflowID) }
        .onDisappear { manager.stopPolling() }
        .navigationTitle("Workflow Runs")
    }
}
