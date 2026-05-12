import Foundation
import Combine

/// Compatibility facade over AgentSessionFramework + AgentSessionStore.
final class AgentSessionManager: ObservableObject {
    @Published var activeSessions: [AgentSession] = []
    @Published var activities: [String: [AgentActivity]] = [:]
    @Published var sessionStates: [String: AgentSessionState] = [:]
    @Published var isLoading = false

    private let framework = AgentSessionFramework.shared
    private let store = AgentSessionStore.shared
    private var cancellables = Set<AnyCancellable>()

    static let shared = AgentSessionManager()

    private init() {
        store.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                self?.sessionStates = states
                self?.activeSessions = states.values.compactMap(\.session).sorted(by: { $0.id > $1.id })
            }
            .store(in: &cancellables)
    }

    func startSession(prompt: String, owner: String, repo: String, branch: String? = nil) async throws -> AgentSession {
        let session = try await framework.startSession(prompt: prompt, owner: owner, repo: repo, branch: branch)
        await MainActor.run {
            if !activeSessions.contains(where: { $0.id == session.id }) {
                activeSessions.insert(session, at: 0)
            }
        }
        return session
    }

    func fetchSessions() async {
        await MainActor.run { isLoading = true }
        await framework.fetchSessions()
        await MainActor.run { isLoading = false }
    }

    func startPolling(sessionId: String) {
        guard sessionStates[sessionId] != nil || activeSessions.contains(where: { $0.id == sessionId }) else {
            return
        }
        framework.startPolling(sessionId: sessionId)
    }

    func refreshSession(sessionId: String) async {
        await framework.refreshSession(sessionId: sessionId)
    }

    func stopPolling(sessionId: String) {
        framework.stopPolling(sessionId: sessionId)
    }
}
