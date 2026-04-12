import Foundation

enum OrderIntakeFormTemplate {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "Customer Name", type: .textInput, required: true),
            FormQuestion(title: "Order Channel", type: .dropdown, options: ["Website", "Phone", "Retail", "Partner"], required: true),
            FormQuestion(title: "Order urgency", type: .ratingScale, options: ["1", "5"], required: true),
            FormQuestion(title: "Requested quantity", type: .slider, options: ["1", "500", "1"], required: true),
            FormQuestion(title: "Requested product mix", type: .dragDrop, options: ["Core SKU", "Accessories", "Add-ons", "Service plan"], required: false),
            FormQuestion(title: "Special instructions", type: .textInput, required: false)
        ]

        return FormDocument(
            name: "Order Intake",
            description: "Capture order requirements for fulfillment review.",
            questions: questions,
            accentHexColor: "30B0C7",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "Only collect operational order details needed for fulfillment.",
                templateName: "Order Intake",
                tags: ["operations", "order", "intake"]
            )
        )
    }
}
