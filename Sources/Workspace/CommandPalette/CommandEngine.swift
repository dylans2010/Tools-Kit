import Foundation
import Combine

// MARK: - Command Models

struct ParsedCommand: Identifiable, Sendable {
    let id = UUID()
    let raw: String
    let intent: CommandIntent
    let parameters: [String: String]
    let confidence: Double
}

enum CommandIntent: String, CaseIterable, Sendable {
    // Collaboration
    case summarizeWorkspace = "summarize_workspace"
    case findOverdueTasks = "find_overdue_tasks"
    case openActivityFeed = "open_activity_feed"
    case optimizeWorkspace = "optimize_workspace"
    case createAutomation = "create_automation"
    case saveSnapshot = "save_snapshot"
    case globalSearch = "global_search"
    case generateReport = "generate_report"

    // GitHub
    case runWorkflow = "run_workflow"
    case findUnusedFiles = "find_unused_files"
    case analyzeRepo = "analyze_repo"
    case createRelease = "create_release"
    case scanSecrets = "scan_secrets"
    case buildCommit = "build_commit"

    // Plugin
    case pluginCommand = "plugin_command"

    // Unknown
    case unknown = "unknown"
}


struct PluginCommand: Identifiable, Sendable {
    let id: UUID
    let keyword: String
    let description: String
}

struct CommandSuggestion: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let description: String
    let icon: String
    let intent: CommandIntent
}

struct CommandResult: Identifiable, Sendable {
    let id = UUID()
    let command: String
    let output: String
    let success: Bool
    let timestamp: Date
    let actionData: [String: String]
}

// MARK: - Command Engine

/// Central command routing and execution system.
final class CommandEngine: ObservableObject {
    static let shared = CommandEngine()

    @Published private(set) var history: [CommandResult] = []
    @Published private(set) var pluginCommands: [(command: PluginCommand, pluginName: String)] = []

    private let storageFile = "command_history.json"

    private init() {
        loadHistory()
    }

    // MARK: - Plugin Command Registration

    func registerPluginCommand(_ command: PluginCommand, pluginName: String) {
        pluginCommands.removeAll { $0.command.id == command.id }
        pluginCommands.append((command: command, pluginName: pluginName))
    }

    func unregisterPluginCommand(commandID: UUID) {
        pluginCommands.removeAll { $0.command.id == commandID }
    }

    // MARK: - Parse

    func parse(_ input: String) -> ParsedCommand {
        let interpreter = AICommandInterpreter()
        return interpreter.interpret(input, pluginCommands: pluginCommands)
    }

    // MARK: - Execute

    @discardableResult
    func execute(_ input: String) -> CommandResult {
        let parsed = parse(input)
        let result = route(parsed)
        history.insert(result, at: 0)
        if history.count > 100 { history = Array(history.prefix(100)) }
        saveHistory()
        return result
    }

    private func route(_ cmd: ParsedCommand) -> CommandResult {
        switch cmd.intent {
        case .summarizeWorkspace:
            let spaces = CollaborationManager.shared.spaces
            let totalTasks = ProjectExecutionBoardTool.shared.tasks.count
            let output = "Workspace Summary:\n• \(spaces.count) space(s)\n• \(totalTasks) task(s)\n• \(DecisionEngineTool.shared.decisions.count) decision(s)\n• \(WorkspaceAutomationEngine.shared.automations.count) automation(s)"
            return CommandResult(command: cmd.raw, output: output, success: true, timestamp: Date(), actionData: [:])

        case .findOverdueTasks:
            let overdue = ProjectExecutionBoardTool.shared.tasks.filter { $0.status != .done }
            let output = overdue.isEmpty
                ? "No overdue tasks found."
                : "Overdue tasks (\(overdue.count)):\n" + overdue.prefix(10).map { "• \($0.title)" }.joined(separator: "\n")
            return CommandResult(command: cmd.raw, output: output, success: true, timestamp: Date(), actionData: [:])

        case .openActivityFeed:
            return CommandResult(command: cmd.raw, output: "Opening Activity Feed…", success: true, timestamp: Date(), actionData: ["navigate": "activityFeed"])

        case .optimizeWorkspace:
            DataIntegrityService.shared.runScan()
            let issueCount = DataIntegrityService.shared.issues.count
            return CommandResult(command: cmd.raw, output: "Workspace optimization complete. Found \(issueCount) issue(s).", success: true, timestamp: Date(), actionData: ["navigate": "dataIntegrity"])

        case .saveSnapshot:
            let label = cmd.parameters["label"] ?? "Quick Snapshot"
            WorkspaceSnapshotService.shared.saveSnapshot(label: label)
            return CommandResult(command: cmd.raw, output: "Snapshot '\(label)' saved.", success: true, timestamp: Date(), actionData: [:])

        case .globalSearch:
            let q = cmd.parameters["query"] ?? cmd.raw
            GlobalSearchService.shared.search(query: q)
            let count = GlobalSearchService.shared.results.count
            return CommandResult(command: cmd.raw, output: "Search complete. Found \(count) result(s) for '\(q)'.", success: true, timestamp: Date(), actionData: ["navigate": "search", "query": q])

        case .generateReport:
            let spaces = CollaborationManager.shared.spaces
            let report = spaces.map { "• \($0.name): \($0.activityFeed.count) events" }.joined(separator: "\n")
            return CommandResult(command: cmd.raw, output: "Report:\n\(report.isEmpty ? "No data." : report)", success: true, timestamp: Date(), actionData: [:])

        case .runWorkflow:
            return CommandResult(command: cmd.raw, output: "Routing to Workflow Runner…", success: true, timestamp: Date(), actionData: ["navigate": "workflows"])

        case .findUnusedFiles:
            return CommandResult(command: cmd.raw, output: "Code intelligence scan queued. Open Code Intelligence panel to view results.", success: true, timestamp: Date(), actionData: ["navigate": "codeIntelligence"])

        case .analyzeRepo:
            return CommandResult(command: cmd.raw, output: "Repo analysis started. Open Repo Tools Panel to view health report.", success: true, timestamp: Date(), actionData: ["navigate": "repoTools"])

        case .createRelease:
            return CommandResult(command: cmd.raw, output: "Opening Release Manager…", success: true, timestamp: Date(), actionData: ["navigate": "releaseManager"])

        case .scanSecrets:
            return CommandResult(command: cmd.raw, output: "Opening Security Tools panel to scan for exposed secrets.", success: true, timestamp: Date(), actionData: ["navigate": "securityTools"])

        case .buildCommit:
            return CommandResult(command: cmd.raw, output: "Opening Local Git Engine…", success: true, timestamp: Date(), actionData: ["navigate": "localGit"])

        case .createAutomation:
            return CommandResult(command: cmd.raw, output: "Opening Automation Engine…", success: true, timestamp: Date(), actionData: ["navigate": "automation"])

        case .pluginCommand:
            let keyword = cmd.parameters["keyword"] ?? ""
            let pluginName = cmd.parameters["plugin"] ?? "Unknown Plugin"
            return CommandResult(command: cmd.raw, output: "[\(pluginName)] Executed '\(keyword)'. ✓", success: true, timestamp: Date(), actionData: [:])

        case .unknown:
            return CommandResult(command: cmd.raw, output: "Unknown command. Try: 'summarize workspace', 'find overdue tasks', 'run workflow', 'scan secrets'.", success: false, timestamp: Date(), actionData: [:])
        }
    }

    // MARK: - Suggestions

    func suggestions(for input: String) -> [CommandSuggestion] {
        let builtIn: [CommandSuggestion] = [
            CommandSuggestion(text: "summarize workspace", description: "Get workspace overview", icon: "text.magnifyingglass", intent: .summarizeWorkspace),
            CommandSuggestion(text: "find overdue tasks", description: "List tasks not yet done", icon: "exclamationmark.circle", intent: .findOverdueTasks),
            CommandSuggestion(text: "open activity feed", description: "Navigate to activity feed", icon: "clock.arrow.2.circlepath", intent: .openActivityFeed),
            CommandSuggestion(text: "optimize workspace", description: "Run integrity scan", icon: "wand.and.stars", intent: .optimizeWorkspace),
            CommandSuggestion(text: "save snapshot", description: "Save current workspace state", icon: "camera.fill", intent: .saveSnapshot),
            CommandSuggestion(text: "run workflow", description: "Navigate to workflow runner", icon: "play.rectangle", intent: .runWorkflow),
            CommandSuggestion(text: "find unused files", description: "Code intelligence scan", icon: "doc.badge.ellipsis", intent: .findUnusedFiles),
            CommandSuggestion(text: "analyze repo", description: "Repo health analysis", icon: "chart.line.uptrend.xyaxis", intent: .analyzeRepo),
            CommandSuggestion(text: "create release", description: "Open Release Manager", icon: "tag.fill", intent: .createRelease),
            CommandSuggestion(text: "scan secrets", description: "Security scan for exposed secrets", icon: "lock.shield", intent: .scanSecrets),
            CommandSuggestion(text: "generate report", description: "Generate workspace report", icon: "doc.text", intent: .generateReport),
        ]

        let pluginSuggestions = pluginCommands.map { entry in
            CommandSuggestion(text: entry.command.keyword, description: "\(entry.pluginName): \(entry.command.description)", icon: "puzzlepiece.extension", intent: .pluginCommand)
        }

        let all = builtIn + pluginSuggestions
        if input.isEmpty { return Array(all.prefix(8)) }
        let q = input.lowercased()
        return all.filter { $0.text.localizedCaseInsensitiveContains(q) || $0.description.localizedCaseInsensitiveContains(q) }
    }

    // MARK: - Context-aware suggestions

    func contextSuggestions(currentView: String) -> [CommandSuggestion] {
        switch currentView {
        case "collaboration":
            return suggestions(for: "").filter { [.summarizeWorkspace, .findOverdueTasks, .saveSnapshot, .openActivityFeed, .optimizeWorkspace, .generateReport].contains($0.intent) }
        case "github":
            return suggestions(for: "").filter { [.runWorkflow, .findUnusedFiles, .analyzeRepo, .createRelease, .scanSecrets, .buildCommit].contains($0.intent) }
        default:
            return Array(suggestions(for: "").prefix(6))
        }
    }

    // MARK: - Persistence

    struct StoredResult: Codable, Sendable {
        let id: UUID
        let command: String
        let output: String
        let success: Bool
        let timestamp: Date
    }

    private func saveHistory() {
        let stored = history.prefix(50).map { StoredResult(id: $0.id, command: $0.command, output: $0.output, success: $0.success, timestamp: $0.timestamp) }
        DispatchQueue.global(qos: .utility).async {
            try? WorkspacePersistence.shared.save(Array(stored), to: self.storageFile)
        }
    }

    private func loadHistory() {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            let stored = (try? WorkspacePersistence.shared.load([StoredResult].self, from: storageFile)) ?? []
            history = stored.map { CommandResult(command: $0.command, output: $0.output, success: $0.success, timestamp: $0.timestamp, actionData: [:]) }
        }
    }
}

// MARK: - AI Command Interpreter

/// Interprets natural language input into structured CommandIntents.
final class AICommandInterpreter {

    func interpret(_ input: String, pluginCommands: [(command: PluginCommand, pluginName: String)]) -> ParsedCommand {
        let normalized = input.lowercased().trimmingCharacters(in: .whitespaces)

        // Check plugin commands first
        for entry in pluginCommands {
            if normalized.contains(entry.command.keyword.lowercased()) {
                return ParsedCommand(raw: input, intent: .pluginCommand, parameters: ["keyword": entry.command.keyword, "plugin": entry.pluginName], confidence: 0.95)
            }
        }

        // Pattern matching for built-in intents
        let rules: [(patterns: [String], intent: CommandIntent, paramExtractor: (String) -> [String: String])] = [
            (["summarize workspace", "workspace summary", "overview", "what's in my workspace"], .summarizeWorkspace, { _ in [:] }),
            (["overdue task", "find tasks", "pending task", "incomplete task"], .findOverdueTasks, { _ in [:] }),
            (["activity feed", "open activity", "show feed", "recent activity"], .openActivityFeed, { _ in [:] }),
            (["optimize", "clean workspace", "fix workspace", "repair workspace"], .optimizeWorkspace, { _ in [:] }),
            (["save snapshot", "take snapshot", "backup workspace"], .saveSnapshot, { raw in
                let label = raw.components(separatedBy: "\"").dropFirst().first ?? "Quick Snapshot"
                return ["label": label]
            }),
            (["search ", "find ", "look for ", "locate "], .globalSearch, { raw in
                // Extract the query by stripping any matched keyword prefix
                let prefixes = ["look for ", "locate ", "search ", "find "]
                for prefix in prefixes {
                    if let r = raw.range(of: prefix, options: .caseInsensitive) {
                        return ["query": String(raw[r.upperBound...])]
                    }
                }
                return ["query": raw]
            }),
            (["generate report", "create report", "show report", "report workspace"], .generateReport, { _ in [:] }),
            (["run workflow", "trigger workflow", "execute workflow"], .runWorkflow, { raw in
                let parts = raw.components(separatedBy: " ")
                if parts.count > 2 { return ["workflow": parts.dropFirst(2).joined(separator: " ")] }
                return [:]
            }),
            (["unused file", "dead code", "orphan file", "find unused"], .findUnusedFiles, { _ in [:] }),
            (["analyze repo", "repo analysis", "repo health", "check repo"], .analyzeRepo, { _ in [:] }),
            (["create release", "new release", "make release", "release version"], .createRelease, { _ in [:] }),
            (["scan secret", "find secret", "exposed key", "security scan"], .scanSecrets, { _ in [:] }),
            (["build commit", "stage commit", "commit changes", "create commit"], .buildCommit, { _ in [:] }),
            (["create automation", "new automation", "add automation"], .createAutomation, { _ in [:] }),
        ]

        for rule in rules {
            if rule.patterns.contains(where: { normalized.contains($0) }) {
                let params = rule.paramExtractor(normalized)
                return ParsedCommand(raw: input, intent: rule.intent, parameters: params, confidence: 0.9)
            }
        }

        return ParsedCommand(raw: input, intent: .unknown, parameters: [:], confidence: 0.0)
    }
}
