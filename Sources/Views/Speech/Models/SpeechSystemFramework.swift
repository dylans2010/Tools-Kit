import Foundation

/// Represents the various interaction features available in the Speech module
public enum SpeechInteractionFeature: String, Codable, CaseIterable {
    case speechInput = "speech_input"
    case textInput = "text_input"
    case backgroundListening = "background_listening"
    case interruptionTrigger = "interruption_trigger"
    case detailedMode = "detailed_mode"
    case conciseMode = "concise_mode"
    case extendedListening = "extended_listening"
}

/// A structure that holds the current interaction context to be sent to the AI
public struct SpeechSystemContext: Codable {
    public let activeFeatures: Set<SpeechInteractionFeature>
    public let timestamp: Date
    public let isInterrupted: Bool
    public let inputType: SpeechInputType

    public init(
        activeFeatures: Set<SpeechInteractionFeature>,
        timestamp: Date = Date(),
        isInterrupted: Bool = false,
        inputType: SpeechInputType
    ) {
        self.activeFeatures = activeFeatures
        self.timestamp = timestamp
        self.isInterrupted = isInterrupted
        self.inputType = inputType
    }
}

public enum SpeechInputType: String, Codable {
    case speech
    case text
}

/// Helper to load the SpeechSystem.md instructions
public struct SpeechSystemInstructions {
    public static var instructions: String {
        guard let url = Bundle.main.url(forResource: "SpeechSystem", withExtension: "md"),
              let content = try? String(contentsOf: url) else {
            return "You are a helpful AI assistant in a speech-first interface. Respond concisely to voice input and more detail to text input."
        }
        return content
    }
}
