import SwiftUI

struct WorkflowRunView: View {
    let owner: String
    let repo: String
    let workflowID: Int

    @StateObject private var manager = WorkflowRunManager()
    @State private var expandedRuns = Set<Int>()

    var body: some View {
        List {
            if let error = manager.lastError {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
            ForEach(manager.runs) { run in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink(destination: WorkflowLogsView(owner: owner, repo: repo, runID: run.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(run.name ?? "Run #\(run.runNumber)").font(.headline)
                            Text("Branch: \(run.headBranch)").font(.caption)
                            Text("Status: \(run.status ?? "queued") / \(run.conclusion ?? "-")").font(.caption2)
                            Text("Timeline: \(run.createdAt.formatted()) → \(run.updatedAt.formatted())").font(.caption2)
                        }
                    }
                    HStack {
                        Button("Load Jobs") {
                            Task { await manager.loadJobs(owner: owner, repo: repo, runID: run.id) }
                        }
                        .buttonStyle(.bordered)
                        Button("Re-run") {
                            Task { await manager.rerun(owner: owner, repo: repo, runID: run.id, workflowID: workflowID) }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Cancel") {
                            Task { await manager.cancel(owner: owner, repo: repo, runID: run.id, workflowID: workflowID) }
                        }
                        .buttonStyle(.bordered)
                    }
                    if expandedRuns.contains(run.id), let jobs = manager.jobsByRunID[run.id], !jobs.isEmpty {
                        ForEach(jobs) { job in
                            Text("• \(job.name): \(job.status ?? "-") / \(job.conclusion ?? "-")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button(expandedRuns.contains(run.id) ? "Hide Jobs" : "Show Jobs") {
                        if expandedRuns.contains(run.id) {
                            expandedRuns.remove(run.id)
                        } else {
                            expandedRuns.insert(run.id)
                        }
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 4) {
                Text("Success rate: \(Int(manager.analytics.successRate * 100))%")
                Text("Avg duration: \(Int(manager.analytics.averageDurationSeconds))s").font(.caption)
                Text(manager.polling ? "Live updates enabled" : "Live updates paused").font(.caption2)
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
