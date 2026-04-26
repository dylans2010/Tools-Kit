import Foundation

actor WorkflowGenerator {
    enum GeneratorError: LocalizedError {
        case invalidWorkflowName

        var errorDescription: String? {
            switch self {
            case .invalidWorkflowName:
                return "Workflow name must not be empty."
            }
        }
    }

    private let actionsClient: GitHubActionsClient
    private let julesProvider: JulesProvider
    private let keyManager: APIKeyManager

    init(
        actionsClient: GitHubActionsClient = GitHubActionsClient(),
        julesProvider: JulesProvider = JulesProvider(),
        keyManager: APIKeyManager = .shared
    ) {
        self.actionsClient = actionsClient
        self.julesProvider = julesProvider
        self.keyManager = keyManager
    }

    func generateAndExecute(request: WorkflowGenerationRequest) async throws -> WorkflowGenerationResult {
        let sanitizedName = request.workflowName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedName.isEmpty else { throw GeneratorError.invalidWorkflowName }

        let yaml = try await generateYAML(prompt: request.prompt, workflowName: sanitizedName)
        let filePath = ".github/workflows/\(sanitizedName.replacingOccurrences(of: " ", with: "-").lowercased()).yml"
        let encoded = Data(yaml.utf8).base64EncodedString()

        let existingSHA = try await actionsClient.getContentSHA(owner: request.owner, repo: request.repo, path: filePath, ref: request.branch)
        let commitSHA = try await actionsClient.putFile(
            owner: request.owner,
            repo: request.repo,
            path: filePath,
            message: "Add \(sanitizedName) workflow",
            content: encoded,
            branch: request.branch,
            sha: existingSHA
        )

        var runID: Int?
        if request.triggerImmediately {
            let workflowID = sanitizedName.replacingOccurrences(of: " ", with: "-").lowercased() + ".yml"
            try await actionsClient.dispatchWorkflow(owner: request.owner, repo: request.repo, workflowID: workflowID, ref: request.branch, inputs: nil)
            let runs = try await actionsClient.listRuns(owner: request.owner, repo: request.repo)
            runID = runs.first?.id
        }

        return WorkflowGenerationResult(workflowPath: filePath, commitSHA: commitSHA, runID: runID)
    }

    private func generateYAML(prompt: String, workflowName: String) async throws -> String {
        var base = defaultYAML(for: prompt, workflowName: workflowName)

        if let julesKey = keyManager.getKey(for: "jules"), !julesKey.isEmpty {
            let session = try await julesProvider.createSession(
                prompt: "Generate concise CI strategy for iOS workflow named \(workflowName): \(prompt)",
                source: nil,
                apiKey: julesKey,
                automationMode: "NO_AUTOMATION"
            )
            if let suggestion = session.title, !suggestion.isEmpty {
                base += "\n\n# Jules Context: \(suggestion)"
            }
        }

        return base
    }

    private func defaultYAML(for prompt: String, workflowName: String) -> String {
        let lower = prompt.lowercased()

        if lower.contains("refactor") {
            return """
            name: \(workflowName)
            on:
              workflow_dispatch:
            jobs:
              refactor-check:
                runs-on: macos-latest
                steps:
                  - uses: actions/checkout@v4
                  - name: Swift format validation
                    run: swift format lint --recursive Sources
                  - name: Build verification
                    run: xcodebuild -project Tools-Kit.xcodeproj -scheme Tools-Kit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
            """
        }

        if lower.contains("test") {
            return """
            name: \(workflowName)
            on:
              pull_request:
              workflow_dispatch:
            jobs:
              tests:
                runs-on: macos-latest
                steps:
                  - uses: actions/checkout@v4
                  - name: Run Tests
                    run: xcodebuild -project Tools-Kit.xcodeproj -scheme Tools-Kit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
            """
        }

        return """
        name: \(workflowName)
        on:
          push:
            branches: [main]
          workflow_dispatch:
        jobs:
          build:
            runs-on: macos-latest
            steps:
              - uses: actions/checkout@v4
              - name: Build
                run: xcodebuild -project Tools-Kit.xcodeproj -scheme Tools-Kit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
        """
    }
}
