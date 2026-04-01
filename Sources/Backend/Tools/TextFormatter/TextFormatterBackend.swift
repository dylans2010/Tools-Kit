import Foundation
class TextFormatterBackend: ObservableObject {
    @Published var text = ""
    func uppercase() { text = text.uppercased() }
}
