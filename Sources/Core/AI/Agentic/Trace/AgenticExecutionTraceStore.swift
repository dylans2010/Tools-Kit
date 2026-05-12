import Foundation

@MainActor
final class AgenticExecutionTraceStore: ObservableObject {
    nonisolated(unsafe) static let shared = AgenticExecutionTraceStore()

    @Published private(set) var entries: [AgenticTraceEntry] = []
    @Published private(set) var activeToolName: String?

    private let maxEntries = 2000

    private init() {}

    // MARK: - Recording

    func record(phase: String, detail: String, toolName: String? = nil, inputSnapshot: [String: String]? = nil, outputSnapshot: [String: String]? = nil, durationMs: Double? = nil) {
        let entry = AgenticTraceEntry(
            phase: phase,
            detail: detail,
            toolName: toolName,
            inputSnapshot: inputSnapshot,
            outputSnapshot: outputSnapshot,
            durationMs: durationMs
        )
        entries.append(entry)
        if let tool = toolName {
            activeToolName = tool
        }
        enforceLimit()
    }

    func markToolStart(_ toolName: String, parameters: [String: String]) {
        activeToolName = toolName
        record(
            phase: "tool_start",
            detail: "Executing tool: \(toolName)",
            toolName: toolName,
            inputSnapshot: parameters
        )
    }

    func markToolEnd(_ toolName: String, output: AgenticToolOutput, durationMs: Double) {
        var snapshot: [String: String] = ["summary": output.summary]
        if let code = output.generatedCode {
            snapshot["generatedCode"] = String(code.prefix(500))
        }
        for (k, v) in output.metadata {
            snapshot["meta_\(k)"] = v
        }
        record(
            phase: "tool_end",
            detail: "Tool completed: \(toolName)",
            toolName: toolName,
            outputSnapshot: snapshot,
            durationMs: durationMs
        )
        activeToolName = nil
    }

    func markError(_ error: Error, context: String) {
        record(
            phase: "error",
            detail: "\(context): \(error.localizedDescription)"
        )
        activeToolName = nil
    }

    // MARK: - Query

    func entriesForTool(_ toolName: String) -> [AgenticTraceEntry] {
        entries.filter { $0.toolName == toolName }
    }

    func entriesForPhase(_ phase: String) -> [AgenticTraceEntry] {
        entries.filter { $0.phase == phase }
    }

    var totalDurationMs: Double {
        entries.compactMap(\.durationMs).reduce(0, +)
    }

    // MARK: - Export

    func exportJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(entries)
    }

    func clear() {
        entries.removeAll()
        activeToolName = nil
    }

    // MARK: - Internal

    private func enforceLimit() {
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }
    }
}
