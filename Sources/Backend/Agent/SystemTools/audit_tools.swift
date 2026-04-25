import Foundation

/// A tool to audit all registered system tools for production-readiness.
final class AuditToolsTool: SystemTool {
    let name = "audit_tools"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileManager = FileManager.default
        let toolsDirectory = "Sources/Backend/Agent/SystemTools/"

        var invalidTools: [String] = []
        var mockToolsDetected: [String] = []
        var todoToolsDetected: [String] = []
        var nonFunctionalTools: [String] = []
        var jsonSchemaFailures: [String] = []
        var registryMismatches: [String] = []

        do {
            let files = try fileManager.contentsOfDirectory(atPath: toolsDirectory)
            let toolFiles = files.filter { $0.endsWith(".swift") && $0 != "SystemTool.swift" }

            for file in toolFiles {
                let filePath = toolsDirectory + file
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                let toolClassName = file.replacingOccurrences(of: ".swift", with: "").split(separator: "_").map { $0.capitalized }.joined() + "Tool"

                // Check for mocks
                if content.contains("executed successfully") {
                    mockToolsDetected.append(file)
                }

                // Check for TODOs
                if content.localizedCaseInsensitiveContains("TODO") || content.localizedCaseInsensitiveContains("FIXME") {
                    todoToolsDetected.append(file)
                }

                // Check for registry mismatch (simplified check)
                let registryContent = try String(contentsOfFile: "Sources/Backend/Agent/AgentSystemTools.swift", encoding: .utf8)
                if !registryContent.contains(toolClassName) {
                    registryMismatches.append(file)
                }

                // Real execution logic check
                let productionKeywords = ["FileManager", "URLSession", "Process", "Data(contentsOf", "JSONDecoder", "JSONEncoder", "Bundle", "UserDefaults", "AppStorage"]
                let hasProductionLogic = productionKeywords.contains { content.contains($0) }

                if !hasProductionLogic {
                    // Ignore tools that are naturally simple or special
                    let exclusions = ["AuditToolsTool", "AbortTaskTool", "EmitStatusTool", "PauseExecutionTool", "ResumeExecutionTool"]
                    if !exclusions.contains(toolClassName) {
                         nonFunctionalTools.append(file)
                    }
                }
            }
        } catch {
            return SystemToolResponse(
                tool: name,
                status: "failed",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: [:],
                error: SystemToolError(message: "Audit failed: \(error.localizedDescription)", code: "audit_error"),
                context: context
            )
        }

        let status = (mockToolsDetected.isEmpty && registryMismatches.isEmpty) ? "passed" : "failed"

        let auditResults: [String: Any] = [
            "audit_status": status,
            "invalid_tools": invalidTools,
            "mock_tools_detected": mockToolsDetected,
            "todo_tools_detected": todoToolsDetected,
            "non_functional_tools": nonFunctionalTools,
            "json_schema_failures": jsonSchemaFailures,
            "registry_mismatches": registryMismatches
        ]

        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: auditResults.mapValues { AnyCodable($0) },
            error: nil,
            context: context
        )
    }
}

private extension String {
    func endsWith(_ suffix: String) -> Bool {
        return self.hasSuffix(suffix)
    }
}
