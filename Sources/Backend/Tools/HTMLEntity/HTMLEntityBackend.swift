import Foundation

final class HTMLEntityBackend: ObservableObject {
    @Published var output: String = ""

    func encode(_ text: String) {
        // Simple manual encoding for demonstration
        self.output = text.replacingOccurrences(of: "<", with: "&lt;")
                         .replacingOccurrences(of: ">", with: "&gt;")
    }

    func decode(_ text: String) {
        self.output = text.replacingOccurrences(of: "&lt;", with: "<")
                         .replacingOccurrences(of: "&gt;", with: ">")
    }
}
