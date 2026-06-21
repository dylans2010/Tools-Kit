import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class AFMService: ObservableObject {
    static let shared = AFMService()

    @Published var isAvailable = false
    @Published var availabilityMessage = "Checking availability..."

    #if canImport(FoundationModels)
    private var activeSession: LanguageModelSession?
    #endif

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            self.isAvailable = true
            self.availabilityMessage = "Apple Foundation Models are available and ready."
        case .unavailable(let reason):
            self.isAvailable = false
            self.availabilityMessage = "AFM Unavailable: \(reason)"
        @unknown default:
            self.isAvailable = false
            self.availabilityMessage = "AFM status unknown."
        }
        #else
        self.isAvailable = false
        self.availabilityMessage = "FoundationModels framework not supported on this platform."
        #endif
    }

    func generateResponse(prompt: String, systemPrompt: String = "") async throws -> String {
        #if canImport(FoundationModels)
        let selectedModelID = AIChatSettingsManager.shared.settings.selectedAFMModelID

        if activeSession == nil {
            let instructions = systemPrompt.isEmpty ? "You are a helpful assistant." : systemPrompt
            // In a real environment, we'd select the model variant here if supported by the API
            activeSession = LanguageModelSession(instructions: instructions)
        }

        guard let session = activeSession else {
            throw NSError(domain: "AFMService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize session"])
        }

        let response = try await session.respond(to: prompt)
        return response.content
        #else
        throw NSError(domain: "AFMService", code: 501, userInfo: [NSLocalizedDescriptionKey: "FoundationModels not available"])
        #endif
    }

    func resetSession() {
        #if canImport(FoundationModels)
        activeSession = nil
        #endif
    }
}
