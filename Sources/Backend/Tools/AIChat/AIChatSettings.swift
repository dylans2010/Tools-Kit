import Foundation
import SwiftUI

// MARK: - AIModel

struct AIModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let supportsVision: Bool
    let contextLength: Int?

    init(id: String, name: String, supportsVision: Bool = false, contextLength: Int? = nil) {
        self.id = id
        self.name = name
        self.supportsVision = supportsVision
        self.contextLength = contextLength
    }
}

// MARK: - Enums

enum LocalProviderType: String, Codable, CaseIterable {
    case ollama = "Ollama"
    case lmStudio = "LM Studio"
    case openAICompatible = "OpenAI-Compatible"
    case unknown = "Unknown"
}

enum AIModelSource: String, Codable, CaseIterable {
    case appModel = "App Model"
    case ownKey = "My API Key"
    case local = "Local Model"
}

enum ResponseTone: String, Codable, CaseIterable {
    case professional = "Professional"
    case casual = "Casual"
    case creative = "Creative"
    case balanced = "Balanced"
}

enum ResponseLength: String, Codable, CaseIterable {
    case concise = "Concise"
    case medium = "Medium"
    case detailed = "Detailed"
}

// MARK: - Models

struct PromptVariable: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var value: String
}

struct FileSource: Codable, Identifiable, Equatable {
    var id = UUID()
    var path: String
    var isActive: Bool = true
}

struct WebSource: Codable, Identifiable, Equatable {
    var id = UUID()
    var url: String
    var isActive: Bool = true
}

struct PromptChain: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var steps: [String]
}

struct LocalModelConfig: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String = "My Local Model"
    var baseURL: String = "http://localhost:11434/v1/chat/completions"
    var providerType: LocalProviderType = .openAICompatible
    var modelName: String = "llama3"
    var apiKey: String = ""
    var customHeaders: [String: String] = [:]
    var timeout: Double = 30.0

    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var topP: Double = 1.0
    var frequencyPenalty: Double = 0.0
    var presencePenalty: Double = 0.0
    var isStreamingEnabled: Bool = true

    // New Advanced Parameters
    var seed: Int = 0
    var topK: Int = 40
    var minP: Double = 0.05
    var typicalP: Double = 1.0
    var tfsZ: Double = 1.0
    var repeatPenalty: Double = 1.1
    var repeatLastN: Int = 64
    var mirostat: Int = 0
    var mirostatTau: Double = 5.0
    var mirostatEta: Double = 0.1
    var numGpu: Int = 0
    var numThread: Int = 8
    var useMLock: Bool = false
    var useMMap: Bool = true
    var stopSequences: [String] = []
    var logprobs: Int = 0
    var batchSize: Int = 512
    var contextLength: Int = 2048
    var lowVRAM: Bool = false
    var f16KV: Bool = true
    var logitsAll: Bool = false
    var vocabOnly: Bool = false

    var cachedModels: [AIModel] = []

    enum CodingKeys: String, CodingKey {
        case id, name, baseURL, providerType, modelName, apiKey, customHeaders, timeout
        case temperature, maxTokens, topP, frequencyPenalty, presencePenalty, isStreamingEnabled
        case seed, topK, minP, typicalP, tfsZ, repeatPenalty, repeatLastN
        case mirostat, mirostatTau, mirostatEta, numGpu, numThread, useMLock, useMMap
        case stopSequences, logprobs, batchSize, contextLength, lowVRAM, f16KV, logitsAll, vocabOnly
        case cachedModels
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "My Local Model"
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? "http://localhost:11434/v1/chat/completions"
        providerType = try container.decodeIfPresent(LocalProviderType.self, forKey: .providerType) ?? .openAICompatible
        modelName = try container.decodeIfPresent(String.self, forKey: .modelName) ?? "llama3"
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        customHeaders = try container.decodeIfPresent([String: String].self, forKey: .customHeaders) ?? [:]
        timeout = try container.decodeIfPresent(Double.self, forKey: .timeout) ?? 30.0

        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens) ?? 2048
        topP = try container.decodeIfPresent(Double.self, forKey: .topP) ?? 1.0
        frequencyPenalty = try container.decodeIfPresent(Double.self, forKey: .frequencyPenalty) ?? 0.0
        presencePenalty = try container.decodeIfPresent(Double.self, forKey: .presencePenalty) ?? 0.0
        isStreamingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isStreamingEnabled) ?? true

        seed = try container.decodeIfPresent(Int.self, forKey: .seed) ?? 0
        topK = try container.decodeIfPresent(Int.self, forKey: .topK) ?? 40
        minP = try container.decodeIfPresent(Double.self, forKey: .minP) ?? 0.05
        typicalP = try container.decodeIfPresent(Double.self, forKey: .typicalP) ?? 1.0
        tfsZ = try container.decodeIfPresent(Double.self, forKey: .tfsZ) ?? 1.0
        repeatPenalty = try container.decodeIfPresent(Double.self, forKey: .repeatPenalty) ?? 1.1
        repeatLastN = try container.decodeIfPresent(Int.self, forKey: .repeatLastN) ?? 64
        mirostat = try container.decodeIfPresent(Int.self, forKey: .mirostat) ?? 0
        mirostatTau = try container.decodeIfPresent(Double.self, forKey: .mirostatTau) ?? 5.0
        mirostatEta = try container.decodeIfPresent(Double.self, forKey: .mirostatEta) ?? 0.1
        numGpu = try container.decodeIfPresent(Int.self, forKey: .numGpu) ?? 0
        numThread = try container.decodeIfPresent(Int.self, forKey: .numThread) ?? 8
        useMLock = try container.decodeIfPresent(Bool.self, forKey: .useMLock) ?? false
        useMMap = try container.decodeIfPresent(Bool.self, forKey: .useMMap) ?? true
        stopSequences = try container.decodeIfPresent([String].self, forKey: .stopSequences) ?? []
        logprobs = try container.decodeIfPresent(Int.self, forKey: .logprobs) ?? 0
        batchSize = try container.decodeIfPresent(Int.self, forKey: .batchSize) ?? 512
        contextLength = try container.decodeIfPresent(Int.self, forKey: .contextLength) ?? 2048
        lowVRAM = try container.decodeIfPresent(Bool.self, forKey: .lowVRAM) ?? false
        f16KV = try container.decodeIfPresent(Bool.self, forKey: .f16KV) ?? true
        logitsAll = try container.decodeIfPresent(Bool.self, forKey: .logitsAll) ?? false
        vocabOnly = try container.decodeIfPresent(Bool.self, forKey: .vocabOnly) ?? false
        cachedModels = try container.decodeIfPresent([AIModel].self, forKey: .cachedModels) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(providerType, forKey: .providerType)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(customHeaders, forKey: .customHeaders)
        try container.encode(timeout, forKey: .timeout)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(topP, forKey: .topP)
        try container.encode(frequencyPenalty, forKey: .frequencyPenalty)
        try container.encode(presencePenalty, forKey: .presencePenalty)
        try container.encode(isStreamingEnabled, forKey: .isStreamingEnabled)
        try container.encode(seed, forKey: .seed)
        try container.encode(topK, forKey: .topK)
        try container.encode(minP, forKey: .minP)
        try container.encode(typicalP, forKey: .typicalP)
        try container.encode(tfsZ, forKey: .tfsZ)
        try container.encode(repeatPenalty, forKey: .repeatPenalty)
        try container.encode(repeatLastN, forKey: .repeatLastN)
        try container.encode(mirostat, forKey: .mirostat)
        try container.encode(mirostatTau, forKey: .mirostatTau)
        try container.encode(mirostatEta, forKey: .mirostatEta)
        try container.encode(numGpu, forKey: .numGpu)
        try container.encode(numThread, forKey: .numThread)
        try container.encode(useMLock, forKey: .useMLock)
        try container.encode(useMMap, forKey: .useMMap)
        try container.encode(stopSequences, forKey: .stopSequences)
        try container.encode(logprobs, forKey: .logprobs)
        try container.encode(batchSize, forKey: .batchSize)
        try container.encode(contextLength, forKey: .contextLength)
        try container.encode(lowVRAM, forKey: .lowVRAM)
        try container.encode(f16KV, forKey: .f16KV)
        try container.encode(logitsAll, forKey: .logitsAll)
        try container.encode(vocabOnly, forKey: .vocabOnly)
        try container.encode(cachedModels, forKey: .cachedModels)
    }
}

struct AIChatSettings: Codable, Equatable {
    var selectedProviderID: String = "openrouter"
    var aiModelSource: AIModelSource = .appModel
    var modelID: String = ""
    var selectedAFMModelID: String = "AFM 3 Core"
    var systemPrompt: String = ""
    var useCustomPersonality: Bool = false
    var personalityName: String = ""
    var personalityTraits: [String] = []
    var expertiseAreas: [String] = []
    var knowledgeContext: String = ""
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var topP: Double = 1.0
    var bubbleColorHex: String = "007AFF"
    var fontSize: Double = 16
    var showTimestamps: Bool = false
    var selectedPresetID: String? = nil
    var saveChatHistory: Bool = true
    var streamResponseText: Bool = false
    var logErrorsToConsole: Bool = true
    var memoryEnabled: Bool = true
    var memorySensitivity: Double = 0.7
    var responseTone: ResponseTone = .balanced
    var preferredResponseLength: ResponseLength = .medium
    var useSystemTools: Bool = true
    var autoInjectContext: Bool = false
    var includeConversationHistory: Bool = true
    var dynamicRoutingEnabled: Bool = false

    // Local Models
    var localConfigs: [LocalModelConfig] = []
    var favoriteModels: [AIModel] = []
    var selectedLocalConfigID: UUID? = nil
    var lmStudioUsername: String? = nil

    // Prompt Tools
    var promptVariables: [PromptVariable] = []
    var promptChains: [PromptChain] = []

    // Knowledge & Context
    var fileSources: [FileSource] = []
    var webSources: [WebSource] = []
    var ragTopK: Int = 5
    var ragSimilarityThreshold: Double = 0.75
    var ragChunkSize: Int = 512
    var ragChunkOverlap: Int = 64
    var ragSearchStrategy: String = "Hybrid"
    var ragChunkingStrategy: String = "Sentence"
    var embeddingModel: String = "default"
    var embeddingDimensions: Int = 1536
    var normalizeVectors: Bool = true
    var compressEmbeddings: Bool = false
    var contextAllocationSystemPrompt: Double = 0.2
    var contextAllocationHistory: Double = 0.4
    var contextAllocationRAG: Double = 0.3
    var contextOverflowStrategy: String = "Truncate oldest"
    var showContextOverflowWarning: Bool = true

    // Personality & Tone (Response Formatting)
    var useMarkdown: Bool = true
    var includeCodeBlocks: Bool = true
    var useBulletPoints: Bool = true
    var addSectionHeaders: Bool = false
    var includeTOC: Bool = false
    var defaultCodeLanguage: String = "Swift"
    var showLineNumbers: Bool = false
    var primaryLanguage: String = "English"
    var autoDetectLanguage: Bool = true
    var matchResponseLanguage: Bool = true
    var dateFormat: String = "System"
    var numberFormat: String = "System"

    // Output Constraints
    var maxParagraphs: Int = 10
    var maxSentencesPerParagraph: Int = 5
    var enforceWordCountLimits: Bool = false
    var avoidJargon: Bool = false
    var familyFriendlyOnly: Bool = true
    var citeSources: Bool = false
    var avoidOpinions: Bool = false

    enum CodingKeys: String, CodingKey {
        case selectedProviderID, aiModelSource, modelID, selectedAFMModelID, systemPrompt
        case useCustomPersonality, personalityName, personalityTraits, expertiseAreas, knowledgeContext
        case temperature, maxTokens, topP, bubbleColorHex, fontSize, showTimestamps, selectedPresetID
        case saveChatHistory, streamResponseText, logErrorsToConsole, memoryEnabled, memorySensitivity
        case responseTone, preferredResponseLength, useSystemTools, autoInjectContext, includeConversationHistory, dynamicRoutingEnabled
        case localConfigs, favoriteModels, selectedLocalConfigID, lmStudioUsername
        case promptVariables, promptChains, fileSources, webSources, ragTopK, ragSimilarityThreshold
        case ragChunkSize, ragChunkOverlap, ragSearchStrategy, ragChunkingStrategy, embeddingModel
        case embeddingDimensions, normalizeVectors, compressEmbeddings, contextAllocationSystemPrompt
        case contextAllocationHistory, contextAllocationRAG, contextOverflowStrategy, showContextOverflowWarning
        case useMarkdown, includeCodeBlocks, useBulletPoints, addSectionHeaders, includeTOC
        case defaultCodeLanguage, showLineNumbers, primaryLanguage, autoDetectLanguage, matchResponseLanguage
        case dateFormat, numberFormat, maxParagraphs, maxSentencesPerParagraph, enforceWordCountLimits
        case avoidJargon, familyFriendlyOnly, citeSources, avoidOpinions
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AIChatSettings()

        selectedProviderID = try container.decodeIfPresent(String.self, forKey: .selectedProviderID) ?? defaults.selectedProviderID
        aiModelSource = try container.decodeIfPresent(AIModelSource.self, forKey: .aiModelSource) ?? defaults.aiModelSource
        modelID = try container.decodeIfPresent(String.self, forKey: .modelID) ?? defaults.modelID
        selectedAFMModelID = try container.decodeIfPresent(String.self, forKey: .selectedAFMModelID) ?? defaults.selectedAFMModelID
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt) ?? defaults.systemPrompt
        useCustomPersonality = try container.decodeIfPresent(Bool.self, forKey: .useCustomPersonality) ?? defaults.useCustomPersonality
        personalityName = try container.decodeIfPresent(String.self, forKey: .personalityName) ?? defaults.personalityName
        personalityTraits = try container.decodeIfPresent([String].self, forKey: .personalityTraits) ?? defaults.personalityTraits
        expertiseAreas = try container.decodeIfPresent([String].self, forKey: .expertiseAreas) ?? defaults.expertiseAreas
        knowledgeContext = try container.decodeIfPresent(String.self, forKey: .knowledgeContext) ?? defaults.knowledgeContext
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? defaults.temperature
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens) ?? defaults.maxTokens
        topP = try container.decodeIfPresent(Double.self, forKey: .topP) ?? defaults.topP
        bubbleColorHex = try container.decodeIfPresent(String.self, forKey: .bubbleColorHex) ?? defaults.bubbleColorHex
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? defaults.fontSize
        showTimestamps = try container.decodeIfPresent(Bool.self, forKey: .showTimestamps) ?? defaults.showTimestamps
        selectedPresetID = try container.decodeIfPresent(String.self, forKey: .selectedPresetID) ?? defaults.selectedPresetID
        saveChatHistory = try container.decodeIfPresent(Bool.self, forKey: .saveChatHistory) ?? defaults.saveChatHistory
        streamResponseText = try container.decodeIfPresent(Bool.self, forKey: .streamResponseText) ?? defaults.streamResponseText
        logErrorsToConsole = try container.decodeIfPresent(Bool.self, forKey: .logErrorsToConsole) ?? defaults.logErrorsToConsole
        memoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .memoryEnabled) ?? defaults.memoryEnabled
        memorySensitivity = try container.decodeIfPresent(Double.self, forKey: .memorySensitivity) ?? defaults.memorySensitivity
        responseTone = try container.decodeIfPresent(ResponseTone.self, forKey: .responseTone) ?? defaults.responseTone
        preferredResponseLength = try container.decodeIfPresent(ResponseLength.self, forKey: .preferredResponseLength) ?? defaults.preferredResponseLength
        useSystemTools = try container.decodeIfPresent(Bool.self, forKey: .useSystemTools) ?? defaults.useSystemTools
        autoInjectContext = try container.decodeIfPresent(Bool.self, forKey: .autoInjectContext) ?? defaults.autoInjectContext
        includeConversationHistory = try container.decodeIfPresent(Bool.self, forKey: .includeConversationHistory) ?? defaults.includeConversationHistory
        dynamicRoutingEnabled = try container.decodeIfPresent(Bool.self, forKey: .dynamicRoutingEnabled) ?? defaults.dynamicRoutingEnabled
        localConfigs = try container.decodeIfPresent([LocalModelConfig].self, forKey: .localConfigs) ?? defaults.localConfigs
        favoriteModels = try container.decodeIfPresent([AIModel].self, forKey: .favoriteModels) ?? defaults.favoriteModels
        selectedLocalConfigID = try container.decodeIfPresent(UUID.self, forKey: .selectedLocalConfigID) ?? defaults.selectedLocalConfigID
        lmStudioUsername = try container.decodeIfPresent(String.self, forKey: .lmStudioUsername) ?? defaults.lmStudioUsername
        promptVariables = try container.decodeIfPresent([PromptVariable].self, forKey: .promptVariables) ?? defaults.promptVariables
        promptChains = try container.decodeIfPresent([PromptChain].self, forKey: .promptChains) ?? defaults.promptChains
        fileSources = try container.decodeIfPresent([FileSource].self, forKey: .fileSources) ?? defaults.fileSources
        webSources = try container.decodeIfPresent( [WebSource].self, forKey: .webSources) ?? defaults.webSources
        ragTopK = try container.decodeIfPresent(Int.self, forKey: .ragTopK) ?? defaults.ragTopK
        ragSimilarityThreshold = try container.decodeIfPresent(Double.self, forKey: .ragSimilarityThreshold) ?? defaults.ragSimilarityThreshold
        ragChunkSize = try container.decodeIfPresent(Int.self, forKey: .ragChunkSize) ?? defaults.ragChunkSize
        ragChunkOverlap = try container.decodeIfPresent(Int.self, forKey: .ragChunkOverlap) ?? defaults.ragChunkOverlap
        ragSearchStrategy = try container.decodeIfPresent(String.self, forKey: .ragSearchStrategy) ?? defaults.ragSearchStrategy
        ragChunkingStrategy = try container.decodeIfPresent(String.self, forKey: .ragChunkingStrategy) ?? defaults.ragChunkingStrategy
        embeddingModel = try container.decodeIfPresent(String.self, forKey: .embeddingModel) ?? defaults.embeddingModel
        embeddingDimensions = try container.decodeIfPresent(Int.self, forKey: .embeddingDimensions) ?? defaults.embeddingDimensions
        normalizeVectors = try container.decodeIfPresent(Bool.self, forKey: .normalizeVectors) ?? defaults.normalizeVectors
        compressEmbeddings = try container.decodeIfPresent(Bool.self, forKey: .compressEmbeddings) ?? defaults.compressEmbeddings
        contextAllocationSystemPrompt = try container.decodeIfPresent(Double.self, forKey: .contextAllocationSystemPrompt) ?? defaults.contextAllocationSystemPrompt
        contextAllocationHistory = try container.decodeIfPresent(Double.self, forKey: .contextAllocationHistory) ?? defaults.contextAllocationHistory
        contextAllocationRAG = try container.decodeIfPresent(Double.self, forKey: .contextAllocationRAG) ?? defaults.contextAllocationRAG
        contextOverflowStrategy = try container.decodeIfPresent(String.self, forKey: .contextOverflowStrategy) ?? defaults.contextOverflowStrategy
        showContextOverflowWarning = try container.decodeIfPresent(Bool.self, forKey: .showContextOverflowWarning) ?? defaults.showContextOverflowWarning
        useMarkdown = try container.decodeIfPresent(Bool.self, forKey: .useMarkdown) ?? defaults.useMarkdown
        includeCodeBlocks = try container.decodeIfPresent(Bool.self, forKey: .includeCodeBlocks) ?? defaults.includeCodeBlocks
        useBulletPoints = try container.decodeIfPresent(Bool.self, forKey: .useBulletPoints) ?? defaults.useBulletPoints
        addSectionHeaders = try container.decodeIfPresent(Bool.self, forKey: .addSectionHeaders) ?? defaults.addSectionHeaders
        includeTOC = try container.decodeIfPresent(Bool.self, forKey: .includeTOC) ?? defaults.includeTOC
        defaultCodeLanguage = try container.decodeIfPresent(String.self, forKey: .defaultCodeLanguage) ?? defaults.defaultCodeLanguage
        showLineNumbers = try container.decodeIfPresent(Bool.self, forKey: .showLineNumbers) ?? defaults.showLineNumbers
        primaryLanguage = try container.decodeIfPresent(String.self, forKey: .primaryLanguage) ?? defaults.primaryLanguage
        autoDetectLanguage = try container.decodeIfPresent(Bool.self, forKey: .autoDetectLanguage) ?? defaults.autoDetectLanguage
        matchResponseLanguage = try container.decodeIfPresent(Bool.self, forKey: .matchResponseLanguage) ?? defaults.matchResponseLanguage
        dateFormat = try container.decodeIfPresent(String.self, forKey: .dateFormat) ?? defaults.dateFormat
        numberFormat = try container.decodeIfPresent(String.self, forKey: .numberFormat) ?? defaults.numberFormat
        maxParagraphs = try container.decodeIfPresent(Int.self, forKey: .maxParagraphs) ?? defaults.maxParagraphs
        maxSentencesPerParagraph = try container.decodeIfPresent(Int.self, forKey: .maxSentencesPerParagraph) ?? defaults.maxSentencesPerParagraph
        enforceWordCountLimits = try container.decodeIfPresent(Bool.self, forKey: .enforceWordCountLimits) ?? defaults.enforceWordCountLimits
        avoidJargon = try container.decodeIfPresent(Bool.self, forKey: .avoidJargon) ?? defaults.avoidJargon
        familyFriendlyOnly = try container.decodeIfPresent(Bool.self, forKey: .familyFriendlyOnly) ?? defaults.familyFriendlyOnly
        citeSources = try container.decodeIfPresent(Bool.self, forKey: .citeSources) ?? defaults.citeSources
        avoidOpinions = try container.decodeIfPresent(Bool.self, forKey: .avoidOpinions) ?? defaults.avoidOpinions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedProviderID, forKey: .selectedProviderID)
        try container.encode(aiModelSource, forKey: .aiModelSource)
        try container.encode(modelID, forKey: .modelID)
        try container.encode(selectedAFMModelID, forKey: .selectedAFMModelID)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(useCustomPersonality, forKey: .useCustomPersonality)
        try container.encode(personalityName, forKey: .personalityName)
        try container.encode(personalityTraits, forKey: .personalityTraits)
        try container.encode(expertiseAreas, forKey: .expertiseAreas)
        try container.encode(knowledgeContext, forKey: .knowledgeContext)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(topP, forKey: .topP)
        try container.encode(bubbleColorHex, forKey: .bubbleColorHex)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(showTimestamps, forKey: .showTimestamps)
        try container.encode(selectedPresetID, forKey: .selectedPresetID)
        try container.encode(saveChatHistory, forKey: .saveChatHistory)
        try container.encode(streamResponseText, forKey: .streamResponseText)
        try container.encode(logErrorsToConsole, forKey: .logErrorsToConsole)
        try container.encode(memoryEnabled, forKey: .memoryEnabled)
        try container.encode(memorySensitivity, forKey: .memorySensitivity)
        try container.encode(responseTone, forKey: .responseTone)
        try container.encode(preferredResponseLength, forKey: .preferredResponseLength)
        try container.encode(useSystemTools, forKey: .useSystemTools)
        try container.encode(autoInjectContext, forKey: .autoInjectContext)
        try container.encode(includeConversationHistory, forKey: .includeConversationHistory)
        try container.encode(dynamicRoutingEnabled, forKey: .dynamicRoutingEnabled)
        try container.encode(localConfigs, forKey: .localConfigs)
        try container.encode(favoriteModels, forKey: .favoriteModels)
        try container.encode(selectedLocalConfigID, forKey: .selectedLocalConfigID)
        try container.encode(lmStudioUsername, forKey: .lmStudioUsername)
        try container.encode(promptVariables, forKey: .promptVariables)
        try container.encode(promptChains, forKey: .promptChains)
        try container.encode(fileSources, forKey: .fileSources)
        try container.encode(webSources, forKey: .webSources)
        try container.encode(ragTopK, forKey: .ragTopK)
        try container.encode(ragSimilarityThreshold, forKey: .ragSimilarityThreshold)
        try container.encode(ragChunkSize, forKey: .ragChunkSize)
        try container.encode(ragChunkOverlap, forKey: .ragChunkOverlap)
        try container.encode(ragSearchStrategy, forKey: .ragSearchStrategy)
        try container.encode(ragChunkingStrategy, forKey: .ragChunkingStrategy)
        try container.encode(embeddingModel, forKey: .embeddingModel)
        try container.encode(embeddingDimensions, forKey: .embeddingDimensions)
        try container.encode(normalizeVectors, forKey: .normalizeVectors)
        try container.encode(compressEmbeddings, forKey: .compressEmbeddings)
        try container.encode(contextAllocationSystemPrompt, forKey: .contextAllocationSystemPrompt)
        try container.encode(contextAllocationHistory, forKey: .contextAllocationHistory)
        try container.encode(contextAllocationRAG, forKey: .contextAllocationRAG)
        try container.encode(contextOverflowStrategy, forKey: .contextOverflowStrategy)
        try container.encode(showContextOverflowWarning, forKey: .showContextOverflowWarning)
        try container.encode(useMarkdown, forKey: .useMarkdown)
        try container.encode(includeCodeBlocks, forKey: .includeCodeBlocks)
        try container.encode(useBulletPoints, forKey: .useBulletPoints)
        try container.encode(addSectionHeaders, forKey: .addSectionHeaders)
        try container.encode(includeTOC, forKey: .includeTOC)
        try container.encode(defaultCodeLanguage, forKey: .defaultCodeLanguage)
        try container.encode(showLineNumbers, forKey: .showLineNumbers)
        try container.encode(primaryLanguage, forKey: .primaryLanguage)
        try container.encode(autoDetectLanguage, forKey: .autoDetectLanguage)
        try container.encode(matchResponseLanguage, forKey: .matchResponseLanguage)
        try container.encode(dateFormat, forKey: .dateFormat)
        try container.encode(numberFormat, forKey: .numberFormat)
        try container.encode(maxParagraphs, forKey: .maxParagraphs)
        try container.encode(maxSentencesPerParagraph, forKey: .maxSentencesPerParagraph)
        try container.encode(enforceWordCountLimits, forKey: .enforceWordCountLimits)
        try container.encode(avoidJargon, forKey: .avoidJargon)
        try container.encode(familyFriendlyOnly, forKey: .familyFriendlyOnly)
        try container.encode(citeSources, forKey: .citeSources)
        try container.encode(avoidOpinions, forKey: .avoidOpinions)
    }
}

struct SystemPromptPreset: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var prompt: String
    var icon: String

    static let builtIn: [SystemPromptPreset] = [
        SystemPromptPreset(id: "assistant", name: "General Assistant", prompt: "You are a helpful, accurate, and thoughtful assistant.", icon: "sparkles"),
        SystemPromptPreset(id: "coder", name: "Code Expert", prompt: "You are an expert software engineer. Provide concise, well-commented code with explanations.", icon: "chevron.left.forwardslash.chevron.right"),
        SystemPromptPreset(id: "writer", name: "Creative Writer", prompt: "You are a creative and expressive writer. Help craft engaging narratives, stories, and content.", icon: "pencil.and.outline"),
        SystemPromptPreset(id: "analyst", name: "Data Analyst", prompt: "You are a data analyst. Interpret data, spot trends, and provide insights clearly.", icon: "chart.bar.fill"),
        SystemPromptPreset(id: "teacher", name: "Teacher", prompt: "You are a patient teacher. Explain concepts clearly, use examples, and adapt to the learner's level.", icon: "book.fill"),
    ]
}

class AIChatSettingsManager: ObservableObject {
    static let shared = AIChatSettingsManager()

    @Published var settings: AIChatSettings {
        didSet { save() }
    }

    var settingsBinding: Binding<AIChatSettings> {
        Binding(
            get: { self.settings },
            set: { self.settings = $0 }
        )
    }

    private let key = "AIChatSettings"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AIChatSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AIChatSettings()
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
