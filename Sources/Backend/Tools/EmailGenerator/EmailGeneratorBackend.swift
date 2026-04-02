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

    func generate() {
        let recipient = recipientName.isEmpty ? "[Recipient Name]" : recipientName
        let sender = senderName.isEmpty ? "[Your Name]" : senderName
        let context = contextInfo.isEmpty ? "[Context]" : contextInfo

        var template = ""

        switch selectedType {
        case .jobApplication:
            if selectedTone == .professional {
                template = "Dear \(recipient),\n\nI am writing to formally apply for the position mentioned in \(context). With my background in the industry, I am confident I would be a great fit for your team.\n\nBest regards,\n\(sender)"
            } else if selectedTone == .casual {
                template = "Hi \(recipient),\n\nI saw the opening for the position and wanted to reach out. I've done a lot of work with \(context) and would love to chat about how I can help.\n\nThanks,\n\(sender)"
            } else {
                template = "To the Hiring Manager,\n\nPlease accept this letter as a formal application for the position. My extensive experience with \(context) aligns well with the requirements.\n\nSincerely,\n\(sender)"
            }
        case .meetingRequest:
            template = "Hi \(recipient),\n\nI'd like to schedule a time to discuss \(context). Are you available later this week?\n\nBest,\n\(sender)"
        case .followUp:
            template = "Dear \(recipient),\n\nI'm following up regarding our previous conversation about \(context). Looking forward to hearing from you.\n\nBest,\n\(sender)"
        case .resignation:
            template = "Dear \(recipient),\n\nPlease accept this email as formal notification that I am resigning from my position. My last day will be in two weeks. Thank you for the opportunity to work on \(context).\n\nBest,\n\(sender)"
        case .thankYou:
            template = "Hi \(recipient),\n\nThank you for \(context). I really appreciate the help and look forward to our next steps.\n\nBest,\n\(sender)"
        }

        generatedEmail = template
    }
}
