import Foundation

@MainActor
final class WorkflowManager: ObservableObject {
    @Published private(set) var workflows: [GitHubWorkflow] = []
    @Published private(set) var summaries: [WorkflowSummary] = []
    @Published private(set) var templates: [WorkflowTemplate] = WorkflowManager.defaultTemplates
    @Published var isLoading = false
    @Published var lastError: String?

    private let client: GitHubActionsClient
    private let favoritesKey = "workflow_favorites"

    init(client: GitHubActionsClient = GitHubActionsClient()) {
        self.client = client
    }

    func refresh(owner: String, repo: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await client.listWorkflows(owner: owner, repo: repo)
            let runs = try await client.listRuns(owner: owner, repo: repo)
            let favorites = loadFavorites()
            workflows = fetched
            summaries = fetched.map { workflow in
                let lastRun = runs.first(where: { $0.workflowID == workflow.id })
                return WorkflowSummary(workflow: workflow, lastRun: lastRun, isFavorite: favorites.contains(workflow.id))
            }
            .sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
                return lhs.workflow.name.localizedCaseInsensitiveCompare(rhs.workflow.name) == .orderedAscending
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func toggleFavorite(workflowID: Int) {
        var favorites = loadFavorites()
        if favorites.contains(workflowID) {
            favorites.remove(workflowID)
        } else {
            favorites.insert(workflowID)
        }
        saveFavorites(favorites)
        summaries = summaries.map { summary in
            guard summary.workflow.id == workflowID else { return summary }
            return WorkflowSummary(workflow: summary.workflow, lastRun: summary.lastRun, isFavorite: favorites.contains(workflowID))
        }.sorted { $0.isFavorite && !$1.isFavorite }
    }

    private func loadFavorites() -> Set<Int> {
        let saved = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? []
        return Set(saved)
    }

    private func saveFavorites(_ ids: Set<Int>) {
        UserDefaults.standard.set(Array(ids), forKey: favoritesKey)
    }

    func trigger(workflowID: String, owner: String, repo: String, ref: String, inputs: [String: String] = [:]) async -> Bool {
        do {
            try await client.dispatchWorkflow(owner: owner, repo: repo, workflowID: workflowID, ref: ref, inputs: inputs.isEmpty ? nil : inputs)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func setWorkflowState(workflowID: Int, owner: String, repo: String, enabled: Bool) async -> Bool {
        do {
            try await client.setWorkflowState(owner: owner, repo: repo, workflowID: workflowID, enabled: enabled)
            await refresh(owner: owner, repo: repo)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func loadYAML(owner: String, repo: String, workflowPath: String, ref: String) async throws -> String {
        try await client.getWorkflowYAML(owner: owner, repo: repo, path: workflowPath, ref: ref)
    }

    func updateTemplate(_ template: WorkflowTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }

    static let defaultTemplates: [WorkflowTemplate] = [
        WorkflowTemplate(id: "ios-build", displayName: "iOS Build", category: "build", description: "Builds the iOS project.", yaml: "name: iOS Build", version: "1.0.0"),
        WorkflowTemplate(id: "ios-tests", displayName: "iOS Tests", category: "test", description: "Runs project tests.", yaml: "name: iOS Tests", version: "1.0.0"),
        WorkflowTemplate(id: "ios-deploy", displayName: "iOS Deploy", category: "deploy", description: "Build + archive + deploy lane.", yaml: "name: iOS Deploy", version: "1.0.0"),
        WorkflowTemplate(id: "ios-refactor", displayName: "Refactor Safety", category: "refactor", description: "Lint and compile checks.", yaml: "name: Refactor Safety", version: "1.0.0")
    ]
}
