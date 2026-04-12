import Foundation

struct DragDropOptionManager: FormOptionManager {
    let type: FormQuestionType = .dragDrop
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Drag & drop ranking question", type: .dragDrop, options: [], required: false)
    }
}
