import Foundation

struct IntegrationTool: Codable, Identifiable, Equatable, Sendable {
    enum TriggerMode: String, Codable, CaseIterable, Identifiable, Sendable {
        case manual = "Manual"
        case onSave = "On Save"
        case onDemand = "On Demand"
        case scheduled = "Scheduled"
        var id: String { rawValue }
    }

    enum InputScope: String, Codable, CaseIterable, Identifiable, Sendable {
        case currentPage = "Current Page"
        case selectedText = "Selected Text"
        case folderPages = "Folder Pages"
        case entireNotebook = "Entire Notebook"
        var id: String { rawValue }
    }

    enum OutputStyle: String, Codable, CaseIterable, Identifiable, Sendable {
        case markdown = "Markdown"
        case bulletList = "Bullet List"
        case checklist = "Checklist"
        case json = "JSON"
        case summary = "Summary"
        var id: String { rawValue }
    }

    var id: UUID = UUID()
    var name: String = ""
    var description: String = ""
    var category: String = "General"
    var tags: [String] = []
    var promptTemplate: String = ""
    var systemPrompt: String = "You are a helpful assistant."
    var temperature: Double = 0.7
    var topP: Double = 1.0
    var frequencyPenalty: Double = 0.0
    var presencePenalty: Double = 0.0
    var maxResponseTokens: Int = 1200
    var aiModel: String = "openai/gpt-3.5-turbo"
    var triggerMode: TriggerMode = .manual
    var inputScope: InputScope = .currentPage
    var outputStyle: OutputStyle = .markdown
    var includeAttachmentsContext: Bool = true
    var runInBackground: Bool = false
    var allowWebResults: Bool = false
    var timeoutSeconds: Int = 60
    var requiredVariables: [String] = []
    var exampleInputs: [String] = []
    var postProcessingRules: [String] = []
    var isEnabled: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    private enum CodingKeys: String, CodingKey, Sendable {
        case id, name, description, category, tags, promptTemplate, systemPrompt
        case temperature, topP, frequencyPenalty, presencePenalty, maxResponseTokens
        case aiModel, triggerMode, inputScope, outputStyle, includeAttachmentsContext
        case runInBackground, allowWebResults, timeoutSeconds, requiredVariables
        case exampleInputs, postProcessingRules, isEnabled, createdAt, updatedAt
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "General"
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        promptTemplate = try c.decodeIfPresent(String.self, forKey: .promptTemplate) ?? ""
        systemPrompt = try c.decodeIfPresent(String.self, forKey: .systemPrompt) ?? "You are a helpful assistant."
        temperature = try c.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
        topP = try c.decodeIfPresent(Double.self, forKey: .topP) ?? 1.0
        frequencyPenalty = try c.decodeIfPresent(Double.self, forKey: .frequencyPenalty) ?? 0.0
        presencePenalty = try c.decodeIfPresent(Double.self, forKey: .presencePenalty) ?? 0.0
        maxResponseTokens = try c.decodeIfPresent(Int.self, forKey: .maxResponseTokens) ?? 1200
        aiModel = try c.decodeIfPresent(String.self, forKey: .aiModel) ?? "openai/gpt-3.5-turbo"
        triggerMode = try c.decodeIfPresent(TriggerMode.self, forKey: .triggerMode) ?? .manual
        inputScope = try c.decodeIfPresent(InputScope.self, forKey: .inputScope) ?? .currentPage
        outputStyle = try c.decodeIfPresent(OutputStyle.self, forKey: .outputStyle) ?? .markdown
        includeAttachmentsContext = try c.decodeIfPresent(Bool.self, forKey: .includeAttachmentsContext) ?? true
        runInBackground = try c.decodeIfPresent(Bool.self, forKey: .runInBackground) ?? false
        allowWebResults = try c.decodeIfPresent(Bool.self, forKey: .allowWebResults) ?? false
        timeoutSeconds = try c.decodeIfPresent(Int.self, forKey: .timeoutSeconds) ?? 60
        requiredVariables = try c.decodeIfPresent([String].self, forKey: .requiredVariables) ?? []
        exampleInputs = try c.decodeIfPresent([String].self, forKey: .exampleInputs) ?? []
        postProcessingRules = try c.decodeIfPresent([String].self, forKey: .postProcessingRules) ?? []
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(category, forKey: .category)
        try c.encode(tags, forKey: .tags)
        try c.encode(promptTemplate, forKey: .promptTemplate)
        try c.encode(systemPrompt, forKey: .systemPrompt)
        try c.encode(temperature, forKey: .temperature)
        try c.encode(topP, forKey: .topP)
        try c.encode(frequencyPenalty, forKey: .frequencyPenalty)
        try c.encode(presencePenalty, forKey: .presencePenalty)
        try c.encode(maxResponseTokens, forKey: .maxResponseTokens)
        try c.encode(aiModel, forKey: .aiModel)
        try c.encode(triggerMode, forKey: .triggerMode)
        try c.encode(inputScope, forKey: .inputScope)
        try c.encode(outputStyle, forKey: .outputStyle)
        try c.encode(includeAttachmentsContext, forKey: .includeAttachmentsContext)
        try c.encode(runInBackground, forKey: .runInBackground)
        try c.encode(allowWebResults, forKey: .allowWebResults)
        try c.encode(timeoutSeconds, forKey: .timeoutSeconds)
        try c.encode(requiredVariables, forKey: .requiredVariables)
        try c.encode(exampleInputs, forKey: .exampleInputs)
        try c.encode(postProcessingRules, forKey: .postProcessingRules)
        try c.encode(isEnabled, forKey: .isEnabled)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}
