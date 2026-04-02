import Foundation

enum MeetingType: String, CaseIterable {
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

    func generate() {
        let topicStr = topic.isEmpty ? "[Topic]" : topic
        let people = participants.isEmpty ? "[Participants]" : participants

        var template = ""
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)

        template = "MEETING NOTES\n"
        template += "Date: \(dateStr)\n"
        template += "Topic: \(topicStr)\n"
        template += "Attendees: \(people)\n\n"
        template += "AGENDA:\n- Review progress on \(topicStr)\n- Address any blockers\n- Next steps\n\n"

        switch selectedType {
        case .standup:
            template += "KEY UPDATES:\n- [Update 1]\n- [Update 2]\n\n"
        case .brainstorming:
            template += "IDEAS GENERATED:\n- [Idea A]\n- [Idea B]\n- [Idea C]\n\n"
        case .clientCall:
            template += "CLIENT FEEDBACK:\n- [Requirement 1]\n- [Requirement 2]\n\n"
        case .technical:
            template += "TECHNICAL DECISIONS:\n- [Decision 1]\n- [Decision 2]\n\n"
        }

        template += "ACTION ITEMS:\n[ ] Follow up on \(topicStr)\n[ ] Assign tasks to \(people.components(separatedBy: ",").first ?? "team")"

        generatedNotes = template
    }
}
