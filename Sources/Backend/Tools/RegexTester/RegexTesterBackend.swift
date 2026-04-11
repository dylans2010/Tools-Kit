import Foundation

struct RegexFlags {
    var caseInsensitive: Bool = false
    var multiline: Bool = false
}

class RegexTesterBackend: ObservableObject {
    @Published var pattern = ""
    @Published var testText = ""
    @Published var matches: [String] = []
    @Published var captureGroups: [[String]] = []
    @Published var replacement: String = ""
    @Published var replacedText: String = ""
    @Published var flags: RegexFlags = RegexFlags()

    func findMatches() {
        guard !pattern.isEmpty, !testText.isEmpty else {
            matches = []
            captureGroups = []
            return
        }

        do {
            var options: NSRegularExpression.Options = []
            if flags.caseInsensitive { options.insert(.caseInsensitive) }
            if flags.multiline { options.insert(.anchorsMatchLines) }

            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let nsText = testText as NSString
            let results = regex.matches(in: testText, options: [], range: NSRange(location: 0, length: nsText.length))

            matches = results.map { nsText.substring(with: $0.range) }
            captureGroups = results.map { result in
                (1..<result.numberOfRanges).map { i in
                    let range = result.range(at: i)
                    return range.location != NSNotFound ? nsText.substring(with: range) : ""
                }
            }
        } catch {
            matches = ["Invalid Regex Pattern: \(error.localizedDescription)"]
            captureGroups = []
        }
    }

    func replace() {
        guard !pattern.isEmpty, !testText.isEmpty else {
            replacedText = testText
            return
        }

        do {
            var options: NSRegularExpression.Options = []
            if flags.caseInsensitive { options.insert(.caseInsensitive) }
            if flags.multiline { options.insert(.anchorsMatchLines) }

            let regex = try NSRegularExpression(pattern: pattern, options: options)
            replacedText = regex.stringByReplacingMatches(
                in: testText,
                options: [],
                range: NSRange(testText.startIndex..., in: testText),
                withTemplate: replacement
            )
        } catch {
            replacedText = "Invalid Regex Pattern: \(error.localizedDescription)"
        }
    }
}
