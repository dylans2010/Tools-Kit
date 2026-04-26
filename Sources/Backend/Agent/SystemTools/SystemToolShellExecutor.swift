import Foundation

enum SystemToolShellExecutor {
    static func execute(tool name: String, input: [String: Any], context: SystemToolContext) async -> SystemToolResponse {
        do {
            let output = try await run(tool: name, input: input)
            return SystemToolResponse(
                tool: name,
                status: "success",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: output.mapValues { AnyCodable($0) },
                error: nil,
                context: context
            )
        } catch {
            return SystemToolResponse(
                tool: name,
                status: "failed",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: [:],
                error: SystemToolError(message: error.localizedDescription, code: "tool_execution_error"),
                context: context
            )
        }
    }

    private static func run(tool name: String, input: [String: Any]) async throws -> [String: Any] {
        switch name {
        case "run_command", "execute_script":
            let command = try required(input, key: "command")
            return try runShell(command)
        case "run_tests":
            return try runShell((input["command"] as? String) ?? "swift test")
        case "build_project":
            return try runShell((input["command"] as? String) ?? "swift build")
        case "search_repo":
            let pattern = try required(input, key: "pattern")
            let path = (input["path"] as? String) ?? "."
            return try runShell("rg --line-number --color never \(shellEscape(pattern)) \(shellEscape(path))")
        case "list_files":
            let path = (input["path"] as? String) ?? "."
            return try runShell("find \(shellEscape(path)) -maxdepth 3 -mindepth 1")
        case "get_git_diff", "generate_diff", "render_diff_state":
            return try runShell("git diff -- .")
        case "branch_create":
            let branch = try required(input, key: "branch")
            return try runShell("git checkout -b \(shellEscape(branch))")
        case "branch_switch":
            let branch = try required(input, key: "branch")
            return try runShell("git checkout \(shellEscape(branch))")
        case "merge_branch":
            let branch = try required(input, key: "branch")
            return try runShell("git merge \(shellEscape(branch))")
        case "commit_changes":
            let message = (input["message"] as? String) ?? "Agent commit"
            return try runShell("git add -A && git commit -m \(shellEscape(message))")
        case "revert_commit":
            let commit = (input["commit"] as? String) ?? "HEAD"
            return try runShell("git revert --no-edit \(shellEscape(commit))")
        case "delete_file":
            let path = try required(input, key: "path")
            try FileManager.default.removeItem(atPath: path)
            return ["path": path, "deleted": true]
        case "move_file":
            let source = try required(input, key: "source")
            let destination = try required(input, key: "destination")
            try FileManager.default.moveItem(atPath: source, toPath: destination)
            return ["source": source, "destination": destination]
        case "append_file":
            let path = try required(input, key: "path")
            let content = try required(input, key: "content")
            let data = Data(content.utf8)
            if FileManager.default.fileExists(atPath: path) {
                let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } else {
                try data.write(to: URL(fileURLWithPath: path))
            }
            return ["path": path, "appended_bytes": data.count]
        case "clear_memory":
            try storeJSON([], fileName: "agent_memory.json")
            return ["cleared": true]
        case "save_memory", "update_memory", "load_memory", "summarize_memory":
            return try handleMemory(tool: name, input: input)
        case "update_timeline", "log_event", "event_replay", "execution_trace_export":
            return try handleTimeline(tool: name, input: input)
        case "pause_execution", "resume_execution", "abort_task", "emit_status", "publish_workspace_state", "stream_execution", "simulate_run", "ui_refresh", "debug_session", "restore_checkpoint", "create_checkpoint", "workspace_snapshot":
            return try handleState(tool: name, input: input)
        case "lint_code":
            return try runShell((input["command"] as? String) ?? "swift format lint --recursive Sources")
        case "format_code", "code_cleanup", "refactor_code", "extract_function", "inline_function", "rename_symbol":
            return try runShell((input["command"] as? String) ?? "swift format --in-place --recursive Sources")
        case "tool_discovery":
            return ["tools": Array(AgentSystemTools.shared.tools.keys).sorted()]
        case "tool_health_check":
            let tools = Array(AgentSystemTools.shared.tools.keys).sorted()
            return ["total_tools": tools.count, "healthy_tools": tools]
        case "dependency_graph":
            return try runShell("swift package describe --type json")
        case "security_scan":
            return try runShell((input["command"] as? String) ?? "rg --line-number --ignore-case 'password|secret|api[_-]?key|token' Sources")
        case "code_explain", "architecture_review", "api_contract_scan", "schema_validation", "performance_profile", "profile_runtime", "migration_analyzer", "complexity_analysis", "analyze_errors":
            return try runShell(try required(input, key: "command"))
        case "apply_patch":
            return try runShell(try required(input, key: "command"))
        case "request_user_input":
            throw NSError(domain: "SystemTool", code: 1, userInfo: [NSLocalizedDescriptionKey: "request_user_input must be handled by UI runtime."])
        default:
            throw NSError(domain: "SystemTool", code: 404, userInfo: [NSLocalizedDescriptionKey: "No executor for tool \(name)"])
        }
    }

    private static func handleMemory(tool: String, input: [String: Any]) throws -> [String: Any] {
        let fileName = "agent_memory.json"
        var memory = (try? loadJSONArray(fileName: fileName)) ?? []
        switch tool {
        case "save_memory":
            let entry = ["key": try required(input, key: "key"), "value": try required(input, key: "value"), "updated_at": ISO8601DateFormatter().string(from: Date())]
            memory.append(entry)
            try storeJSON(memory, fileName: fileName)
            return ["saved": true, "count": memory.count]
        case "update_memory":
            let key = try required(input, key: "key")
            let value = try required(input, key: "value")
            memory.removeAll { ($0["key"] as? String) == key }
            memory.append(["key": key, "value": value, "updated_at": ISO8601DateFormatter().string(from: Date())])
            try storeJSON(memory, fileName: fileName)
            return ["updated": true, "key": key]
        case "load_memory":
            if let key = input["key"] as? String {
                let values = memory.filter { ($0["key"] as? String) == key }
                return ["items": values]
            }
            return ["items": memory]
        case "summarize_memory":
            let summary = memory.prefix(20).map { "\(($0["key"] as? String) ?? "?"): \(($0["value"] as? String) ?? "")" }.joined(separator: "\n")
            return ["summary": summary, "count": memory.count]
        default:
            return [:]
        }
    }

    private static func handleTimeline(tool: String, input: [String: Any]) throws -> [String: Any] {
        let fileName = "agent_timeline.json"
        var timeline = (try? loadJSONArray(fileName: fileName)) ?? []
        if tool == "event_replay" || tool == "execution_trace_export" {
            return ["events": timeline]
        }
        let event: [String: Any] = [
            "tool": tool,
            "message": (input["message"] as? String) ?? "",
            "payload": input,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        timeline.append(event)
        try storeJSON(timeline, fileName: fileName)
        return ["logged": true, "events_count": timeline.count]
    }

    private static func handleState(tool: String, input: [String: Any]) throws -> [String: Any] {
        let fileName = "agent_state.json"
        var state = (try? loadJSONDictionary(fileName: fileName)) ?? [:]
        state[tool] = input
        state["updated_at"] = ISO8601DateFormatter().string(from: Date())
        try storeJSON(state, fileName: fileName)
        return ["state_updated": true, "tool": tool]
    }

    private static func runShell(_ command: String) throws -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-lc", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        let result: [String: Any] = [
            "command": command,
            "exit_code": process.terminationStatus,
            "stdout": stdout,
            "stderr": stderr
        ]

        if process.terminationStatus != 0 {
            throw NSError(domain: "ShellExecution", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: stderr.isEmpty ? "Command failed" : stderr])
        }

        return result
    }

    private static func required(_ input: [String: Any], key: String) throws -> String {
        if let value = input[key] as? String, !value.isEmpty { return value }
        throw NSError(domain: "SystemTool", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing required parameter: \(key)"])
    }

    private static func storeJSON(_ value: Any, fileName: String) throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted])
        try data.write(to: url)
    }

    private static func loadJSONArray(fileName: String) throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return (try JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    private static func loadJSONDictionary(fileName: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private static func shellEscape(_ input: String) -> String {
        "'\(input.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
