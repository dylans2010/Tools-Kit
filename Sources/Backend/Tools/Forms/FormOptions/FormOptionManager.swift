import Foundation

protocol FormOptionManager {
    var type: FormQuestionType { get }
    func defaultQuestion() -> FormQuestion
}
