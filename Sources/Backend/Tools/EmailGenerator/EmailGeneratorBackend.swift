import Foundation

enum EmailType: String, CaseIterable {
    case jobApplication = "Job Application"
    case meetingRequest = "Meeting Request"
    case followUp = "Follow-up"
    case resignation = "Resignation"
    case thankYou = "Thank You"
}

enum EmailTone: String, CaseIterable {
    case professional = "Professional"
    case casual = "Casual"
    case formal = "Formal"
}

class EmailGeneratorBackend: ObservableObject {
    @Published var generatedEmail = ""
    @Published var recipientName = ""
    @Published var senderName = ""
    @Published var contextInfo = ""
    @Published var selectedType: EmailType = .jobApplication
    @Published var selectedTone: EmailTone = .professional
    @Published var isProcessing = false

    @MainActor
    func generate() async {
        isProcessing = true
        defer { isProcessing = false }

        let recipient = recipientName.isEmpty ? "[Recipient Name]" : recipientName
        let sender = senderName.isEmpty ? "[Your Name]" : senderName
        let context = contextInfo.isEmpty ? "[Context]" : contextInfo

        let prompt = """
        Write a \(selectedTone.rawValue.lowercased()) \(selectedType.rawValue.lowercased()) email.
        Recipient: \(recipient)
        Sender: \(sender)
        Context: \(context)
        Keep it polished and ready to send.
        """

        do {
            generatedEmail = try await AIService.shared.generateResponse(prompt: prompt)
        } catch {
            generatedEmail = "Failed to generate email: \(error.localizedDescription)"
        }
    }
}
