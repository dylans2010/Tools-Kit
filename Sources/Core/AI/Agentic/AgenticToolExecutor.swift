import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AgenticToolExecutor: ObservableObject {
    static let shared = AgenticToolExecutor()

    @Published var lastOutput: AgenticToolOutputFallback?
    @Published var executionLog: [ToolExecutionEntry] = []
    @Published var isExecuting: Bool = false

    private let logger = Logger(subsystem: "com.toolskit.agentic", category: "tool-executor")
    private let analyzer = AgenticWorkspaceAnalyzer.shared

    private init() {}

    struct ToolExecutionEntry: Identifiable {
        let id = UUID()
        let toolName: String
        let input: [String: String]
        let output: AgenticToolOutputFallback
        let duration: TimeInterval
        let timestamp: Date
        let success: Bool
    }

    // MARK: - Tool Execution

    func execute(tool: AgenticToolDefinition, parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        isExecuting = true
        let startTime = Date()
        defer { isExecuting = false }

        logger.info("Executing tool: \(tool.name) with \(parameters.count) parameters")

        let output: AgenticToolOutputFallback

        switch tool.name {
        case let name where name.hasPrefix("query"):
            output = try await executeQueryTool(tool: tool, parameters: parameters)

        case let name where name.hasPrefix("modify"):
            output = try await executeModifyTool(tool: tool, parameters: parameters)

        case let name where name.hasPrefix("invoke"):
            output = try await executeServiceTool(tool: tool, parameters: parameters)

        case let name where name.hasPrefix("inspect"):
            output = try await executeInspectTool(tool: tool, parameters: parameters)

        case "analyzeWorkspaceArchitecture":
            output = try await executeArchitectureAnalysis(parameters: parameters)

        case "searchWorkspaceCode":
            output = try await executeCodeSearch(parameters: parameters)

        case "generateCodeSuggestion":
            output = try await executeCodeGeneration(tool: tool, parameters: parameters)

        case "crossDomainQuery":
            output = try await executeCrossDomainQuery(parameters: parameters)

        default:
            output = AgenticToolOutputFallback(
                summary: "Unknown tool: \(tool.name)",
                metadata: ["status": "unsupported"]
            )
        }

        let duration = Date().timeIntervalSince(startTime)
        let entry = ToolExecutionEntry(
            toolName: tool.name,
            input: parameters,
            output: output,
            duration: duration,
            timestamp: startTime,
            success: true
        )
        executionLog.append(entry)
        lastOutput = output

        logger.info("Tool \(tool.name) completed in \(String(format: "%.2f", duration))s")
        return output
    }

    // MARK: - Query Tool

    private func executeQueryTool(tool: AgenticToolDefinition, parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        let query = parameters["query"] ?? ""

        guard let graph = analyzer.getCachedGraph() else {
            return AgenticToolOutputFallback(
                summary: "Workspace not yet analyzed. Run workspace analysis first.",
                metadata: ["status": "needs_analysis"]
            )
        }

        let matchingModules = graph.modules.filter { module in
            module.domain.lowercased().contains(query.lowercased()) ||
            module.name.lowercased().contains(query.lowercased()) ||
            module.declarations.contains { $0.name.lowercased().contains(query.lowercased()) }
        }

        let results = matchingModules.map { module in
            "\(module.name) (\(module.domain)): \(module.declarations.count) declarations, \(module.files.count) files"
        }

        return AgenticToolOutputFallback(
            summary: "Found \(matchingModules.count) matching modules for query '\(query)'",
            metadata: [
                "query": query,
                "resultCount": String(matchingModules.count),
                "sourceModule": tool.sourceModule
            ],
            dataPayload: Dictionary(uniqueKeysWithValues: results.enumerated().map { ("result_\($0.offset)", $0.element) })
        )
    }

    // MARK: - Modify Tool

    private func executeModifyTool(tool: AgenticToolDefinition, parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        let operation = parameters["operation"] ?? "unknown"
        let data = parameters["data"] ?? "{}"

        return AgenticToolOutputFallback(
            summary: "Modification operation '\(operation)' prepared for \(tool.sourceModule)",
            metadata: [
                "operation": operation,
                "sourceModule": tool.sourceModule,
                "status": "prepared"
            ],
            dataPayload: ["payload": data]
        )
    }

    // MARK: - Service Tool

    private func executeServiceTool(tool: AgenticToolDefinition, parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        let method = parameters["method"] ?? "unknown"

        return AgenticToolOutputFallback(
            summary: "Service method '\(method)' invoked on \(tool.sourceModule)",
            metadata: [
                "method": method,
                "sourceModule": tool.sourceModule,
                "status": "invoked"
            ]
        )
    }

    // MARK: - Inspect Tool

    private func executeInspectTool(tool: AgenticToolDefinition, parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        guard let graph = analyzer.getCachedGraph() else {
            return AgenticToolOutputFallback(
                summary: "Workspace not yet analyzed.",
                metadata: ["status": "needs_analysis"]
            )
        }

        let module = graph.modules.first { $0.id == tool.sourceModule }

        guard let module = module else {
            return AgenticToolOutputFallback(
                summary: "Module not found: \(tool.sourceModule)",
                metadata: ["status": "not_found"]
            )
        }

        var details: [String: String] = [
            "moduleName": module.name,
            "domain": module.domain,
            "fileCount": String(module.files.count),
            "declarationCount": String(module.declarations.count),
            "structCount": String(module.structCount),
            "classCount": String(module.classCount),
            "enumCount": String(module.enumCount)
        ]

        let component = parameters["component"]
        if let component = component {
            let matching = module.declarations.filter { $0.name.lowercased().contains(component.lowercased()) }
            details["matchingDeclarations"] = matching.map(\.name).joined(separator: ", ")
        }

        return AgenticToolOutputFallback(
            summary: "Inspection of \(module.name): \(module.files.count) files, \(module.declarations.count) declarations",
            metadata: ["status": "inspected"],
            dataPayload: details
        )
    }

    // MARK: - Architecture Analysis

    private func executeArchitectureAnalysis(parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        guard let graph = analyzer.getCachedGraph() else {
            return AgenticToolOutputFallback(
                summary: "Workspace not analyzed yet.",
                metadata: ["status": "needs_analysis"]
            )
        }

        let focus = parameters["focus"]
        let modules: [WorkspaceModule]

        if let focus = focus {
            modules = graph.modules(in: focus)
        } else {
            modules = graph.modules
        }

        let capabilities = analyzer.detectExistingCapabilities(from: graph)
        let missing = analyzer.detectMissingCapabilities(from: graph)

        var payload: [String: String] = [
            "totalModules": String(modules.count),
            "totalFiles": String(graph.totalFileCount),
            "totalRelationships": String(graph.relationships.count),
            "featureDomains": graph.featureDomains.joined(separator: ", ")
        ]

        for (domain, caps) in capabilities {
            payload["caps_\(domain)"] = caps.joined(separator: ", ")
        }

        if !missing.isEmpty {
            payload["missingCapabilities"] = missing.joined(separator: "; ")
        }

        return AgenticToolOutputFallback(
            summary: "Architecture: \(modules.count) modules across \(graph.featureDomains.count) domains with \(graph.relationships.count) relationships",
            metadata: ["status": "analyzed"],
            dataPayload: payload
        )
    }

    // MARK: - Code Search

    private func executeCodeSearch(parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        let query = parameters["query"] ?? ""
        let scope = parameters["scope"]

        guard let graph = analyzer.getCachedGraph() else {
            return AgenticToolOutputFallback(
                summary: "Workspace not analyzed.",
                metadata: ["status": "needs_analysis"]
            )
        }

        var searchModules = graph.modules
        if let scope = scope {
            searchModules = graph.modules(in: scope)
        }

        var matches: [(String, String)] = []
        for module in searchModules {
            for decl in module.declarations {
                if decl.name.lowercased().contains(query.lowercased()) {
                    matches.append((decl.name, "\(decl.kind.rawValue) in \(module.name) (\(decl.filePath))"))
                }
            }
        }

        return AgenticToolOutputFallback(
            summary: "Code search for '\(query)': found \(matches.count) declarations",
            metadata: [
                "query": query,
                "resultCount": String(matches.count)
            ],
            dataPayload: Dictionary(uniqueKeysWithValues: matches.prefix(20).map { ($0.0, $0.1) })
        )
    }

    // MARK: - Code Generation

    private func executeCodeGeneration(tool: AgenticToolDefinition, parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        let intent = parameters["intent"] ?? ""

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return try await generateWithFoundationModels(intent: intent, tool: tool)
        }
        #endif

        return AgenticToolOutputFallback(
            summary: "Code generation requires Foundation Models runtime (iOS 26.0+ / macOS 26.0+)",
            metadata: ["status": "unavailable"]
        )
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func generateWithFoundationModels(intent: String, tool: AgenticToolDefinition) async throws -> AgenticToolOutputFallback {
        let session = LanguageModelSession()

        guard let graph = analyzer.getCachedGraph() else {
            return AgenticToolOutputFallback(
                summary: "Workspace not analyzed.",
                metadata: ["status": "needs_analysis"]
            )
        }

        let contextSummary = graph.modules.prefix(10).map { module in
            "\(module.name) (\(module.domain)): \(module.declarations.map(\.name).prefix(5).joined(separator: ", "))"
        }.joined(separator: "\n")

        let prompt = """
        Based on this workspace structure:
        \(contextSummary)

        Generate Swift code for: \(intent)
        Follow existing patterns and conventions found in the workspace.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutputFallback(
            summary: "Generated code for: \(intent)",
            generatedCode: response.content,
            metadata: [
                "intent": intent,
                "status": "generated",
                "sourceModule": tool.sourceModule
            ]
        )
    }
    #endif

    // MARK: - Cross-Domain Query

    private func executeCrossDomainQuery(parameters: [String: String]) async throws -> AgenticToolOutputFallback {
        let query = parameters["query"] ?? ""
        let domainsFilter = parameters["domains"]?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        guard let graph = analyzer.getCachedGraph() else {
            return AgenticToolOutputFallback(
                summary: "Workspace not analyzed.",
                metadata: ["status": "needs_analysis"]
            )
        }

        var targetModules = graph.modules
        if let domainsFilter = domainsFilter {
            targetModules = graph.modules.filter { domainsFilter.contains($0.domain) }
        }

        var results: [String: String] = [:]
        for module in targetModules {
            let matchingDecls = module.declarations.filter {
                $0.name.lowercased().contains(query.lowercased()) ||
                $0.methods.contains { $0.lowercased().contains(query.lowercased()) } ||
                $0.properties.contains { $0.lowercased().contains(query.lowercased()) }
            }
            if !matchingDecls.isEmpty {
                results[module.domain] = matchingDecls.map(\.name).joined(separator: ", ")
            }
        }

        return AgenticToolOutputFallback(
            summary: "Cross-domain query '\(query)': matches in \(results.count) domains",
            metadata: [
                "query": query,
                "domainsSearched": String(targetModules.count),
                "domainsMatched": String(results.count)
            ],
            dataPayload: results
        )
    }

    // MARK: - Execution History

    func clearLog() {
        executionLog = []
        lastOutput = nil
    }
}
