import Foundation

/// Registry and dispatcher for system tools.
final class AgentSystemTools {
    static let shared = AgentSystemTools()

    private var tools: [String: SystemTool] = [:]

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
        return try await tool.execute(input: input, context: context)
    }

        private func registerTools() {
        register(AbortTaskTool())
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

enum AgentSystemToolsError: Error, LocalizedError {
    case unknownTool(String)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown system tool: \(name)"
        }
    }
}
