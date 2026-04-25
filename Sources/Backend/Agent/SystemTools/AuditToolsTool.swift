import Foundation

/// A tool to audit all registered system tools for production-readiness.
final class AuditToolsTool: SystemTool {
    let name = "audit_tools"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let fileManager = FileManager.default
        let toolsDirectory = "Sources/Backend/Agent/SystemTools/"

        let registeredTools = AgentSystemTools.shared.tools

        var invalidTools: [String] = []
        var mockToolsDetected: [String] = []
        var todoToolsDetected: [String] = []
        var nonFunctionalTools: [String] = []
        var jsonSchemaFailures: [String] = []
        var registryMismatches: [String] = []

        // Registry Mismatch check
        do {
            let files = try fileManager.contentsOfDirectory(atPath: toolsDirectory)
            let toolFiles = files.filter { $0.hasSuffix(".swift") && $0 != "SystemTool.swift" && $0 != "AuditToolsTool.swift" }

            let registeredToolNames = Set(registeredTools.keys)

            for file in toolFiles {
                let toolName = file.replacingOccurrences(of: ".swift", with: "")
                // Basic mapping of filename to tool name - most tools use their filename as name or snake_case
                // Since most filenames are snake_case and tool names are also snake_case or match, we check both.
                if !registeredToolNames.contains(toolName) {
                    // Try to see if any registered tool has a name that matches this file (ignoring snake_case differences if any)
                    let matches = registeredTools.values.contains { $0.name == toolName || $0.name.replacingOccurrences(of: "_", with: "") == toolName.replacingOccurrences(of: "_", with: "") }
                    if !matches {
                        registryMismatches.append(file)
                    }
                }
            }
        } catch {
            // If directory read fails, we continue with other checks
        }

        for tool in registeredTools.values {
            let toolName = tool.name
            let fileName: String
            if toolName == "audit_tools" {
                fileName = "AuditToolsTool.swift"
            } else if toolName == "abort_task" {
                fileName = "abort_task.swift"
            } else {
                // Heuristic for other tools
                fileName = "\(toolName).swift"
            }

            let filePath = toolsDirectory + fileName

            if !fileManager.fileExists(atPath: filePath) {
                // If it doesn't exist with exact name, try to find it in the directory
                // (e.g. tool name is "read_file" but filename is "read_file.swift")
                // This is already covered by the logic above, but let's be safe.
                continue
            }

            do {
                let content = try String(contentsOfFile: filePath, encoding: .utf8)

                // Mock Detection: Returns a success message without doing anything substantial
                // Check if execute returns SystemToolResponse with "success" but no production-related keywords in the whole file
                let productionKeywords = ["FileManager", "URLSession", "Process", "Data(contentsOf", "JSONDecoder", "JSONEncoder", "Bundle", "UserDefaults", "AppStorage", "NSTask", "Gzip"]
                let hasProductionLogic = productionKeywords.contains { content.contains($0) }

                if content.contains("\"success\"") && !hasProductionLogic {
                    let exclusions = ["AuditToolsTool", "AbortTaskTool", "EmitStatusTool", "PauseExecutionTool", "ResumeExecutionTool", "RequestUserInputTool"]
                    let className = String(describing: type(of: tool))
                    if !exclusions.contains(className) {
                        mockToolsDetected.append(fileName)
                    }
                }

                // TODO/FIXME detection
                if content.contains("TODO") || content.contains("FIXME") {
                    todoToolsDetected.append(fileName)
                }

                // Non-functional detection (lacks production logic and isn't a known simple tool)
                if !hasProductionLogic {
                    let exclusions = ["AuditToolsTool", "AbortTaskTool", "EmitStatusTool", "PauseExecutionTool", "ResumeExecutionTool", "RequestUserInputTool", "ClearMemoryTool", "LogEventTool"]
                    let className = String(describing: type(of: tool))
                    if !exclusions.contains(className) {
                        nonFunctionalTools.append(fileName)
                    }
                }

                // JSON Schema Failures
                // Check if tool uses 'input' but lacks any validation or decoding
                if content.contains("input[") && !content.contains("JSONDecoder") && !content.contains("as?") && !content.contains("guard let") {
                     jsonSchemaFailures.append(fileName)
                }

            } catch {
                invalidTools.append(fileName)
            }
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
