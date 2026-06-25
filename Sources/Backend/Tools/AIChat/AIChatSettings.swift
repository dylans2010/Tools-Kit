import Foundation
import SwiftUI

struct PromptVariable: Codable, Identifiable {
    var id = UUID()
    var name: String
    var value: String
}

struct FileSource: Codable, Identifiable {
    var id = UUID()
    var path: String
    var isActive: Bool = true
}

struct WebSource: Codable, Identifiable {
    var id = UUID()
    var url: String
    var isActive: Bool = true
}

struct PromptChain: Codable, Identifiable {
    var id = UUID()
    var name: String
    var steps: [String]
}

struct LocalModelConfig: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String = "My Local Model"
    var baseURL: String = "http://localhost:11434/v1/chat/completions"
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
        case id, name, baseURL, modelName, apiKey, customHeaders, timeout
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
}

struct AIChatSettings: Codable {
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

struct SystemPromptPreset: Identifiable, Codable {
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
