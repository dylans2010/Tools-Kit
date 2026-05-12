import Foundation
import FoundationModels

protocol AgenticToolProtocol {
    var definition: WorkspaceAIToolDefinition { get }
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput
}

@MainActor
final class AgenticToolExecutor: ObservableObject {
    static let shared = AgenticToolExecutor()

    private var toolImplementations: [String: AgenticToolProtocol] = [:]
    private let registry = WorkspaceAITools.shared
    private let traceStore = AgenticExecutionTraceStore.shared

    private init() {
        registerImplementations()
    }

    // MARK: - Execution

    func execute(action: AgenticModelAction) async throws -> AgenticToolOutput {
        guard registry.validate(toolName: action.toolName) else {
            let error = AgenticToolExecutionError.unknownTool(action.toolName)
            traceStore.markError(error, context: "Tool validation failed")
            throw error
        }

        guard let implementation = toolImplementations[action.toolName] else {
            let error = AgenticToolExecutionError.noImplementation(action.toolName)
            traceStore.markError(error, context: "No implementation found")
            throw error
        }

        let definition = implementation.definition
        for (key, _) in definition.inputSchema {
            if action.parameters[key] == nil {
                let error = AgenticToolExecutionError.missingParameter(key, action.toolName)
                traceStore.markError(error, context: "Parameter validation")
                throw error
            }
        }

        traceStore.markToolStart(action.toolName, parameters: action.parameters)
        let startTime = Date()

        let output = try await implementation.execute(parameters: action.parameters)

        let elapsed = Date().timeIntervalSince(startTime) * 1000
        traceStore.markToolEnd(action.toolName, output: output, durationMs: elapsed)

        return output
    }

    // MARK: - Registration

    func register(_ tool: AgenticToolProtocol) {
        toolImplementations[tool.definition.name] = tool
    }

    private func registerImplementations() {
        // Task Engine
        register(AgenticToolTaskCreate())
        register(AgenticToolTaskUpdate())
        register(AgenticToolTaskDelete())
        register(AgenticToolTaskList())
        register(AgenticToolTaskSchedule())
        register(AgenticToolTaskPrioritize())
        register(AgenticToolTaskAutoPlan())
        register(AgenticToolTaskDependencyGraph())
        register(AgenticToolTaskCriticalPathAnalyzer())
        register(AgenticToolTaskResourceOptimizer())

        // Notes Engine
        register(AgenticToolNoteCreate())
        register(AgenticToolNoteUpdate())
        register(AgenticToolNoteDelete())
        register(AgenticToolNoteSearch())
        register(AgenticToolNoteSummarize())
        register(AgenticToolNoteExtractInsights())
        register(AgenticToolNoteAutoTag())
        register(AgenticToolNoteGraphLinker())

        // Calendar Engine
        register(AgenticToolCalendarEventCreate())
        register(AgenticToolCalendarEventUpdate())
        register(AgenticToolCalendarEventDelete())
        register(AgenticToolCalendarAvailabilityFinder())
        register(AgenticToolCalendarConflictResolver())
        register(AgenticToolCalendarSmartSchedule())

        // Mail Engine
        register(AgenticToolMailSummarize())
        register(AgenticToolMailDraft())
        register(AgenticToolMailSend())
        register(AgenticToolMailSearch())
        register(AgenticToolMailExtractActions())
        register(AgenticToolMailAutoReply())
        register(AgenticToolMailPriorityClassifier())

        // Slides Engine
        register(AgenticToolSlidesGenerate())
        register(AgenticToolSlidesEdit())
        register(AgenticToolSlidesBuildRenderer())
        register(AgenticToolSlidesThemeSystem())
        register(AgenticToolSlidesExportPDF())
        register(AgenticToolSlidesInsertMedia())
        register(AgenticToolSlidesLayoutOptimizer())

        // Spreadsheet Engine
        register(AgenticToolSheetCreate())
        register(AgenticToolSheetUpdateCell())
        register(AgenticToolSheetFormulaEngine())
        register(AgenticToolSheetAnalyzer())
        register(AgenticToolSheetVisualizationGenerator())
        register(AgenticToolSheetDependencyResolver())

        // Workspace Graph Engine
        register(AgenticToolWorkspaceSearch())
        register(AgenticToolWorkspaceOpenItem())
        register(AgenticToolWorkspaceLinkGraph())
        register(AgenticToolWorkspaceTaggingEngine())
        register(AgenticToolWorkspaceIndexBuilder())
        register(AgenticToolWorkspaceSemanticIndex())

        // AI Transformation Engine
        register(AgenticToolAITextSummarize())
        register(AgenticToolAITextRewrite())
        register(AgenticToolAITextTranslate())
        register(AgenticToolAIIdeaGenerator())
        register(AgenticToolAIClassifier())
        register(AgenticToolAIContentExtractor())
        register(AgenticToolAIStructuredTransformer())

        // Media Engine
        register(AgenticToolMediaImageSearch())
        register(AgenticToolMediaImageAttach())
        register(AgenticToolMediaPromptGenerator())
        register(AgenticToolMediaAutoLayout())
        register(AgenticToolMediaCompositionEngine())

        // Code Generation Engine
        register(AgenticToolCodeSwiftUIViewGenerator())
        register(AgenticToolCodeModelBuilder())
        register(AgenticToolCodeFeatureScaffolder())
        register(AgenticToolCodeArchitectureGenerator())
        register(AgenticToolCodeRefactorEngine())
        register(AgenticToolCodeModuleAssembler())
    }
}

// MARK: - Errors

enum AgenticToolExecutionError: LocalizedError {
    case unknownTool(String)
    case noImplementation(String)
    case missingParameter(String, String)
    case executionFailed(String, Error)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown tool '\(name)' is not in the registry. Only registered tools may be executed."
        case .noImplementation(let name):
            return "Tool '\(name)' is registered but has no implementation."
        case .missingParameter(let param, let tool):
            return "Missing required parameter '\(param)' for tool '\(tool)'."
        case .executionFailed(let tool, let error):
            return "Tool '\(tool)' execution failed: \(error.localizedDescription)"
        }
    }
}
