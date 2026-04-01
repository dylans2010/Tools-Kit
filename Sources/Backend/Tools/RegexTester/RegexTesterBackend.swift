import Foundation

class RegexTesterBackend: ObservableObject {
    @Published var pattern = ""
    @Published var testText = ""
    @Published var matches: [String] = []

    func findMatches() {
        guard !pattern.isEmpty, !testText.isEmpty else {
            matches = []
            return
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsText = testText as NSString
            let results = regex.matches(in: testText, range: NSRange(location: 0, length: nsText.length))
            matches = results.map { nsText.substring(with: $0.range) }
        } catch {
            matches = ["Invalid Regex Pattern: \(error.localizedDescription)"]
        }
    }
}
