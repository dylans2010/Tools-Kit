import Foundation

enum JobApplicationFormTemplate {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "Candidate Name", type: .textInput, required: true),
            FormQuestion(title: "Email Address", type: .textInput, required: true),
            FormQuestion(title: "Role Applying For", type: .dropdown, options: ["iOS Engineer", "Backend Engineer", "Designer", "Product Manager"], required: true),
            FormQuestion(title: "Years of Experience", type: .slider, options: ["0", "20", "1"], required: true),
            FormQuestion(title: "Upload Portfolio", type: .imageUpload, required: false)
        ]

        return FormDocument(
            name: "Job Application",
            description: "Collect applicant details.",
            questions: questions,
            accentHexColor: "34C759",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "Contains candidate-provided professional data.",
                templateName: "Job Application",
                tags: ["hiring", "application"]
            )
        )
    }
}
