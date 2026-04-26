import Foundation

struct AgentConfiguration: Codable {
    var toolExecutionTimeout: TimeInterval = 20
    var maxToolIterations: Int = 10
    var streamingEnabled: Bool = true

    static let `default` = AgentConfiguration()
}
