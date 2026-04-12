import Foundation

protocol FormOptionManager {
    var type: FormQuestionType { get }
    func defaultQuestion() -> FormQuestion
    func normalize(_ question: FormQuestion) -> FormQuestion
}

extension FormOptionManager {
    func normalize(_ question: FormQuestion) -> FormQuestion {
        var normalized = question
        normalized.title = question.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.options = question.options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return normalized
    }
}
