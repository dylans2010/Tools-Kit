import Foundation

struct SliderOptionManager: FormOptionManager {
    let type: FormQuestionType = .slider
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Select a value", type: .slider, options: [], required: false)
    }

    func normalize(_ question: FormQuestion) -> FormQuestion {
        var normalized = question
        normalized.title = question.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = question.options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let min = Double(cleaned.first ?? "") ?? 0
        let maxCandidate = Double(cleaned.count > 1 ? cleaned[1] : "") ?? 100
        let maxValue = Swift.max(min, maxCandidate)
        let step = Swift.max(0.1, Double(cleaned.count > 2 ? cleaned[2] : "") ?? 1)
        normalized.options = [String(min), String(maxValue), String(step)]
        return normalized
    }
}
