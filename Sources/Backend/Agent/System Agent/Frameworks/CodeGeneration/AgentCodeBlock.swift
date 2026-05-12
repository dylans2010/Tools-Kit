import Foundation

struct AgentCodeBlock: Codable, Sendable {
    var language: String
    var code: String

    init(language: String, code: String) {
        self.language = language
        self.code = code
    }

    var lineCount: Int { max(code.split(separator: "\n", omittingEmptySubsequences: false).count, 1) }
}
