import Foundation

struct WorkspaceAIToolDefinition {
    let name: String
    let description: String
    let category: String
    let inputSchema: [String: String]
    let producesCode: Bool
}

struct WorkspaceAITools {
    static let registry: [WorkspaceAIToolDefinition] = [
        WorkspaceAIToolDefinition(name: "AgenticToolTaskCreate", description: "Creates a task", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskUpdate", description: "Updates a task", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskDelete", description: "Deletes a task", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskList", description: "Lists tasks", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskSchedule", description: "Schedules a task", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskPrioritize", description: "Prioritizes tasks", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskAutoPlan", description: "Auto plans tasks", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolTaskDependencyGraph", description: "Generates dependency graph", category: "TASK", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteCreate", description: "Creates a note", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteSummarize", description: "Summarizes a note", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteUpdate", description: "Updates a note", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteDelete", description: "Deletes a note", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteSearch", description: "Searches notes", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteExtractInsights", description: "Extracts insights from note", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteAutoTag", description: "Auto tags notes", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolNoteConvertToTask", description: "Converts note to task", category: "NOTE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolCalendarEventCreate", description: "Creates event", category: "CALENDAR", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolCalendarEventUpdate", description: "Updates event", category: "CALENDAR", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolCalendarEventDelete", description: "Deletes event", category: "CALENDAR", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolCalendarAvailabilityFinder", description: "Finds availability", category: "CALENDAR", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolCalendarSmartSchedule", description: "Smart schedules events", category: "CALENDAR", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMailSummarize", description: "Summarizes mail", category: "MAIL", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMailDraft", description: "Drafts mail", category: "MAIL", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMailSend", description: "Sends mail", category: "MAIL", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMailSearch", description: "Searches mail", category: "MAIL", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMailExtractActions", description: "Extracts actions from mail", category: "MAIL", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMailAutoReply", description: "Auto replies to mail", category: "MAIL", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolSlidesGenerate", description: "Generates slides", category: "SLIDES", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSlidesEdit", description: "Edits slides", category: "SLIDES", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSlidesBuildRenderer", description: "Builds slide renderer", category: "SLIDES", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSlidesThemeSystem", description: "Slides theme system", category: "SLIDES", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSlidesExportPDF", description: "Exports slides to PDF", category: "SLIDES", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolSlidesInsertMedia", description: "Inserts media to slides", category: "SLIDES", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSheetCreate", description: "Creates sheet", category: "SHEET", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSheetUpdateCell", description: "Updates sheet cell", category: "SHEET", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSheetFormulaEngine", description: "Sheet formula engine", category: "SHEET", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolSheetAnalyzer", description: "Analyzes sheet", category: "SHEET", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolSheetVisualizationGenerator", description: "Generates sheet visualization", category: "SHEET", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolWorkspaceSearch", description: "Searches workspace", category: "WORKSPACE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolWorkspaceOpenItem", description: "Opens workspace item", category: "WORKSPACE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolWorkspaceLinkGraph", description: "Workspace link graph", category: "WORKSPACE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolWorkspaceTaggingEngine", description: "Workspace tagging engine", category: "WORKSPACE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolWorkspaceIndexBuilder", description: "Workspace index builder", category: "WORKSPACE", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolAITextSummarize", description: "Summarizes text", category: "AI", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolAITextRewrite", description: "Rewrites text", category: "AI", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolAITextTranslate", description: "Translates text", category: "AI", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolAIIdeaGenerator", description: "Generates ideas", category: "AI", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolAIClassifier", description: "Classifies content", category: "AI", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolAIContentExtractor", description: "Extracts content", category: "AI", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMediaImageSearch", description: "Searches images", category: "MEDIA", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMediaImageAttach", description: "Attaches image", category: "MEDIA", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMediaPromptGenerator", description: "Generates prompts", category: "MEDIA", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolMediaAutoLayout", description: "Auto layout for media", category: "MEDIA", inputSchema: [:], producesCode: false),
        WorkspaceAIToolDefinition(name: "AgenticToolCodeSwiftUIViewGenerator", description: "Generates SwiftUI view", category: "CODE", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolCodeModelBuilder", description: "Builds model code", category: "CODE", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolCodeFeatureScaffolder", description: "Scaffolds features", category: "CODE", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolCodeArchitectureGenerator", description: "Generates architecture", category: "CODE", inputSchema: [:], producesCode: true),
        WorkspaceAIToolDefinition(name: "AgenticToolCodeRefactorEngine", description: "Refactors code", category: "CODE", inputSchema: [:], producesCode: true)
    ]
}
