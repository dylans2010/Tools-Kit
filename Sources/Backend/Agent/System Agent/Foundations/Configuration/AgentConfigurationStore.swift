import Foundation

struct AgentConfigurationStore {
    func save(_ configuration: AgentConfiguration, to url: URL) throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: url, options: .atomic)
    }

    func load(from url: URL) throws -> AgentConfiguration {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AgentConfiguration.self, from: data)
    }
}
