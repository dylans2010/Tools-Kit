import Foundation

struct DragDropOptionManager: FormOptionManager {
    let type: FormQuestionType = .dragDrop
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Drag and drop order", type: .dragDrop, options: ["Item 1", "Item 2"], required: false)
    }
}
