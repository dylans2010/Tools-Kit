import Foundation

struct DragDropOptionManager: FormOptionManager, Sendable {
    let type: FormQuestionType = .dragDrop
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Drag & drop ranking question", type: .dragDrop, options: [], required: false)
    }
}
