import Foundation

struct DropdownOptionManager: FormOptionManager {
    let type: FormQuestionType = .dropdown
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Dropdown question", type: .dropdown, options: [], required: false)
    }
}
