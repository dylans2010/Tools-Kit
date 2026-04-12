import Foundation

enum ITServiceRequestFormTemplate {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "Requester Name", type: .textInput, required: true),
            FormQuestion(title: "Department", type: .dropdown, options: ["Engineering", "Operations", "Sales", "HR", "Finance"], required: true),
            FormQuestion(title: "Request Type", type: .dropdown, options: ["Hardware", "Software", "Access", "Network", "Account Reset"], required: true),
            FormQuestion(title: "Priority", type: .ratingScale, options: ["1", "5"], required: true),
            FormQuestion(title: "Preferred fulfillment order", type: .dragDrop, options: ["Today", "This week", "This month"], required: false),
            FormQuestion(title: "Request details", type: .textInput, required: true)
        ]

        return FormDocument(
            name: "IT Service Request",
            description: "Track internal IT support and provisioning requests.",
            questions: questions,
            accentHexColor: "5856D6",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "Use internal identifiers only; avoid sharing private credentials.",
                templateName: "IT Service Request",
                tags: ["internal", "it", "support"]
            )
        )
    }
}
