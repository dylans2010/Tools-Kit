import Foundation

struct AgentBundleLoader {
    func decodeBundle(from data: Data) throws -> AgentBundle {
        try JSONDecoder().decode(AgentBundle.self, from: data)
    }

    func encodeBundle(_ bundle: AgentBundle) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bundle)
    }
}
