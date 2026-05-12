import Foundation

@MainActor
final class WorkspaceAITools: ObservableObject {
    nonisolated(unsafe) static let shared = WorkspaceAITools()

    @Published private(set) var tools: [WorkspaceAIToolDefinition] = []

    private init() {
        registerAllTools()
    }

    // MARK: - Lookup

    func tool(named name: String) -> WorkspaceAIToolDefinition? {
        tools.first { $0.name == name }
    }

    func tools(inCategory category: String) -> [WorkspaceAIToolDefinition] {
        tools.filter { $0.category == category }
    }

    func validate(toolName: String) -> Bool {
        tools.contains { $0.name == toolName }
    }

    var categories: [String] {
        Array(Set(tools.map(\.category))).sorted()
    }

    // MARK: - Context Injection

    func registryContextForModel() -> String {
        let toolDescriptions = tools.map { tool -> String in
            let params = tool.inputSchema.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "- \(tool.name) [\(tool.category)]: \(tool.description) | params: {\(params)}"
        }
        return """
        AVAILABLE TOOLS (\(tools.count) registered):
        \(toolDescriptions.joined(separator: "\n"))

        RULES:
        - Only use tools listed above
        - Validate parameters match the schema
        - Never hallucinate tool names
        - Report unknown tools as errors
        """
    }

    // MARK: - Registration

    private func registerAllTools() {
        tools = [
            // TASK ENGINE
            WorkspaceAIToolDefinition(name: "task_create", description: "Create a new task with title, description, priority, and due date", category: "tasks", inputSchema: ["title": "String", "description": "String", "priority": "String", "dueDate": "String"]),
            WorkspaceAIToolDefinition(name: "task_update", description: "Update an existing task by ID", category: "tasks", inputSchema: ["taskId": "String", "field": "String", "value": "String"]),
            WorkspaceAIToolDefinition(name: "task_delete", description: "Delete a task by ID", category: "tasks", inputSchema: ["taskId": "String"]),
            WorkspaceAIToolDefinition(name: "task_list", description: "List all tasks with optional filters", category: "tasks", inputSchema: ["filter": "String", "sortBy": "String"]),
            WorkspaceAIToolDefinition(name: "task_schedule", description: "Schedule a task for a specific time slot", category: "tasks", inputSchema: ["taskId": "String", "scheduledDate": "String", "duration": "String"]),
            WorkspaceAIToolDefinition(name: "task_prioritize", description: "Auto-prioritize tasks based on deadlines and importance", category: "tasks", inputSchema: ["strategy": "String"]),
            WorkspaceAIToolDefinition(name: "task_auto_plan", description: "Generate an execution plan for a set of tasks", category: "tasks", inputSchema: ["scope": "String", "timeframe": "String"]),
            WorkspaceAIToolDefinition(name: "task_dependency_graph", description: "Build and return a dependency graph for tasks", category: "tasks", inputSchema: ["rootTaskId": "String"]),
            WorkspaceAIToolDefinition(name: "task_critical_path", description: "Analyze the critical path through task dependencies", category: "tasks", inputSchema: ["projectScope": "String"]),
            WorkspaceAIToolDefinition(name: "task_resource_optimizer", description: "Optimize resource allocation across tasks", category: "tasks", inputSchema: ["constraints": "String", "resources": "String"]),

            // NOTES ENGINE
            WorkspaceAIToolDefinition(name: "note_create", description: "Create a new note in a notebook", category: "notes", inputSchema: ["notebookName": "String", "title": "String", "content": "String"]),
            WorkspaceAIToolDefinition(name: "note_update", description: "Update an existing note", category: "notes", inputSchema: ["noteId": "String", "content": "String"]),
            WorkspaceAIToolDefinition(name: "note_delete", description: "Delete a note by ID", category: "notes", inputSchema: ["noteId": "String"]),
            WorkspaceAIToolDefinition(name: "note_search", description: "Search notes by query string", category: "notes", inputSchema: ["query": "String", "scope": "String"]),
            WorkspaceAIToolDefinition(name: "note_summarize", description: "Summarize a note or set of notes using AI", category: "notes", inputSchema: ["noteId": "String"]),
            WorkspaceAIToolDefinition(name: "note_extract_insights", description: "Extract key insights and action items from notes", category: "notes", inputSchema: ["noteId": "String"]),
            WorkspaceAIToolDefinition(name: "note_auto_tag", description: "Automatically tag notes based on content analysis", category: "notes", inputSchema: ["noteId": "String"]),
            WorkspaceAIToolDefinition(name: "note_graph_linker", description: "Link related notes into a knowledge graph", category: "notes", inputSchema: ["scope": "String"]),

            // CALENDAR ENGINE
            WorkspaceAIToolDefinition(name: "calendar_event_create", description: "Create a new calendar event", category: "calendar", inputSchema: ["title": "String", "startDate": "String", "endDate": "String", "description": "String"]),
            WorkspaceAIToolDefinition(name: "calendar_event_update", description: "Update an existing calendar event", category: "calendar", inputSchema: ["eventId": "String", "field": "String", "value": "String"]),
            WorkspaceAIToolDefinition(name: "calendar_event_delete", description: "Delete a calendar event", category: "calendar", inputSchema: ["eventId": "String"]),
            WorkspaceAIToolDefinition(name: "calendar_availability_finder", description: "Find available time slots", category: "calendar", inputSchema: ["dateRange": "String", "duration": "String"]),
            WorkspaceAIToolDefinition(name: "calendar_conflict_resolver", description: "Detect and resolve scheduling conflicts", category: "calendar", inputSchema: ["dateRange": "String"]),
            WorkspaceAIToolDefinition(name: "calendar_smart_schedule", description: "AI-powered smart scheduling based on preferences and patterns", category: "calendar", inputSchema: ["title": "String", "duration": "String", "priority": "String"]),

            // MAIL ENGINE
            WorkspaceAIToolDefinition(name: "mail_summarize", description: "Summarize email threads or inbox", category: "mail", inputSchema: ["scope": "String", "count": "String"]),
            WorkspaceAIToolDefinition(name: "mail_draft", description: "Draft an email using AI", category: "mail", inputSchema: ["to": "String", "subject": "String", "context": "String"]),
            WorkspaceAIToolDefinition(name: "mail_send", description: "Send a drafted email", category: "mail", inputSchema: ["draftId": "String"]),
            WorkspaceAIToolDefinition(name: "mail_search", description: "Search emails by query", category: "mail", inputSchema: ["query": "String", "account": "String"]),
            WorkspaceAIToolDefinition(name: "mail_extract_actions", description: "Extract action items from emails", category: "mail", inputSchema: ["emailId": "String"]),
            WorkspaceAIToolDefinition(name: "mail_auto_reply", description: "Generate an AI auto-reply for an email", category: "mail", inputSchema: ["emailId": "String", "tone": "String"]),
            WorkspaceAIToolDefinition(name: "mail_priority_classifier", description: "Classify email priority using AI", category: "mail", inputSchema: ["scope": "String"]),

            // SLIDES ENGINE
            WorkspaceAIToolDefinition(name: "slides_generate", description: "Generate a complete slide deck from a topic", category: "slides", inputSchema: ["topic": "String", "slideCount": "String", "style": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "slides_edit", description: "Edit a specific slide", category: "slides", inputSchema: ["deckId": "String", "slideIndex": "String", "content": "String"]),
            WorkspaceAIToolDefinition(name: "slides_build_renderer", description: "Build a renderer for slide content", category: "slides", inputSchema: ["deckId": "String", "format": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "slides_theme_system", description: "Apply or generate a theme for slides", category: "slides", inputSchema: ["deckId": "String", "theme": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "slides_export_pdf", description: "Export slide deck to PDF", category: "slides", inputSchema: ["deckId": "String"]),
            WorkspaceAIToolDefinition(name: "slides_insert_media", description: "Insert media into a slide", category: "slides", inputSchema: ["deckId": "String", "slideIndex": "String", "mediaType": "String", "source": "String"]),
            WorkspaceAIToolDefinition(name: "slides_layout_optimizer", description: "Optimize slide layouts using AI", category: "slides", inputSchema: ["deckId": "String"]),

            // SPREADSHEET ENGINE
            WorkspaceAIToolDefinition(name: "sheet_create", description: "Create a new spreadsheet", category: "spreadsheet", inputSchema: ["name": "String", "columns": "String"]),
            WorkspaceAIToolDefinition(name: "sheet_update_cell", description: "Update a cell value", category: "spreadsheet", inputSchema: ["sheetId": "String", "row": "String", "column": "String", "value": "String"]),
            WorkspaceAIToolDefinition(name: "sheet_formula_engine", description: "Evaluate or create formulas", category: "spreadsheet", inputSchema: ["sheetId": "String", "formula": "String", "targetCell": "String"]),
            WorkspaceAIToolDefinition(name: "sheet_analyzer", description: "Analyze spreadsheet data for patterns and statistics", category: "spreadsheet", inputSchema: ["sheetId": "String", "analysisType": "String"]),
            WorkspaceAIToolDefinition(name: "sheet_visualization_generator", description: "Generate chart/visualization from sheet data", category: "spreadsheet", inputSchema: ["sheetId": "String", "chartType": "String", "dataRange": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "sheet_dependency_resolver", description: "Resolve formula dependencies in a spreadsheet", category: "spreadsheet", inputSchema: ["sheetId": "String"]),

            // WORKSPACE GRAPH ENGINE
            WorkspaceAIToolDefinition(name: "workspace_search", description: "Search across entire workspace", category: "workspace", inputSchema: ["query": "String", "scope": "String"]),
            WorkspaceAIToolDefinition(name: "workspace_open_item", description: "Open a workspace item by ID or name", category: "workspace", inputSchema: ["itemId": "String", "itemType": "String"]),
            WorkspaceAIToolDefinition(name: "workspace_link_graph", description: "Build a link graph between workspace items", category: "workspace", inputSchema: ["rootId": "String", "depth": "String"]),
            WorkspaceAIToolDefinition(name: "workspace_tagging_engine", description: "Tag workspace items using AI classification", category: "workspace", inputSchema: ["itemId": "String", "autoDetect": "String"]),
            WorkspaceAIToolDefinition(name: "workspace_index_builder", description: "Build or rebuild the workspace search index", category: "workspace", inputSchema: ["scope": "String"]),
            WorkspaceAIToolDefinition(name: "workspace_semantic_index", description: "Build semantic embeddings index for workspace items", category: "workspace", inputSchema: ["scope": "String"]),

            // AI TRANSFORMATION ENGINE
            WorkspaceAIToolDefinition(name: "ai_text_summarize", description: "Summarize any text using Foundation Models", category: "ai_transform", inputSchema: ["text": "String", "maxLength": "String"]),
            WorkspaceAIToolDefinition(name: "ai_text_rewrite", description: "Rewrite text in a different tone or style", category: "ai_transform", inputSchema: ["text": "String", "style": "String"]),
            WorkspaceAIToolDefinition(name: "ai_text_translate", description: "Translate text to another language", category: "ai_transform", inputSchema: ["text": "String", "targetLanguage": "String"]),
            WorkspaceAIToolDefinition(name: "ai_idea_generator", description: "Generate ideas based on a topic or context", category: "ai_transform", inputSchema: ["topic": "String", "count": "String"]),
            WorkspaceAIToolDefinition(name: "ai_classifier", description: "Classify text into categories", category: "ai_transform", inputSchema: ["text": "String", "categories": "String"]),
            WorkspaceAIToolDefinition(name: "ai_content_extractor", description: "Extract structured data from unstructured text", category: "ai_transform", inputSchema: ["text": "String", "extractionType": "String"]),
            WorkspaceAIToolDefinition(name: "ai_structured_transformer", description: "Transform text into a structured format", category: "ai_transform", inputSchema: ["text": "String", "outputFormat": "String"]),

            // MEDIA ENGINE
            WorkspaceAIToolDefinition(name: "media_image_search", description: "Search for images in the workspace", category: "media", inputSchema: ["query": "String", "scope": "String"]),
            WorkspaceAIToolDefinition(name: "media_image_attach", description: "Attach an image to a workspace item", category: "media", inputSchema: ["imageId": "String", "targetId": "String", "targetType": "String"]),
            WorkspaceAIToolDefinition(name: "media_prompt_generator", description: "Generate image prompts using AI", category: "media", inputSchema: ["description": "String", "style": "String"]),
            WorkspaceAIToolDefinition(name: "media_auto_layout", description: "Auto-layout media in a document or slide", category: "media", inputSchema: ["targetId": "String", "mediaIds": "String"]),
            WorkspaceAIToolDefinition(name: "media_composition_engine", description: "Compose multiple media elements into a layout", category: "media", inputSchema: ["elements": "String", "canvasSize": "String"], producesCode: true),

            // CODE GENERATION ENGINE
            WorkspaceAIToolDefinition(name: "code_swiftui_view_generator", description: "Generate a complete SwiftUI view from a description", category: "codegen", inputSchema: ["viewDescription": "String", "viewName": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "code_model_builder", description: "Generate Swift data models from a schema", category: "codegen", inputSchema: ["modelName": "String", "properties": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "code_feature_scaffolder", description: "Scaffold a complete feature module", category: "codegen", inputSchema: ["featureName": "String", "components": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "code_architecture_generator", description: "Generate architectural scaffolding for a system", category: "codegen", inputSchema: ["systemName": "String", "pattern": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "code_refactor_engine", description: "Refactor existing Swift code using AI", category: "codegen", inputSchema: ["sourceCode": "String", "refactorType": "String"], producesCode: true),
            WorkspaceAIToolDefinition(name: "code_module_assembler", description: "Assemble multiple generated components into a module", category: "codegen", inputSchema: ["moduleName": "String", "componentIds": "String"], producesCode: true),
        ]
    }
}
