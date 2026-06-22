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
    private var activeSession: Any?
    #endif

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            self.isAvailable = true
            self.availabilityMessage = "Apple Foundation Models are available and ready."
        } else {
            self.isAvailable = false
            self.availabilityMessage = "Requires iOS 26 or newer."
        }
        #else
        self.isAvailable = false
        self.availabilityMessage = "FoundationModels framework not supported on this platform."
        #endif
    }

    func generateResponse(prompt: String, systemPrompt: String = "") async throws -> String {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            throw NSError(domain: "AFMService", code: 502, userInfo: [NSLocalizedDescriptionKey: "Requires iOS 26 or newer"])
        }
        let selectedModelID = AIChatSettingsManager.shared.settings.selectedAFMModelID

        var session: LanguageModelSession

        if let existing = activeSession as? LanguageModelSession {
            session = existing
        } else {
            let instructions = systemPrompt.isEmpty ? "You are a helpful assistant." : systemPrompt
            let newSession = LanguageModelSession(instructions: instructions)
            activeSession = newSession
            session = newSession
        }

        let response = try await session.respond(to: prompt)
        return response.content
        #else
        throw NSError(domain: "AFMService", code: 501, userInfo: [NSLocalizedDescriptionKey: "FoundationModels not available"])
        #endif
    }

    func resetSession() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            activeSession = nil
        }
        #endif
    }
}
