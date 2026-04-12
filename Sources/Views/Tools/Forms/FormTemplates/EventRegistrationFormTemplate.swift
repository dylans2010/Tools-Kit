import Foundation

enum EventRegistrationFormTemplate {
    static func build() -> FormDocument {
        FormDocument(
            name: "Event Registration",
            description: "Capture attendees for an event.",
            questions: [
                FormQuestion(title: "Full Name", type: .textInput, required: true),
                FormQuestion(title: "Ticket Type", type: .dropdown, options: ["Standard", "VIP"], required: true),
                FormQuestion(title: "Need accessibility support?", type: .multipleChoice, options: ["Yes", "No"], required: true)
            ],
            accentHexColor: "AF52DE",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest(createdBy: "Template", createdAt: Date(), appVersion: "1.0", privacyNote: "Use only for event logistics.")
        )
    }
}
