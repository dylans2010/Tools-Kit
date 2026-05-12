import Foundation
import JavaScriptCore

public final class SDKSandboxEngine {
    nonisolated(unsafe) public static let shared = SDKSandboxEngine()

    private init() {}

    @MainActor
    private func createNewContext() -> JSContext {
        guard let context = JSContext() else {
            fatalError("Failed to create JSContext")
        }
        setupContext(context)
        return context
    }

    @MainActor
    private func setupContext(_ context: JSContext) {
        let log: @convention(block) (String) -> Void = { message in
            SDKLogStore.shared.log(message, source: "SDKSandboxEngine", level: .info)
        }
        context.setObject(log, forKeyedSubscript: "print" as NSString)

        let workspace = JSValue(object: [:], in: context)

        // Notes Module
        let notes = JSValue(object: [:], in: context)
        let listNotes: @convention(block) () -> [[String: Any]] = {
            WorkspaceAPI.shared.notes.listNotes().map { ["id": $0.id.uuidString, "title": $0.title, "content": $0.content] }
        }
        let createNote: @convention(block) (String, String) -> [String: Any] = { title, content in
            let action = SDKAction.createNote(title: title, content: content)
            let context = SDKExecutionContext(projectID: UUID(), noSandbox: SDKRuntimeEngine.shared.isNoSandboxModeEnabled)
            Task {
                try? await SDKExecutionKernel.shared.execute(action: action, context: context)
            }
            return ["status": "queued_via_kernel"]
        }
        notes?.setObject(listNotes, forKeyedSubscript: "list" as NSString)
        notes?.setObject(createNote, forKeyedSubscript: "create" as NSString)
        workspace?.setObject(notes, forKeyedSubscript: "notes" as NSString)

        // Tasks Module
        let tasks = JSValue(object: [:], in: context)
        let listTasks: @convention(block) () -> [[String: Any]] = {
            WorkspaceAPI.shared.tasks.listTasks().map { ["id": $0.id.uuidString, "title": $0.title, "completed": $0.completed] }
        }
        let createTask: @convention(block) (String) -> [String: Any] = { title in
            let task = WorkspaceAPI.shared.tasks.createTask(title: title, dueDate: nil)
            return ["id": task.id.uuidString, "title": task.title]
        }
        tasks?.setObject(listTasks, forKeyedSubscript: "list" as NSString)
        tasks?.setObject(createTask, forKeyedSubscript: "create" as NSString)
        workspace?.setObject(tasks, forKeyedSubscript: "tasks" as NSString)

        // Mail Module
        let mail = JSValue(object: [:], in: context)
        let listMail: @convention(block) () -> [[String: Any]] = {
            WorkspaceAPI.shared.mail.listMessages().map { ["id": $0.id, "subject": $0.subject, "from": $0.from] }
        }
        let sendMail: @convention(block) (String, String, String) -> Void = { to, subject, body in
            Task { try? await WorkspaceAPI.shared.mail.sendMail(to: to, subject: subject, body: body) }
        }
        mail?.setObject(listMail, forKeyedSubscript: "list" as NSString)
        mail?.setObject(sendMail, forKeyedSubscript: "send" as NSString)
        workspace?.setObject(mail, forKeyedSubscript: "mail" as NSString)

        // Calendar Module
        let calendar = JSValue(object: [:], in: context)
        let listEvents: @convention(block) () -> [[String: Any]] = {
            guard Thread.isMainThread else { return [] }
            return MainActor.assumeIsolated {
                WorkspaceAPI.shared.calendar.listEvents().map { ["id": $0.id.uuidString, "title": $0.title] }
            }
        }
        let createEvent: @convention(block) (String, Double, Double) -> Void = { title, start, end in
            Task { @MainActor in
                WorkspaceAPI.shared.calendar.createEvent(title: title, start: Date(timeIntervalSince1970: start), end: Date(timeIntervalSince1970: end))
            }
        }
        calendar?.setObject(listEvents, forKeyedSubscript: "list" as NSString)
        calendar?.setObject(createEvent, forKeyedSubscript: "create" as NSString)
        workspace?.setObject(calendar, forKeyedSubscript: "calendar" as NSString)

        // Files Module
        let files = JSValue(object: [:], in: context)
        let listFiles: @convention(block) () -> [[String: Any]] = {
            WorkspaceAPI.shared.files.listFiles().map { ["id": $0.id, "name": $0.name] }
        }
        files?.setObject(listFiles, forKeyedSubscript: "list" as NSString)
        workspace?.setObject(files, forKeyedSubscript: "files" as NSString)

        // Slides Module
        let slides = JSValue(object: [:], in: context)
        let listDecks: @convention(block) () -> [[String: Any]] = {
            WorkspaceAPI.shared.slides.listDecks().map { ["id": $0.id.uuidString, "title": $0.title] }
        }
        slides?.setObject(listDecks, forKeyedSubscript: "list" as NSString)
        workspace?.setObject(slides, forKeyedSubscript: "slides" as NSString)

        // Meet Module
        let meet = JSValue(object: [:], in: context)
        let startMeeting: @convention(block) (String) -> [String: Any] = { title in
            var result: [String: Any] = ["status": "starting"]
            Task {
                do {
                    let meetingID = try await WorkspaceAPI.shared.meet.startMeeting(title: title)
                    SDKLogStore.shared.log("Meeting started: \(meetingID)", source: "SDKSandboxEngine", level: .info)
                } catch {
                    SDKLogStore.shared.log("Meeting failed: \(error.localizedDescription)", source: "SDKSandboxEngine", level: .error)
                }
            }
            return result
        }
        meet?.setObject(startMeeting, forKeyedSubscript: "start" as NSString)
        workspace?.setObject(meet, forKeyedSubscript: "meet" as NSString)

        // Time Travel Module
        let timeTravel = JSValue(object: [:], in: context)
        let listSnapshots: @convention(block) () -> [[String: Any]] = {
            WorkspaceAPI.shared.timeTravel.listSnapshots().map { ["id": $0.id.uuidString, "message": $0.message] }
        }
        let restoreSnapshot: @convention(block) (String) -> [String: Any] = { idString in
            guard let uuid = UUID(uuidString: idString) else { return ["error": "Invalid UUID"] }
            do {
                try WorkspaceAPI.shared.timeTravel.restoreState(snapshotID: uuid)
                return ["status": "restored"]
            } catch {
                return ["error": error.localizedDescription]
            }
        }
        timeTravel?.setObject(listSnapshots, forKeyedSubscript: "list" as NSString)
        timeTravel?.setObject(restoreSnapshot, forKeyedSubscript: "restore" as NSString)
        workspace?.setObject(timeTravel, forKeyedSubscript: "timeTravel" as NSString)

        // Persona Module
        let persona = JSValue(object: [:], in: context)
        let queryPersona: @convention(block) (String) -> String = { prompt in
            var result = ""
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                do {
                    result = try await WorkspaceAPI.shared.persona.queryPersona(prompt: prompt)
                } catch {
                    result = "Error: \(error.localizedDescription)"
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 10)
            return result
        }
        persona?.setObject(queryPersona, forKeyedSubscript: "query" as NSString)
        workspace?.setObject(persona, forKeyedSubscript: "persona" as NSString)

        // Integrations Module
        let integrations = JSValue(object: [:], in: context)
        let executeWorkflow: @convention(block) (String) -> Void = { id in
            if let uuid = UUID(uuidString: id) {
                Task { try? await WorkspaceAPI.shared.integrations.executeWorkflow(workflowID: uuid) }
            }
        }
        integrations?.setObject(executeWorkflow, forKeyedSubscript: "execute" as NSString)
        workspace?.setObject(integrations, forKeyedSubscript: "integrations" as NSString)

        // Graph Module
        let graph = JSValue(object: [:], in: context)
        let queryGraph: @convention(block) () -> [[String: Any]] = {
            let g = WorkspaceAPI.shared.intelligence.getGraph()
            return g.nodes.map { ["id": $0.id.uuidString, "label": $0.label, "type": $0.type] }
        }
        let linkEntities: @convention(block) (String, String, String) -> Void = { source, target, relation in
            if let sourceUUID = UUID(uuidString: source), let targetUUID = UUID(uuidString: target) {
                WorkspaceAPI.shared.intelligence.updateLink(source: sourceUUID, target: targetUUID, relation: relation)
            }
        }
        graph?.setObject(queryGraph, forKeyedSubscript: "query" as NSString)
        graph?.setObject(linkEntities, forKeyedSubscript: "link" as NSString)
        workspace?.setObject(graph, forKeyedSubscript: "graph" as NSString)

        context.setObject(workspace, forKeyedSubscript: "workspace" as NSString)
    }

    @MainActor
    public func executeSandboxed(sourceCode: String) async throws {
        let context = createNewContext()
        context.evaluateScript(sourceCode)

        if let exception = context.exception {
            let errorMsg = exception.toString() ?? "Unknown JS error"
            SDKLogStore.shared.log("Sandbox execution error: \(errorMsg)", source: "SDKSandboxEngine", level: LogLevel.error)
            throw SDKError.executionFailed(reason: errorMsg)
        }
    }

    @MainActor
    public func executeUnrestricted(sourceCode: String) async throws {
        let context = createNewContext()

        let bridge = JSValue(object: [:], in: context)
        let getLiveState: @convention(block) () -> [String: Any] = {
            return MainActor.assumeIsolated {
                SDKWorkspaceBridge.shared.getLiveSystemState()
            }
        }
        bridge?.setObject(getLiveState, forKeyedSubscript: "getLiveState" as NSString)
        context.setObject(bridge, forKeyedSubscript: "sdk_bridge" as NSString)

        context.evaluateScript(sourceCode)

        if let exception = context.exception {
            let errorMsg = exception.toString() ?? "Unknown JS error"
            SDKLogStore.shared.log("Unrestricted execution error: \(errorMsg)", source: "SDKSandboxEngine", level: LogLevel.error)
            throw SDKError.executionFailed(reason: errorMsg)
        }
    }
}
