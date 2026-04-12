import Foundation

enum CourseEvaluationFormTemplate {
    static func build() -> FormDocument {
        let questions = [
            FormQuestion(title: "Course Name", type: .textInput, required: true),
            FormQuestion(title: "Instructor", type: .textInput, required: true),
            FormQuestion(title: "Content quality", type: .ratingScale, options: ["1", "10"], required: true),
            FormQuestion(title: "Pace", type: .slider, options: ["1", "10", "1"], required: true),
            FormQuestion(title: "Most useful modules", type: .dragDrop, options: ["Foundations", "Hands-on Labs", "Case Studies", "Q&A"], required: false),
            FormQuestion(title: "Would you recommend this course?", type: .multipleChoice, options: ["Yes", "No"], required: true),
            FormQuestion(title: "Additional comments", type: .textInput, required: false)
        ]

        return FormDocument(
            name: "Course Evaluation",
            description: "Collect post-course learner feedback.",
            questions: questions,
            accentHexColor: "FF9500",
            backgroundHexColor: "F2F2F7",
            manifest: FormManifest.compose(
                creatorName: "Template",
                questions: questions,
                privacyNote: "Keep feedback constructive and avoid personal private information.",
                templateName: "Course Evaluation",
                tags: ["education", "evaluation", "feedback"]
            )
        )
    }
}
