import Foundation
class IdeaGeneratorBackend: ObservableObject {
    @Published var ideas: [String] = []
    func generate() { ideas = ["Idea"] }
}
