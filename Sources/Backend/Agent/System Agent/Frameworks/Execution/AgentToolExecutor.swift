import Foundation

struct AgentToolExecutor: Sendable {
    typealias Handler = ([String: String]) async throws -> String

    private var handlers: [String: Handler] = [:]

    mutating func register(tool: String, handler: @escaping Handler) {
        handlers[tool] = handler
    }

    func execute(tool: String, input: [String: String]) async throws -> String {
        guard let handler = handlers[tool] else { throw NSError(domain: "AgentToolExecutor", code: 404) }
        return try await handler(input)
    }
}
