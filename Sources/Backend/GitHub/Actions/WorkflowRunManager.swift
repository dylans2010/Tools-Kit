import Foundation

@MainActor
final class WorkflowRunManager: ObservableObject {
    @Published private(set) var runs: [GitHubWorkflowRun] = []
    @Published private(set) var analytics = WorkflowAnalytics(totalRuns: 0, successfulRuns: 0, failedRuns: 0, successRate: 0, averageDurationSeconds: 0)
    @Published private(set) var polling = false
    @Published private(set) var jobsByRunID: [Int: [WorkflowJob]] = [:]
    @Published var lastError: String?

    private let client: GitHubActionsClient
    private var pollingTask: Task<Void, Never>?

    init(client: GitHubActionsClient = GitHubActionsClient()) {
        self.client = client
    }

    func fetchRuns(owner: String, repo: String, workflowID: Int? = nil) async {
        do {
            let fetched = try await client.listRuns(owner: owner, repo: repo, workflowID: workflowID)
            runs = fetched
            analytics = buildAnalytics(from: fetched)
            lastError = nil
        } catch {
            runs = []
            lastError = error.localizedDescription
        }
    }

    func loadJobs(owner: String, repo: String, runID: Int) async {
        do {
            jobsByRunID[runID] = try await client.listJobs(owner: owner, repo: repo, runID: runID)
            lastError = nil
        } catch {
            jobsByRunID[runID] = []
            lastError = error.localizedDescription
        }
    }

    func rerun(owner: String, repo: String, runID: Int, workflowID: Int?) async {
        do {
            try await client.rerun(runID: runID, owner: owner, repo: repo)
            await fetchRuns(owner: owner, repo: repo, workflowID: workflowID)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func cancel(owner: String, repo: String, runID: Int, workflowID: Int?) async {
        do {
            try await client.cancel(runID: runID, owner: owner, repo: repo)
            await fetchRuns(owner: owner, repo: repo, workflowID: workflowID)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func startPolling(owner: String, repo: String, workflowID: Int? = nil, intervalSeconds: TimeInterval = 8) {
        stopPolling()
        polling = true
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchRuns(owner: owner, repo: repo, workflowID: workflowID)
                try? await Task.sleep(for: .seconds(intervalSeconds))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        polling = false
    }

    private func buildAnalytics(from runs: [GitHubWorkflowRun]) -> WorkflowAnalytics {
        let total = runs.count
        let successful = runs.filter { $0.conclusion == "success" }.count
        let failed = runs.filter { $0.conclusion == "failure" }.count
        let durationSamples: [TimeInterval] = runs.compactMap {
            $0.updatedAt.timeIntervalSince($0.createdAt) > 0 ? $0.updatedAt.timeIntervalSince($0.createdAt) : nil
        }
        let average = durationSamples.isEmpty ? 0 : durationSamples.reduce(0, +) / Double(durationSamples.count)
        let rate = total == 0 ? 0 : Double(successful) / Double(total)

        return WorkflowAnalytics(
            totalRuns: total,
            successfulRuns: successful,
            failedRuns: failed,
            successRate: rate,
            averageDurationSeconds: average
        )
    }
}
