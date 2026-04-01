import Foundation
class PromptGeneratorBackend: ObservableObject {
    @Published var prompt = ""
    func generate() { prompt = "Prompt" }
}
