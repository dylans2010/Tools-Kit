import Foundation

enum JobApplicationFormTemplate {
    static func build() -> FormDocument {
        FormDocument(
            name: "Job Application",
            description: "Collect applicant details.",
            questions: [
                FormQuestion(title: "Candidate Name", type: .textInput, required: true),
                FormQuestion(title: "Role Applying For", type: .dropdown, options: ["iOS Engineer", "Designer", "Product Manager"], required: true),
                FormQuestion(title: "Upload Portfolio", type: .imageUpload, required: false)
            ],
            accentHexColor: "34C759",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest(createdBy: "Template", createdAt: Date(), appVersion: "1.0", privacyNote: "Contains candidate-provided professional data.")
        )
    }
}
