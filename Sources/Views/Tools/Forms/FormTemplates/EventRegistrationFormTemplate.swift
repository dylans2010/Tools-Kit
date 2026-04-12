import Foundation

enum EventRegistrationFormTemplate {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "Full Name", type: .textInput, required: true),
            FormQuestion(title: "Email Address", type: .textInput, required: true),
            FormQuestion(title: "Ticket Type", type: .dropdown, options: ["Standard", "VIP", "Student", "Speaker"], required: true),
            FormQuestion(title: "Need accessibility support?", type: .multipleChoice, options: ["Yes", "No"], required: true),
            FormQuestion(title: "Session preference order", type: .dragDrop, options: ["iOS Architecture", "SwiftUI Deep Dive", "Testing Strategy", "Release Pipeline"], required: false)
        ]

        FormDocument(
            name: "Event Registration",
            description: "Capture attendees for an event.",
            questions: questions,
            accentHexColor: "AF52DE",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "Use only for event logistics.",
                templateName: "Event Registration",
                tags: ["event", "registration"]
            )
        )
    }
}
