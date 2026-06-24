import Foundation

final class OpenClawGatewayService {
    private let connection: OpenClawGatewayConnection

    init(connection: OpenClawGatewayConnection) {
        self.connection = connection
    }

    func fetchNodes() async throws -> [[String: Any]] {
        let response = try await connection.sendRequest("nodes.list")
        return response.result?.value as? [[String: Any]] ?? []
    }

    func fetchChannels() async throws -> [[String: Any]] {
        let response = try await connection.sendRequest("channels.list")
        return response.result?.value as? [[String: Any]] ?? []
    }

    func fetchModels() async throws -> [[String: Any]] {
        let response = try await connection.sendRequest("models.list")
        return response.result?.value as? [[String: Any]] ?? []
    }

    func fetchSessions() async throws -> [[String: Any]] {
        let response = try await connection.sendRequest("sessions.list")
        return response.result?.value as? [[String: Any]] ?? []
    }

    func getHealth() async throws -> [String: Any] {
        let response = try await connection.sendRequest("health")
        return response.result?.value as? [String: Any] ?? [:]
    }

    func getStatus() async throws -> [String: Any] {
        let response = try await connection.sendRequest("status")
        return response.result?.value as? [String: Any] ?? [:]
    }

    func startAgent(prompt: String, model: String, channel: String) async throws -> String {
        let response = try await connection.sendRequest("agent.start", params: [
            "prompt": prompt,
            "config": [
                "model": model,
                "channel": channel
            ]
        ])
        guard let result = response.result?.value as? [String: Any],
              let sessionId = result["session_id"] as? String else {
            throw OpenClawServiceError.invalidResponse
        }
        return sessionId
    }

    func stopAgent(sessionId: String) async throws {
        _ = try await connection.sendRequest("agent.stop", params: ["session_id": sessionId])
    }

    func identify() async throws {
        _ = try await connection.sendRequest("device.identify")
    }

    func restart() async throws {
        _ = try await connection.sendRequest("system.restart")
    }

    func observeEvents() -> AsyncStream<OpenClawEvent> {
        return AsyncStream { continuation in
            Task {
                for await event in await connection.events() {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}
