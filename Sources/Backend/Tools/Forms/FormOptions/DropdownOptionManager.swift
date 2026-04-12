import Foundation

struct DropdownOptionManager: FormOptionManager {
    let type: FormQuestionType = .dropdown
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Select option", type: .dropdown, options: ["Option A", "Option B"], required: false)
    }
}
