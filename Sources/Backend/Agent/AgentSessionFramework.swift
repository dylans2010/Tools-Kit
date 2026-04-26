import Foundation
import Combine

final class AgentEventBus {
    static let shared = AgentEventBus()

    private let subject = PassthroughSubject<AgentExecutionEvent, Never>()

    var publisher: AnyPublisher<AgentExecutionEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ event: AgentExecutionEvent) {
        subject.send(event)
    }
}

final class AgentExecutionEngine {
    static let shared = AgentExecutionEngine()

    func convert(session: AgentSession, activities: [AgentActivity], previousActivityIds: Set<String>) -> [AgentExecutionEvent] {
        var events: [AgentExecutionEvent] = []

        if previousActivityIds.isEmpty {
            events.append(
                AgentExecutionEvent(
                    sessionId: session.id,
                    timestamp: Date(),
                    type: .sessionStarted,
                    title: "Session Started",
                    message: session.title ?? session.prompt ?? "Agent execution started",
                    payload: ["session_name": AnyCodable(session.name)]
                )
            )
        }

        let freshActivities = activities
            .filter { !previousActivityIds.contains($0.id) }
            .sorted { $0.createTime < $1.createTime }

        for activity in freshActivities {
            if let plan = activity.planGenerated?.plan {
                for step in plan.steps.sorted(by: { ($0.index ?? 0) < ($1.index ?? 0) }) {
                    events.append(
                        AgentExecutionEvent(
                            sessionId: session.id,
                            timestamp: activity.createTime,
                            type: .checklistUpdated,
                            stepId: step.id,
                            title: step.title,
                            message: "Checklist step added",
                            payload: [
                                "checklist_id": AnyCodable(step.id),
                                "checklist_status": AnyCodable("pending"),
                                "checklist_details": AnyCodable("Planned for execution")
                            ]
                        )
                    )
                }
            }

            if let progress = activity.progressUpdated {
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: activity.createTime,
                        type: .stepProgress,
                        title: progress.title ?? "Progress",
                        message: progress.description ?? "Agent reported progress",
                        payload: [:]
                    )
                )
            }

            if let timeline = activity.timelineUpdated {
                let eventType: AgentExecutionEventType = timeline.status == "in_progress" ? .stepStarted : .stepProgress
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: timeline.timestamp,
                        type: eventType,
                        stepId: timeline.id,
                        title: timeline.step,
                        message: "Step \(timeline.step) is \(timeline.status)",
                        payload: [
                            "step_status": AnyCodable(timeline.status),
                            "step_name": AnyCodable(timeline.step)
                        ]
                    )
                )
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: timeline.timestamp,
                        type: .checklistUpdated,
                        stepId: timeline.id,
                        title: timeline.step,
                        message: "Checklist step \(timeline.status)",
                        payload: [
                            "checklist_id": AnyCodable(timeline.id),
                            "checklist_status": AnyCodable(timeline.status),
                            "checklist_details": AnyCodable("Updated from Jules timeline")
                        ]
                    )
                )
            }

            if let tool = activity.toolExecuted {
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: activity.createTime,
                        type: .logOutput,
                        title: "Tool: \(tool.tool)",
                        message: "Status: \(tool.status)",
                        payload: [
                            "tool": AnyCodable(tool.tool),
                            "status": AnyCodable(tool.status),
                            "request_id": AnyCodable(tool.requestId)
                        ]
                    )
                )
                if tool.tool.hasPrefix("system_") || tool.tool.contains("_file") || tool.tool.contains("git") {
                    events.append(
                        AgentExecutionEvent(
                            sessionId: session.id,
                            timestamp: activity.createTime,
                            type: .checklistUpdated,
                            title: "Tool: \(tool.tool)",
                            message: "Tool \(tool.status)",
                            payload: [
                                "checklist_id": AnyCodable("tool-\(tool.requestId)"),
                                "checklist_status": AnyCodable(tool.status),
                                "checklist_details": AnyCodable("Executed via SystemTools")
                            ]
                        )
                    )
                }

                if tool.tool.contains("git") || ["branch_create", "branch_switch", "commit_changes", "merge_branch", "revert_commit"].contains(tool.tool) {
                    events.append(
                        AgentExecutionEvent(
                            sessionId: session.id,
                            timestamp: activity.createTime,
                            type: .gitOperation,
                            title: "Git Operation",
                            message: "\(tool.tool) \(tool.status)",
                            payload: ["tool": AnyCodable(tool.tool), "status": AnyCodable(tool.status)]
                        )
                    )
                }

                if tool.tool.contains("workflow") {
                    events.append(
                        AgentExecutionEvent(
                            sessionId: session.id,
                            timestamp: activity.createTime,
                            type: .workflowTriggered,
                            title: "Workflow Trigger",
                            message: "\(tool.tool) \(tool.status)",
                            payload: ["tool": AnyCodable(tool.tool), "status": AnyCodable(tool.status)]
                        )
                    )
                }
            }

            if let diff = activity.diffGenerated {
                let classification: AgentExecutionEventType = diff.diff.contains("new file") ? .fileGenerated : .fileUpdated
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: activity.createTime,
                        type: classification,
                        title: diff.filePath,
                        message: classification == .fileGenerated ? "Generated file" : "Updated file",
                        payload: [
                            "file_path": AnyCodable(diff.filePath),
                            "patch": AnyCodable(diff.diff)
                        ]
                    )
                )
            }

            if let _ = activity.sessionCompleted {
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: activity.createTime,
                        type: .sessionCompleted,
                        title: "Session Completed",
                        message: "Execution completed successfully",
                        payload: [:]
                    )
                )
                events.append(
                    AgentExecutionEvent(
                        sessionId: session.id,
                        timestamp: activity.createTime,
                        type: .checklistUpdated,
                        title: "Session Finalization",
                        message: "All checklist items completed",
                        payload: [
                            "checklist_id": AnyCodable("session-finalization"),
                            "checklist_status": AnyCodable("completed"),
                            "checklist_details": AnyCodable("Jules marked session complete")
                        ]
                    )
                )
            }
        }

        if let pr = session.outputs?.first(where: { $0.pullRequest != nil })?.pullRequest {
            events.append(
                AgentExecutionEvent(
                    sessionId: session.id,
                    timestamp: Date(),
                    type: .sessionCompleted,
                    title: pr.title ?? "Pull Request Ready",
                    message: pr.url,
                    payload: ["pull_request": AnyCodable(pr.url)]
                )
            )
        }

        return dedupe(events)
    }

    private func dedupe(_ events: [AgentExecutionEvent]) -> [AgentExecutionEvent] {
        var seen = Set<String>()
        return events.filter { event in
            let key = "\(event.sessionId)|\(event.type.rawValue)|\(event.timestamp.timeIntervalSince1970)|\(event.title)|\(event.message)"
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}

final class AgentSessionStore: ObservableObject {
    static let shared = AgentSessionStore()

    @Published private(set) var states: [String: AgentSessionState] = [:]
    @Published private(set) var orderedSessionIDs: [String] = []

    private let storageURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = base.appendingPathComponent("AgentSessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        self.storageURL = folder.appendingPathComponent("sessions.json")
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        restore()
    }

    var allStates: [AgentSessionState] {
        orderedSessionIDs.compactMap { states[$0] }
    }

    func state(for sessionId: String) -> AgentSessionState? {
        states[sessionId]
    }

    func upsertSession(_ session: AgentSession, workspaceId: String) {
        let existing = states[session.id] ?? AgentSessionState(sessionId: session.id, workspaceId: workspaceId)
        existing.session = session
        states[session.id] = existing
        if !orderedSessionIDs.contains(session.id) {
            orderedSessionIDs.insert(session.id, at: 0)
        }
        persist()
    }

    func ingest(event: AgentExecutionEvent, debugSnapshot: AgentDebugSnapshot?) {
        let state = states[event.sessionId] ?? AgentSessionState(sessionId: event.sessionId, workspaceId: "unknown")
        state.apply(event: event, debugSnapshot: debugSnapshot)
        states[event.sessionId] = state
        if !orderedSessionIDs.contains(event.sessionId) {
            orderedSessionIDs.insert(event.sessionId, at: 0)
        }
        persist()
    }

    private struct Persisted: Codable {
        let orderedSessionIDs: [String]
        let states: [String: AgentSessionState.PersistenceModel]
    }

    private func persist() {
        let model = Persisted(
            orderedSessionIDs: orderedSessionIDs,
            states: states.mapValues { $0.persistenceModel }
        )
        guard let data = try? encoder.encode(model) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func restore() {
        guard let data = try? Data(contentsOf: storageURL),
              let persisted = try? decoder.decode(Persisted.self, from: data) else { return }

        orderedSessionIDs = persisted.orderedSessionIDs
        states = persisted.states.mapValues { AgentSessionState(model: $0) }
    }
}

final class AgentSessionFramework {
    enum LifecycleStatus: String {
        case created
        case queued
        case running
        case completed
        case failed
        case unknown
    }

    struct SessionTrackingRecord {
        let sessionId: String
        let taskId: String?
        let repositoryURL: String
        var status: LifecycleStatus
        var lastKnownServerState: String
        var lastUpdated: Date
        var expiresAt: Date
        var consecutiveNotFoundCount: Int
        var consecutiveValidationFailures: Int

        var isExpired: Bool { Date() > expiresAt }
    }

    static let shared = AgentSessionFramework()

    private let client: AgentClient
    private let engine: AgentExecutionEngine
    private let eventBus: AgentEventBus
    private let store: AgentSessionStore

    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private var seenActivityIDs: [String: Set<String>] = [:]
    private var trackingRecords: [String: SessionTrackingRecord] = [:]
    private var pendingSessionRequests: [String: (prompt: String, owner: String, repo: String, branch: String?)] = [:]
    private var cancellables = Set<AnyCancellable>()

    private let maxConsecutiveNotFound = 3
    private let maxValidationFailures = 2

    private init(
        client: AgentClient = .shared,
        engine: AgentExecutionEngine = .shared,
        eventBus: AgentEventBus = .shared,
        store: AgentSessionStore = .shared
    ) {
        self.client = client
        self.engine = engine
        self.eventBus = eventBus
        self.store = store

        eventBus.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.routeInternalActions(for: event)
            }
            .store(in: &cancellables)

    }

    func startSession(prompt: String, owner: String, repo: String, branch: String?) async throws -> AgentSession {
        let repositoryURL = try validatedRepositoryURL(owner: owner, repo: repo)
        trace("createSession request repo=\(repositoryURL)")

        let session = try await client.createSession(prompt: prompt, owner: owner, repo: repo, branch: branch)
        trace("createSession response session_id=\(session.id)")

        let workspaceId = session.sourceContext.source.components(separatedBy: "/").last ?? "unknown"
        let normalized = normalizedLifecycleStatus(from: session.name)
        let taskId = taskIdentifier(from: session)
        let now = Date()
        let record = SessionTrackingRecord(
            sessionId: session.id,
            taskId: taskId,
            repositoryURL: repositoryURL,
            status: normalized,
            lastKnownServerState: session.name,
            lastUpdated: now,
            expiresAt: now.addingTimeInterval(30 * 60),
            consecutiveNotFoundCount: 0,
            consecutiveValidationFailures: 0
        )

        await MainActor.run {
            store.upsertSession(session, workspaceId: workspaceId)
        }

        trackingRecords[session.id] = record
        pendingSessionRequests[session.id] = (prompt, owner, repo, branch)

        let started = await validateSessionBeforePolling(sessionId: session.id)
        guard started else {
            throw AgentError.apiError("Session \(session.id) failed validation before polling started.")
        }
        return session
    }

    func refreshSession(sessionId: String, debugMode: Bool = false) async {
        guard var record = trackingRecords[sessionId] else {
            trace("refresh skipped, missing tracking record for \(sessionId)")
            await emitLifecycleFailure(sessionId: sessionId, message: "Missing local tracking record. Reinitialize session.")
            return
        }

        guard !record.isExpired else {
            trace("refresh stopped, session expired \(sessionId)")
            await invalidateSession(sessionId: sessionId, reason: "Session tracking expired")
            await attemptRestartIfNeeded(sessionId: sessionId)
            return
        }

        trace("poll request session_id=\(sessionId) status=\(record.status.rawValue)")
        do {
            let session = try await client.getSession(id: sessionId)
            let normalizedStatus = normalizedLifecycleStatus(from: session.name)

            if !isServerStateCompatible(local: record, with: session, normalized: normalizedStatus) {
                trace("state mismatch session_id=\(sessionId) local=\(record.lastKnownServerState) remote=\(session.name)")
                await invalidateSession(sessionId: sessionId, reason: "Server state mismatch")
                await attemptRestartIfNeeded(sessionId: sessionId)
                return
            }

            let activities = (try? await client.fetchActivities(sessionId: sessionId)) ?? []
            let previousIds = seenActivityIDs[sessionId] ?? []
            let events = engine.convert(session: session, activities: activities, previousActivityIds: previousIds)
            seenActivityIDs[sessionId] = Set(activities.map(\.id))

            record.status = normalizedStatus
            record.lastKnownServerState = session.name
            record.lastUpdated = Date()
            record.expiresAt = Date().addingTimeInterval(30 * 60)
            record.consecutiveNotFoundCount = 0
            record.consecutiveValidationFailures = 0
            trackingRecords[sessionId] = record

            let workspaceId = session.sourceContext.source.components(separatedBy: "/").last ?? "unknown"
            await MainActor.run {
                self.store.upsertSession(session, workspaceId: workspaceId)
            }

            await emitLifecycleEvent(sessionId: sessionId, status: normalizedStatus)

            for event in events {
                let debugSnapshot: AgentDebugSnapshot? = debugMode ? AgentDebugSnapshot(
                    rawSession: session,
                    rawActivities: activities,
                    convertedEvents: events,
                    stateTransition: "state=\(normalizedStatus.rawValue) session=\(sessionId)",
                    uiTrigger: "AgentSessionStore published state change",
                    frameworkPhase: "AgentSessionFramework.refreshSession"
                ) : nil

                await MainActor.run {
                    self.store.ingest(event: event, debugSnapshot: debugSnapshot)
                }
                eventBus.publish(event)
            }
        } catch {
            if isNotFoundError(error) {
                record.consecutiveNotFoundCount += 1
                trackingRecords[sessionId] = record
                trace("404 encountered session_id=\(sessionId) count=\(record.consecutiveNotFoundCount) reason=\(error.localizedDescription)")

                if record.consecutiveNotFoundCount >= maxConsecutiveNotFound {
                    await invalidateSession(sessionId: sessionId, reason: "Repeated 404 responses")
                    await attemptRestartIfNeeded(sessionId: sessionId)
                    return
                }
            }

            let failed = AgentExecutionEvent(
                sessionId: sessionId,
                type: .sessionFailed,
                title: "Session Failed",
                message: error.localizedDescription,
                payload: [:]
            )
            await MainActor.run {
                self.store.ingest(event: failed, debugSnapshot: nil)
            }
            eventBus.publish(failed)
        }
    }

    func fetchSessions() async {
        do {
            let sessions = try await client.listSessions()
            await MainActor.run {
                for session in sessions {
                    let workspaceId = session.sourceContext.source.components(separatedBy: "/").last ?? "unknown"
                    self.store.upsertSession(session, workspaceId: workspaceId)
                }
            }
            for session in sessions {
                if var record = trackingRecords[session.id] {
                    record.lastKnownServerState = session.name
                    record.status = normalizedLifecycleStatus(from: session.name)
                    record.lastUpdated = Date()
                    trackingRecords[session.id] = record
                }
            }
        } catch {
            // Keep silent; store already persists last known sessions.
        }
    }

    func startPolling(sessionId: String, intervalSeconds: UInt64 = 3) {
        guard pollingTasks[sessionId] == nil else { return }

        pollingTasks[sessionId] = Task {
            var failureCount = 0
            while !Task.isCancelled {
                let canPoll = await validateSessionBeforePolling(sessionId: sessionId)
                guard canPoll else {
                    failureCount += 1
                    let backoff = UInt64(min(pow(2.0, Double(failureCount)), 30))
                    trace("poll validation failed session_id=\(sessionId) backoff=\(backoff)s")
                    try? await Task.sleep(nanoseconds: backoff * 1_000_000_000)
                    if failureCount >= maxValidationFailures {
                        await attemptRestartIfNeeded(sessionId: sessionId)
                        break
                    }
                    continue
                }

                failureCount = 0
                await refreshSession(sessionId: sessionId, debugMode: isDebugEnabled)

                let isDone = await MainActor.run {
                    store.state(for: sessionId)?.isCompleted == true
                }
                if isDone { break }

                try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
            }
            pollingTasks[sessionId] = nil
        }
    }

    func stopPolling(sessionId: String) {
        pollingTasks[sessionId]?.cancel()
        pollingTasks.removeValue(forKey: sessionId)
    }

    private func validateSessionBeforePolling(sessionId: String) async -> Bool {
        guard var record = trackingRecords[sessionId] else { return false }
        guard !record.isExpired else { return false }

        do {
            let sessions = try await client.listSessions()
            guard let remote = sessions.first(where: { $0.id == sessionId }) else {
                record.consecutiveValidationFailures += 1
                trackingRecords[sessionId] = record
                return false
            }

            let normalized = normalizedLifecycleStatus(from: remote.name)
            record.status = normalized
            record.lastKnownServerState = remote.name
            record.lastUpdated = Date()
            trackingRecords[sessionId] = record
            trace("validated poll target session_id=\(sessionId) status=\(normalized.rawValue)")
            return true
        } catch {
            trace("validation error session_id=\(sessionId) error=\(error.localizedDescription)")
            return false
        }
    }

    private func normalizedLifecycleStatus(from raw: String?) -> LifecycleStatus {
        let value = (raw ?? "").lowercased()
        if value.contains("created") { return .created }
        if value.contains("queue") || value.contains("pending") { return .queued }
        if value.contains("run") || value.contains("progress") { return .running }
        if value.contains("complete") || value.contains("success") || value.contains("done") { return .completed }
        if value.contains("fail") || value.contains("error") || value.contains("cancel") { return .failed }
        return .unknown
    }

    private func taskIdentifier(from session: AgentSession) -> String? {
        let parts = session.name.split(separator: "/")
        return parts.count > 1 ? String(parts.last ?? "") : nil
    }

    private func validatedRepositoryURL(owner: String, repo: String) throws -> String {
        let o = owner.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !o.isEmpty, !r.isEmpty else {
            throw AgentError.invalidPayload(["repository"])
        }
        return "https://github.com/\(o)/\(r)"
    }

    private func isServerStateCompatible(local: SessionTrackingRecord, with remote: AgentSession, normalized: LifecycleStatus) -> Bool {
        guard local.sessionId == remote.id else { return false }
        if let localTask = local.taskId, !localTask.isEmpty {
            let remoteTask = taskIdentifier(from: remote)
            if remoteTask != nil && remoteTask != localTask { return false }
        }
        if normalized == .unknown && local.status != .unknown {
            return false
        }
        return true
    }

    private func isNotFoundError(_ error: Error) -> Bool {
        if let requestError = error as? JulesRequestManager.JulesRequestError,
           case .apiError(let statusCode, _, _) = requestError,
           statusCode == 404 {
            return true
        }

        if let agentError = error as? AgentError,
           case .apiError(let message) = agentError,
           message.contains("404") || message.localizedCaseInsensitiveContains("NOT_FOUND") {
            return true
        }
        return error.localizedDescription.contains("404") || error.localizedDescription.localizedCaseInsensitiveContains("NOT_FOUND")
    }

    private func invalidateSession(sessionId: String, reason: String) async {
        trace("invalidate session_id=\(sessionId) reason=\(reason)")
        stopPolling(sessionId: sessionId)
        trackingRecords.removeValue(forKey: sessionId)
        seenActivityIDs.removeValue(forKey: sessionId)
        await emitLifecycleFailure(sessionId: sessionId, message: "Session invalidated: \(reason)")
    }

    private func emitLifecycleEvent(sessionId: String, status: LifecycleStatus) async {
        let message = "Session transitioned to \(status.rawValue)"
        let type: AgentExecutionEventType = status == .completed ? .sessionCompleted : (status == .failed ? .sessionFailed : .stepProgress)
        let event = AgentExecutionEvent(
            sessionId: sessionId,
            type: type,
            title: "Lifecycle",
            message: message,
            payload: ["status": AnyCodable(status.rawValue)]
        )
        await MainActor.run {
            self.store.ingest(event: event, debugSnapshot: nil)
        }
        eventBus.publish(event)
    }

    private func emitLifecycleFailure(sessionId: String, message: String) async {
        let failed = AgentExecutionEvent(
            sessionId: sessionId,
            type: .sessionFailed,
            title: "Session Lifecycle Reset",
            message: message,
            payload: [:]
        )
        await MainActor.run {
            self.store.ingest(event: failed, debugSnapshot: nil)
        }
        eventBus.publish(failed)
    }

    private func attemptRestartIfNeeded(sessionId: String) async {
        guard let request = pendingSessionRequests[sessionId] else { return }
        trace("restart session requested old_session_id=\(sessionId)")
        do {
            _ = try await startSession(prompt: request.prompt, owner: request.owner, repo: request.repo, branch: request.branch)
        } catch {
            trace("restart failed old_session_id=\(sessionId) error=\(error.localizedDescription)")
        }
    }

    private func trace(_ message: String) {
        print("[AgentSessionFramework] \(message)")
    }

    private var isDebugEnabled: Bool {
        UserDefaults.standard.bool(forKey: "agent.framework.debug")
    }

    private func routeInternalActions(for event: AgentExecutionEvent) {
        guard event.type == .fileGenerated || event.type == .fileUpdated else { return }
        guard let filePath = event.payload["file_path"]?.value as? String else { return }
        let context = SystemToolContext(workspaceId: "agent", sessionId: event.sessionId, timestamp: ISO8601DateFormatter().string(from: Date()))

        if event.type == .fileUpdated, let patch = event.payload["patch"]?.value as? String {
            Task {
                _ = try? await AgentSystemTools.shared.execute(name: "apply_patch", input: ["path": filePath, "patch": patch], context: context)
            }
        } else if let content = event.payload["content"]?.value as? String {
            Task {
                _ = try? await AgentSystemTools.shared.execute(name: "write_file", input: ["path": filePath, "content": content], context: context)
            }
        }
    }
}
