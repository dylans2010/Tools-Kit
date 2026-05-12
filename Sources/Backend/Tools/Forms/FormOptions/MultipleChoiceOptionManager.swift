import Foundation

struct MultipleChoiceOptionManager: FormOptionManager, Sendable {
    let type: FormQuestionType = .multipleChoice
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Select an option", type: .multipleChoice, options: [], required: false)
    }
}
