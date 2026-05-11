import Foundation

final class ModelConfigManager: ObservableObject {
    static let shared = ModelConfigManager()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let reasoning = "ModelConfig_reasoningModel"
        static let vision = "ModelConfig_visionModel"
        static let language = "ModelConfig_languageModel"
    }

    @Published var reasoningModel: String {
        didSet { defaults.set(reasoningModel, forKey: Keys.reasoning) }
    }

    @Published var visionModel: String {
        didSet { defaults.set(visionModel, forKey: Keys.vision) }
    }

    @Published var languageModel: String {
        didSet { defaults.set(languageModel, forKey: Keys.language) }
    }

    private init() {
        self.reasoningModel = defaults.string(forKey: Keys.reasoning) ?? ""
        self.visionModel = defaults.string(forKey: Keys.vision) ?? ""
        self.languageModel = defaults.string(forKey: Keys.language) ?? ""
    }

    var hasReasoningModel: Bool {
        !reasoningModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasVisionModel: Bool {
        !visionModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasLanguageModel: Bool {
        !languageModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func effectiveReasoningModel(fallback: String = "openrouter/reasoning") -> String {
        hasReasoningModel ? reasoningModel : fallback
    }

    func effectiveVisionModel(fallback: String = "openrouter/vision") -> String {
        hasVisionModel ? visionModel : fallback
    }

    func effectiveLanguageModel(fallback: String = "openrouter/language") -> String {
        hasLanguageModel ? languageModel : fallback
    }

    func isEndpoint(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }
}

