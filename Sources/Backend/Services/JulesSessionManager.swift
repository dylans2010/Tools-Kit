import Foundation
import Combine

/// Manages active Jules sessions and coordinates Agent Mode tasks.
final class JulesSessionManager: ObservableObject {
    nonisolated(unsafe) static let shared = JulesSessionManager()

    @Published var activeSessions: [JulesProvider.Session] = []
    @Published var isRequesting = false

    private let provider = JulesProvider()
    private let keyManager = APIKeyManager.shared

    private var apiKey: String {
        return keyManager.getKey(for: "jules") ?? ""
    }

    func startSession(prompt: String, source: String? = nil) async throws -> JulesProvider.Session {
        await MainActor.run { isRequesting = true }
        defer { Task { @MainActor in isRequesting = false } }

        let session = try await provider.createSession(prompt: prompt, source: source, apiKey: apiKey)

        await MainActor.run {
            activeSessions.append(session)
        }

        return session
    }

    func refreshSessions() async throws {
        // Jules API listSessions implementation would go here
    }

    func approvePlan(sessionID: String) async throws {
        try await provider.approvePlan(sessionID: sessionID, apiKey: apiKey)
    }
}
