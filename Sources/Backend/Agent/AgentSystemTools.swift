import Foundation

/// Registry and dispatcher for system tools.
final class AgentSystemTools {
    static let shared = AgentSystemTools()

    internal var tools: [String: SystemTool] = [:]

    private init() {
        registerTools()
    }

    /// Registers a tool in the registry.
    func register(_ tool: SystemTool) {
        tools[tool.name] = tool
    }

    /// Validates if a tool exists.
    func exists(_ name: String) -> Bool {
        return tools[name] != nil
    }

    /// Executes a tool by name.
    func execute(name: String, input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        guard let tool = tools[name] else {
            throw AgentSystemToolsError.unknownTool(name)
        }

        // Enforcement Rule: Audit validation
        if name != "audit_tools" {
            let auditResponse = try await execute(name: "audit_tools", input: [:], context: context)
            if let status = auditResponse.output["audit_status"]?.value as? String, status == "failed" {
                let fileName = name + ".swift"
                let mockTools = auditResponse.output["mock_tools_detected"]?.value as? [String] ?? []
                let registryMismatches = auditResponse.output["registry_mismatches"]?.value as? [String] ?? []
                let nonFunctional = auditResponse.output["non_functional_tools"]?.value as? [String] ?? []

                if mockTools.contains(fileName) || registryMismatches.contains(fileName) || nonFunctional.contains(fileName) {
                    throw AgentSystemToolsError.toolFailedAudit(name)
                }
            }
        }

        return try await tool.execute(input: input, context: context)
    }

    func listAvailableTools() -> [String] {
        Array(tools.keys).sorted()
    }

    func systemPrompt() -> String {
        let toolList = listAvailableTools().map { "- \($0)" }.joined(separator: "\n")
        return """
        You are Jules, a repository automation agent.
        Follow these rules on every task:
        1. Understand the request, then pick the minimum required tools.
        2. Prefer read_file, list_files, and search_repo to gather context before modifying code.
        3. Use write/edit tools (write_file, append_file, apply_patch, refactor_code, rename_symbol, extract_function, inline_function, move_file, delete_file) only after confirming target files.
        4. Run verification tools (lint_code, run_tests, build_project, schema_validation, complexity_analysis, analyze_errors) before finishing.
        5. Use git tools (branch_create, branch_switch, get_git_diff, commit_changes, merge_branch, revert_commit) to keep changes traceable.
        6. If a tool returns structured output, base your next step on that output instead of assumptions.
        7. If a tool fails, inspect error fields and choose a safe retry or fallback tool.
        8. Never invent file contents. Always read and return actual content from tools.

        Available tools:
        \(toolList)

        Supported coding languages include Swift, Objective-C, C/C++, Java/Kotlin, JavaScript/TypeScript, Python, JSON, YAML, and Markdown.
        """
    }

    private func registerTools() {
        register(AbortTaskTool())
        register(AuditToolsTool())
        register(AnalyzeErrorsTool())
        register(ApiContractScanTool())
        register(AppendFileTool())
        register(ApplyPatchTool())
        register(ArchitectureReviewTool())
        register(BranchCreateTool())
        register(BranchSwitchTool())
        register(BuildProjectTool())
        register(ClearMemoryTool())
        register(CodeCleanupTool())
        register(CodeExplainTool())
        register(CommitChangesTool())
        register(ComplexityAnalysisTool())
        register(CreateCheckpointTool())
        register(DebugSessionTool())
        register(DeleteFileTool())
        register(DependencyGraphTool())
        register(EmitStatusTool())
        register(EventReplayTool())
        register(ExecuteScriptTool())
        register(ExecutionTraceExportTool())
        register(ExtractFunctionTool())
        register(FormatCodeTool())
        register(GenerateDiffTool())
        register(GetGitDiffTool())
        register(InlineFunctionTool())
        register(KillProcessTool())
        register(LintCodeTool())
        register(ListFilesTool())
        register(LoadMemoryTool())
        register(LogEventTool())
        register(MergeBranchTool())
        register(MigrationAnalyzerTool())
        register(MoveFileTool())
        register(PauseExecutionTool())
        register(PerformanceProfileTool())
        register(ProfileRuntimeTool())
        register(PublishWorkspaceStateTool())
        register(ReadFileTool())
        register(RefactorCodeTool())
        register(RenameSymbolTool())
        register(RenderDiffStateTool())
        register(RequestUserInputTool())
        register(RestoreCheckpointTool())
        register(ResumeExecutionTool())
        register(RevertCommitTool())
        register(RunCommandTool())
        register(RunTestsTool())
        register(SaveMemoryTool())
        register(SchemaValidationTool())
        register(SearchRepoTool())
        register(SecurityScanTool())
        register(SimulateRunTool())
        register(StreamExecutionTool())
        register(SummarizeMemoryTool())
        register(ToolDiscoveryTool())
        register(ToolHealthCheckTool())
        register(UiRefreshTool())
        register(UpdateMemoryTool())
        register(UpdateTimelineTool())
        register(WorkspaceSnapshotTool())
        register(WriteFileTool())
    }
}

enum AgentSystemToolsError: Error, LocalizedError, Sendable {
    case unknownTool(String)
    case toolFailedAudit(String)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown system tool: \(name)"
        case .toolFailedAudit(let name):
            return "Tool '\(name)' failed audit enforcement and is blocked from execution."
        }
    }
}
