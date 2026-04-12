import Foundation

struct MultipleChoiceOptionManager: FormOptionManager {
    let type: FormQuestionType = .multipleChoice
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Multiple choice question", type: .multipleChoice, options: [], required: false)
    }
}
