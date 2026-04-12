import Foundation

enum FeedbackFormTemplate {
    static func build() -> FormDocument {
        FormDocument(
            name: "Customer Feedback",
            description: "Collect product feedback from users.",
            questions: [
                FormQuestion(title: "How satisfied are you?", type: .ratingScale, options: ["1", "2", "3", "4", "5"], required: true),
                FormQuestion(title: "What should we improve?", type: .textInput, required: false)
            ],
            accentHexColor: "007AFF",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest(createdBy: "Template", createdAt: Date(), appVersion: "1.0", privacyNote: "No personal data is required by default.")
        )
    }
}
