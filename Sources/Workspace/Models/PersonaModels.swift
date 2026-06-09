import Foundation

struct PersonaConfig: Codable {
    var name: String
    var instructions: String
    var baseModel: String
    var workspaceScope: [String] // List of folders or categories to index
    var isTrainingEnabled: Bool = true
    var trainingPrompt: String = ""
    var creativity: Double = 0.5
    var formality: Double = 0.5
    var humor: Double = 0.5
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var webSearchEnabled: Bool = false
    var memoryEnabled: Bool = true
    var mcpToolsEnabled: Bool = false

    // 25+ New Options
    var conciseness: Double = 0.5
    var detailLevel: Double = 0.5
    var empathy: Double = 0.5
    var proactivity: Double = 0.5
    var reasoningDepth: Double = 0.5
    var responseStyle: String = "Balanced"
    var language: String = "English"
    var useEmoji: Bool = false
    var useMarkdown: Bool = true
    var includeSources: Bool = false
    var autoCorrect: Bool = true
    var voicePitch: Double = 1.0
    var voiceSpeed: Double = 1.0
    var searchEngine: String = "Google"
    var codingStyle: String = "Standard"
    var showThinking: Bool = true
    var summarizeContext: Bool = false
    var contextWindow: Int = 4096
    var frequencyPenalty: Double = 0.0
    var presencePenalty: Double = 0.0
    var topP: Double = 1.0
    var enableImages: Bool = false
    var enableAudio: Bool = false
    var strictCompliance: Bool = false
    var modelFallback: Bool = true
    var developerMode: Bool = false

    init(
        name: String,
        instructions: String,
        baseModel: String,
        workspaceScope: [String],
        isTrainingEnabled: Bool = true,
        trainingPrompt: String = "",
        creativity: Double = 0.5,
        formality: Double = 0.5,
        humor: Double = 0.5,
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        webSearchEnabled: Bool = false,
        memoryEnabled: Bool = true,
        mcpToolsEnabled: Bool = false,
        conciseness: Double = 0.5,
        detailLevel: Double = 0.5,
        empathy: Double = 0.5,
        proactivity: Double = 0.5,
        reasoningDepth: Double = 0.5,
        responseStyle: String = "Balanced",
        language: String = "English",
        useEmoji: Bool = false,
        useMarkdown: Bool = true,
        includeSources: Bool = false,
        autoCorrect: Bool = true,
        voicePitch: Double = 1.0,
        voiceSpeed: Double = 1.0,
        searchEngine: String = "Google",
        codingStyle: String = "Standard",
        showThinking: Bool = true,
        summarizeContext: Bool = false,
        contextWindow: Int = 4096,
        frequencyPenalty: Double = 0.0,
        presencePenalty: Double = 0.0,
        topP: Double = 1.0,
        enableImages: Bool = false,
        enableAudio: Bool = false,
        strictCompliance: Bool = false,
        modelFallback: Bool = true,
        developerMode: Bool = false
    ) {
        self.name = name
        self.instructions = instructions
        self.baseModel = baseModel
        self.workspaceScope = workspaceScope
        self.isTrainingEnabled = isTrainingEnabled
        self.trainingPrompt = trainingPrompt
        self.creativity = creativity
        self.formality = formality
        self.humor = humor
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.webSearchEnabled = webSearchEnabled
        self.memoryEnabled = memoryEnabled
        self.mcpToolsEnabled = mcpToolsEnabled
        self.conciseness = conciseness
        self.detailLevel = detailLevel
        self.empathy = empathy
        self.proactivity = proactivity
        self.reasoningDepth = reasoningDepth
        self.responseStyle = responseStyle
        self.language = language
        self.useEmoji = useEmoji
        self.useMarkdown = useMarkdown
        self.includeSources = includeSources
        self.autoCorrect = autoCorrect
        self.voicePitch = voicePitch
        self.voiceSpeed = voiceSpeed
        self.searchEngine = searchEngine
        self.codingStyle = codingStyle
        self.showThinking = showThinking
        self.summarizeContext = summarizeContext
        self.contextWindow = contextWindow
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.topP = topP
        self.enableImages = enableImages
        self.enableAudio = enableAudio
        self.strictCompliance = strictCompliance
        self.modelFallback = modelFallback
        self.developerMode = developerMode
    }

    private enum CodingKeys: String, CodingKey {
        case name, instructions, baseModel, workspaceScope, isTrainingEnabled, trainingPrompt
        case creativity, formality, humor, temperature, maxTokens, webSearchEnabled, memoryEnabled, mcpToolsEnabled
        case conciseness, detailLevel, empathy, proactivity, reasoningDepth, responseStyle, language, useEmoji, useMarkdown, includeSources, autoCorrect, voicePitch, voiceSpeed, searchEngine, codingStyle, showThinking, summarizeContext, contextWindow, frequencyPenalty, presencePenalty, topP, enableImages, enableAudio, strictCompliance, modelFallback, developerMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        instructions = try container.decode(String.self, forKey: .instructions)
        baseModel = try container.decode(String.self, forKey: .baseModel)
        workspaceScope = try container.decode([String].self, forKey: .workspaceScope)
        isTrainingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTrainingEnabled) ?? true
        trainingPrompt = try container.decodeIfPresent(String.self, forKey: .trainingPrompt) ?? ""
        creativity = try container.decodeIfPresent(Double.self, forKey: .creativity) ?? 0.5
        formality = try container.decodeIfPresent(Double.self, forKey: .formality) ?? 0.5
        humor = try container.decodeIfPresent(Double.self, forKey: .humor) ?? 0.5
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens) ?? 2048
        webSearchEnabled = try container.decodeIfPresent(Bool.self, forKey: .webSearchEnabled) ?? false
        memoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .memoryEnabled) ?? true
        mcpToolsEnabled = try container.decodeIfPresent(Bool.self, forKey: .mcpToolsEnabled) ?? false

        conciseness = try container.decodeIfPresent(Double.self, forKey: .conciseness) ?? 0.5
        detailLevel = try container.decodeIfPresent(Double.self, forKey: .detailLevel) ?? 0.5
        empathy = try container.decodeIfPresent(Double.self, forKey: .empathy) ?? 0.5
        proactivity = try container.decodeIfPresent(Double.self, forKey: .proactivity) ?? 0.5
        reasoningDepth = try container.decodeIfPresent(Double.self, forKey: .reasoningDepth) ?? 0.5
        responseStyle = try container.decodeIfPresent(String.self, forKey: .responseStyle) ?? "Balanced"
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? "English"
        useEmoji = try container.decodeIfPresent(Bool.self, forKey: .useEmoji) ?? false
        useMarkdown = try container.decodeIfPresent(Bool.self, forKey: .useMarkdown) ?? true
        includeSources = try container.decodeIfPresent(Bool.self, forKey: .includeSources) ?? false
        autoCorrect = try container.decodeIfPresent(Bool.self, forKey: .autoCorrect) ?? true
        voicePitch = try container.decodeIfPresent(Double.self, forKey: .voicePitch) ?? 1.0
        voiceSpeed = try container.decodeIfPresent(Double.self, forKey: .voiceSpeed) ?? 1.0
        searchEngine = try container.decodeIfPresent(String.self, forKey: .searchEngine) ?? "Google"
        codingStyle = try container.decodeIfPresent(String.self, forKey: .codingStyle) ?? "Standard"
        showThinking = try container.decodeIfPresent(Bool.self, forKey: .showThinking) ?? true
        summarizeContext = try container.decodeIfPresent(Bool.self, forKey: .summarizeContext) ?? false
        contextWindow = try container.decodeIfPresent(Int.self, forKey: .contextWindow) ?? 4096
        frequencyPenalty = try container.decodeIfPresent(Double.self, forKey: .frequencyPenalty) ?? 0.0
        presencePenalty = try container.decodeIfPresent(Double.self, forKey: .presencePenalty) ?? 0.0
        topP = try container.decodeIfPresent(Double.self, forKey: .topP) ?? 1.0
        enableImages = try container.decodeIfPresent(Bool.self, forKey: .enableImages) ?? false
        enableAudio = try container.decodeIfPresent(Bool.self, forKey: .enableAudio) ?? false
        strictCompliance = try container.decodeIfPresent(Bool.self, forKey: .strictCompliance) ?? false
        modelFallback = try container.decodeIfPresent(Bool.self, forKey: .modelFallback) ?? true
        developerMode = try container.decodeIfPresent(Bool.self, forKey: .developerMode) ?? false
    }
}

struct PersonaInteraction: Codable, Identifiable {
    var id: UUID = UUID()
    var query: String
    var response: String
    var contextUsed: [String] // IDs of entities used for context
    var timestamp: Date = Date()
}

struct PersonaMessage: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var role: String // "user" or "assistant"
    var content: String
    var timestamp: Date = Date()
}

struct PersonaModelTraining: Codable, Identifiable {
    var id: UUID = UUID()
    var userQuery: String
    var aiResponse: String
    var timestamp: Date = Date()
}


struct PersonaChatThread: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var messages: [PersonaMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [PersonaMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
