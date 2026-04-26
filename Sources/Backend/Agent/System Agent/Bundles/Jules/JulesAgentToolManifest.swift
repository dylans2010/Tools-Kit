import Foundation

struct JulesAgentToolManifest: Codable {
    var tools: [String]

    init(tools: [String] = ["summarize", "refactor"]) {
        self.tools = tools
    }

    var canonicalTools: [String] { Array(Set(tools)).sorted() }
}
