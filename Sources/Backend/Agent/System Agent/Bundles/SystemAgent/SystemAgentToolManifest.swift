import Foundation

struct SystemAgentToolManifest: Codable {
    var tools: [String]

    init(tools: [String] = []) {
        self.tools = Array(Set(tools)).sorted()
    }

    func contains(tool: String) -> Bool {
        tools.contains(tool)
    }
}
