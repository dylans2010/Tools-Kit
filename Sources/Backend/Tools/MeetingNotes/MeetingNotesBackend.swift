import Foundation

enum MeetingType: String, CaseIterable, Sendable {
    case standup = "Standup"
    case brainstorming = "Brainstorming"
    case clientCall = "Client Call"
    case technical = "Technical Review"
}

class MeetingNotesBackend: ObservableObject {
    @Published var topic = ""
    @Published var participants = ""
    @Published var generatedNotes = ""
    @Published var selectedType: MeetingType = .standup
    @Published var isProcessing = false

    @MainActor
    func generate() async {
        isProcessing = true
        defer { isProcessing = false }

        let topicStr = topic.isEmpty ? "[Topic]" : topic
        let people = participants.isEmpty ? "[Participants]" : participants

        let prompt = """
        Create structured meeting notes.
        Type: \(selectedType.rawValue)
        Topic: \(topicStr)
        Participants: \(people)
        Include sections for agenda, highlights, decisions, risks, and action items with owners.
        """

        do {
            generatedNotes = try await AIService.shared.generateResponse(prompt: prompt)
        } catch {
            generatedNotes = "Failed to generate notes: \(error.localizedDescription)"
        }
    }
}
