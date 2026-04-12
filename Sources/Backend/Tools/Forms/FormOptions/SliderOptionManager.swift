import Foundation

struct SliderOptionManager: FormOptionManager {
    let type: FormQuestionType = .slider
    func defaultQuestion() -> FormQuestion {
        FormQuestion(title: "Slide value", type: .slider, options: ["0", "100"], required: false)
    }
}
