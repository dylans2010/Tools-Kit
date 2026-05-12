import Foundation

struct TextInputOptionManager: FormOptionManager, Sendable {
    let type: FormQuestionType = .textInput
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Short answer", type: .textInput, options: [], required: false)
    }
}

