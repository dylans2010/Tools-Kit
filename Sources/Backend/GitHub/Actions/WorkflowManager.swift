import Foundation

@MainActor
final class WorkflowManager: ObservableObject {
    @Published private(set) var workflows: [GitHubWorkflow] = []
    @Published private(set) var templates: [WorkflowTemplate] = WorkflowManager.defaultTemplates
    @Published var isLoading = false
    @Published var lastError: String?

    private let client: GitHubActionsClient

    init(client: GitHubActionsClient = GitHubActionsClient()) {
        self.client = client
    }

    func refresh(owner: String, repo: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            workflows = try await client.listWorkflows(owner: owner, repo: repo)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
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

    func updateTemplate(_ template: WorkflowTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }

    static let defaultTemplates: [WorkflowTemplate] = [
        WorkflowTemplate(
            id: "ios-build",
            displayName: "iOS Build",
            category: "build",
            description: "Builds the iOS project with xcodebuild.",
            yaml: """
            name: iOS Build
            on: [push, pull_request]
            jobs:
              build:
                runs-on: macos-latest
                steps:
                  - uses: actions/checkout@v4
                  - name: Build
                    run: xcodebuild -project Tools-Kit.xcodeproj -scheme Tools-Kit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
            """,
            version: "1.0.0"
        ),
        WorkflowTemplate(
            id: "ios-tests",
            displayName: "iOS Tests",
            category: "test",
            description: "Runs project tests on iOS simulator.",
            yaml: """
            name: iOS Tests
            on:
              workflow_dispatch:
              pull_request:
            jobs:
              test:
                runs-on: macos-latest
                steps:
                  - uses: actions/checkout@v4
                  - name: Test
                    run: xcodebuild -project Tools-Kit.xcodeproj -scheme Tools-Kit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
            """,
            version: "1.0.0"
        )
    ]
}
