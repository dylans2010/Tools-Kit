import Foundation
class TextRewriterBackend: ObservableObject {
    @Published var rewritten = ""
    func rewrite() { rewritten = "Rewritten" }
}
