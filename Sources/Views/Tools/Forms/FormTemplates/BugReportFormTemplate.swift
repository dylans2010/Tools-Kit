import Foundation

enum BugReportFormTemplate: Sendable {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "Bug title", type: .textInput, required: true),
            FormQuestion(title: "Environment", type: .dropdown, options: ["Production", "Staging", "Development"], required: true),
            FormQuestion(title: "Severity", type: .ratingScale, options: ["1", "5"], required: true),
            FormQuestion(title: "Steps to reproduce", type: .textInput, required: true),
            FormQuestion(title: "Expected behavior", type: .textInput, required: true),
            FormQuestion(title: "Observed behavior", type: .textInput, required: true),
            FormQuestion(title: "Screenshot evidence", type: .imageUpload, required: false)
        ]

        return FormDocument(
            name: "Bug Report",
            description: "Capture reproducible bug reports with severity and evidence.",
            questions: questions,
            accentHexColor: "FF3B30",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "Do not include credentials or sensitive personal data in bug reports.",
                templateName: "Bug Report",
                tags: ["engineering", "bug", "quality"]
            )
        )
    }
}
