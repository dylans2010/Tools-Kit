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

struct AIChatSettings: Codable {
    var selectedProviderID: String = "openrouter"
    var aiModelSource: AIModelSource = .appModel
    var modelID: String = ""
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
