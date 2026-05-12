import Foundation

final class AgenticToolExecutor {
    static let shared = AgenticToolExecutor()

    private let tools: [String: any AgenticToolProtocol]

    private init() {
        let availableTools: [any AgenticToolProtocol] = [
            AgenticToolTaskCreate(), AgenticToolTaskUpdate(), AgenticToolTaskDelete(), AgenticToolTaskList(), AgenticToolTaskSchedule(), AgenticToolTaskPrioritize(), AgenticToolTaskAutoPlan(), AgenticToolTaskDependencyGraph(),
            AgenticToolNoteCreate(), AgenticToolNoteSummarize(), AgenticToolNoteUpdate(), AgenticToolNoteDelete(), AgenticToolNoteSearch(), AgenticToolNoteExtractInsights(), AgenticToolNoteAutoTag(), AgenticToolNoteConvertToTask(),
            AgenticToolCalendarEventCreate(), AgenticToolCalendarEventUpdate(), AgenticToolCalendarEventDelete(), AgenticToolCalendarAvailabilityFinder(), AgenticToolCalendarSmartSchedule(),
            AgenticToolMailSummarize(), AgenticToolMailDraft(), AgenticToolMailSend(), AgenticToolMailSearch(), AgenticToolMailExtractActions(), AgenticToolMailAutoReply(),
            AgenticToolSlidesGenerate(), AgenticToolSlidesEdit(), AgenticToolSlidesBuildRenderer(), AgenticToolSlidesThemeSystem(), AgenticToolSlidesExportPDF(), AgenticToolSlidesInsertMedia(),
            AgenticToolSheetCreate(), AgenticToolSheetUpdateCell(), AgenticToolSheetFormulaEngine(), AgenticToolSheetAnalyzer(), AgenticToolSheetVisualizationGenerator(),
            AgenticToolWorkspaceSearch(), AgenticToolWorkspaceOpenItem(), AgenticToolWorkspaceLinkGraph(), AgenticToolWorkspaceTaggingEngine(), AgenticToolWorkspaceIndexBuilder(),
            AgenticToolAITextSummarize(), AgenticToolAITextRewrite(), AgenticToolAITextTranslate(), AgenticToolAIIdeaGenerator(), AgenticToolAIClassifier(), AgenticToolAIContentExtractor(),
            AgenticToolMediaImageSearch(), AgenticToolMediaImageAttach(), AgenticToolMediaPromptGenerator(), AgenticToolMediaAutoLayout(),
            AgenticToolCodeSwiftUIViewGenerator(), AgenticToolCodeModelBuilder(), AgenticToolCodeFeatureScaffolder(), AgenticToolCodeArchitectureGenerator(), AgenticToolCodeRefactorEngine()
        ]
        self.tools = Dictionary(uniqueKeysWithValues: availableTools.map { ($0.toolName, $0) })
    }

    func execute(toolName: String, parameters: [String: String]) async throws -> AgenticToolOutput {
        guard let tool = tools[toolName] else {
            throw NSError(domain: "AgenticToolExecutor", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tool not found: \(toolName)"])
        }
        return try await tool.execute(parameters: parameters)
    }
}
