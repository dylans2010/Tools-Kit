import Foundation

final class AgentConfigurationStore {
    private let userDefaults: UserDefaults
    private let key = "com.tools-kit.agent.configuration"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(_ configuration: AgentConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        userDefaults.set(data, forKey: key)
    }

    func load() -> AgentConfiguration {
        guard let data = userDefaults.data(forKey: key),
              let config = try? JSONDecoder().decode(AgentConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    func reset() {
        userDefaults.removeObject(forKey: key)
    }
}
