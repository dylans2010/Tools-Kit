import Foundation

struct ImageUploadOptionManager: FormOptionManager, Sendable {
    let type: FormQuestionType = .imageUpload
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Upload image", type: .imageUpload, options: [], required: false)
    }
}
