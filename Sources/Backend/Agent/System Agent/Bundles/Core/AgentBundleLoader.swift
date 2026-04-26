import Foundation

final class AgentBundleLoader {
    init() {}

    func loadBundle(from url: URL) throws -> AgentBundle {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AgentBundle.self, from: data)
    }
}
