import Foundation

struct DropdownOptionManager: FormOptionManager, Sendable {
    let type: FormQuestionType = .dropdown
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Select an option", type: .dropdown, options: [], required: false)
    }
}
