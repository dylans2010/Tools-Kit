import Foundation

public final class AgentConfigurationStore {
    private let userDefaults: UserDefaults
    private let key = "com.tools-kit.agent.configuration"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func save(_ configuration: AgentConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        userDefaults.set(data, forKey: key)
    }

    public func load() -> AgentConfiguration {
        guard let data = userDefaults.data(forKey: key),
              let config = try? JSONDecoder().decode(AgentConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    public func reset() {
        userDefaults.removeObject(forKey: key)
    }
}
