import Foundation

struct RatingScaleOptionManager: FormOptionManager {
    let type: FormQuestionType = .ratingScale
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Rate from 1 to 5", type: .ratingScale, options: ["1", "2", "3", "4", "5"], required: false)
    }
}
