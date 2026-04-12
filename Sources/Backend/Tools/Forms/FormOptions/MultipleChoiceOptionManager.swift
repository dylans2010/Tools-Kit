import Foundation

struct MultipleChoiceOptionManager: FormOptionManager {
    let type: FormQuestionType = .multipleChoice
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Choose one", type: .multipleChoice, options: ["Option 1", "Option 2"], required: false)
    }
}
