import Foundation
import Combine

/// Manages active agent sessions and polling.
final class AgentSessionManager: ObservableObject {
    @Published var activeSessions: [AgentSession] = []
    @Published var activities: [String: [AgentActivity]] = [:]
    @Published var sessionStates: [String: AgentSessionState] = [:]
    @Published var isLoading = false

    private var pollingTasks: [String: Task<Void, Never>] = [:]

    static let shared = AgentSessionManager()
    private init() {}

    func startSession(prompt: String, owner: String, repo: String, branch: String? = nil) async throws -> AgentSession {
        let sourceName = try await AgentClient.shared.resolveGitHubSource(owner: owner, repo: repo)
        let session = try await AgentClient.shared.createSession(prompt: prompt, source: sourceName, branch: branch)

        await MainActor.run {
            self.activeSessions.insert(session, at: 0)
        }

        startPolling(sessionId: session.id)
        return session
    }

    func fetchSessions() async {
        isLoading = true
        do {
            let sessions = try await AgentClient.shared.listSessions()
            await MainActor.run {
                self.activeSessions = sessions
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }

    func startPolling(sessionId: String) {
        guard pollingTasks[sessionId] == nil else { return }

        pollingTasks[sessionId] = Task {
            while !Task.isCancelled {
                await refreshSession(sessionId: sessionId)

                // Check if completed
                let isDone = activities[sessionId]?.contains(where: { $0.sessionCompleted != nil }) == true ||
                             activeSessions.first(where: { $0.id == sessionId })?.outputs?.contains(where: { $0.pullRequest != nil }) == true

                if isDone {
                    break
                }

                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000) // Poll every 5 seconds
            }
            pollingTasks[sessionId] = nil
        }
    }

    func refreshSession(sessionId: String) async {
        do {
            let session = try await AgentClient.shared.getSession(id: sessionId)
            let sessionActivities = try await AgentClient.shared.fetchActivities(sessionId: sessionId)

            await MainActor.run {
                if let index = self.activeSessions.firstIndex(where: { $0.id == sessionId }) {
                    self.activeSessions[index] = session
                } else {
                    self.activeSessions.insert(session, at: 0)
                }
                self.activities[sessionId] = sessionActivities

                let workspaceId = session.sourceContext.source.components(separatedBy: "/").last ?? "unknown"
                let state = self.sessionStates[sessionId] ?? AgentSessionState(sessionId: sessionId, workspaceId: workspaceId)
                state.update(with: sessionActivities)
                self.sessionStates[sessionId] = state
            }
        } catch {
            // Log error or handle
        }
    }

    func stopPolling(sessionId: String) {
        pollingTasks[sessionId]?.cancel()
        pollingTasks.removeValue(forKey: sessionId)
    }

    deinit {
        pollingTasks.values.forEach { $0.cancel() }
    }
}
