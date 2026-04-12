import Foundation

struct MultipleChoiceOptionManager: FormOptionManager {
    let type: FormQuestionType = .multipleChoice
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Select an option", type: .multipleChoice, options: [], required: false)
    }
}
