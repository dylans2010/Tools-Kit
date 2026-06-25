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
        SDKLogStore.shared.log("AFM: Generating response with model \(selectedModelID)", source: "AFMService", level: .info)

        let instructions = systemPrompt.isEmpty ? "You are a helpful assistant." : systemPrompt

        // We create a fresh session for each request to ensure instructions are always applied correctly
        // and to avoid state pollution that might lead to "[]" responses.
        let session = LanguageModelSession(instructions: instructions)

        let response = try await session.respond(to: prompt)
        let content = response.content

        SDKLogStore.shared.log("AFM: Received response of length \(content.count)", source: "AFMService", level: .info)

        // If the model literally returns "[]", it's often a sign of a failed task or restricted content
        if content.trimmingCharacters(in: .whitespacesAndNewlines) == "[]" {
            SDKLogStore.shared.log("AFM: Received bracketed empty response. Likely model refusal or error.", source: "AFMService", level: .warning)
            // Instead of returning "[]", we throw a more descriptive error or could return a fallback message.
            throw NSError(domain: "AFMService", code: 503, userInfo: [NSLocalizedDescriptionKey: "Apple Foundation Model returned an empty result. Please try rephrasing your request."])
        }

        return content
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
