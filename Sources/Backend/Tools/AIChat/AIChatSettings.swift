import Foundation

struct AIChatSettings: Codable {
    var selectedProviderID: String = "openrouter"
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
