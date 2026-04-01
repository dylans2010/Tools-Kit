import Foundation
class CodeExplainerBackend: ObservableObject {
    @Published var explanation = ""
    func explain() { explanation = "Explanation" }
}
