import Foundation

enum FeedbackFormTemplate: Sendable {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "How satisfied are you?", type: .ratingScale, options: ["1", "5"], required: true),
            FormQuestion(title: "Which area should improve first?", type: .dropdown, options: ["Product quality", "Pricing", "Support", "Delivery speed"], required: true),
            FormQuestion(title: "What should we improve?", type: .textInput, required: false)
        ]

        return FormDocument(
            name: "Customer Feedback",
            description: "Collect product feedback from users.",
            questions: questions,
            accentHexColor: "007AFF",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "No personal data is required by default.",
                templateName: "Customer Feedback",
                tags: ["feedback", "customer", "survey"]
            )
        )
    }
}
