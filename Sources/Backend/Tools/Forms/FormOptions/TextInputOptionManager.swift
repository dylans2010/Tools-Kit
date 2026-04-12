import Foundation

struct TextInputOptionManager: FormOptionManager {
    let type: FormQuestionType = .textInput
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Short answer", type: .textInput, options: [], required: false)
    }
}

