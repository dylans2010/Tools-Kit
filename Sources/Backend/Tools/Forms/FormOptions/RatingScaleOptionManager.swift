import Foundation

struct RatingScaleOptionManager: FormOptionManager, Sendable {
    let type: FormQuestionType = .ratingScale
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Rate your experience", type: .ratingScale, options: [], required: false)
    }

    func normalize(_ question: FormQuestion) -> FormQuestion {
        var normalized = question
        normalized.title = question.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = question.options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if cleaned.count >= 2,
           let min = Int(cleaned[0]),
           let max = Int(cleaned[1]),
           min <= max {
            normalized.options = [String(min), String(max)]
        } else {
            normalized.options = cleaned
        }
        return normalized
    }
}
