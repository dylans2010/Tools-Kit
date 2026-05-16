import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class WorkspaceAITools: ObservableObject {
    static let shared = WorkspaceAITools()

    @Published var registeredTools: [AgenticToolDefinition] = []
    @Published var isGenerating: Bool = false

    private let logger = Logger(subsystem: "com.toolskit.agentic", category: "workspace-tools")
    private let analyzer = AgenticWorkspaceAnalyzer.shared

    private init() {}

    // MARK: - Dynamic Tool Generation

    func generateTools(from graph: WorkspaceGraph) async -> [AgenticToolDefinition] {
        isGenerating = true
        defer { isGenerating = false }

        logger.info("Generating tools from workspace graph with \(graph.modules.count) modules")

        var tools: [AgenticToolDefinition] = []

        let capabilities = analyzer.detectExistingCapabilities(from: graph)

        for module in graph.modules {
            let moduleCaps = capabilities[module.domain] ?? []
            let moduleTools = deriveToolsFromModule(module, capabilities: moduleCaps)
            tools.append(contentsOf: moduleTools)
        }

        tools.append(contentsOf: generateCrossModuleTools(from: graph))

        let deduped = deduplicateTools(tools)

        registeredTools = deduped
        logger.info("Generated \(deduped.count) tools from workspace analysis")

        return deduped
    }

    func regenerateTools() async -> [AgenticToolDefinition] {
        do {
            let graph = try await analyzer.analyzeWorkspace()
            return await generateTools(from: graph)
        } catch {
            logger.error("Tool regeneration failed: \(error.localizedDescription)")
            return []
        }
    }

    func toolDefinition(named name: String) -> AgenticToolDefinition? {
        registeredTools.first { $0.name == name }
    }

    // MARK: - Module-Based Tool Derivation

    private func deriveToolsFromModule(_ module: WorkspaceModule, capabilities: [String]) -> [AgenticToolDefinition] {
        var tools: [AgenticToolDefinition] = []

        let managers = module.declarations.filter { $0.name.hasSuffix("Manager") }
        for manager in managers {
            let readMethods = manager.methods.filter { m in
                m.hasPrefix("get") || m.hasPrefix("fetch") || m.hasPrefix("load") || m.hasPrefix("list") || m.hasPrefix("find")
            }
            let writeMethods = manager.methods.filter { m in
                m.hasPrefix("create") || m.hasPrefix("add") || m.hasPrefix("save") || m.hasPrefix("update") || m.hasPrefix("delete") || m.hasPrefix("remove")
            }

            if !readMethods.isEmpty {
                tools.append(AgenticToolDefinition(
                    name: "query\(module.name)Data",
                    description: "Query and retrieve data from the \(module.domain) system via \(manager.name)",
                    sourceModule: module.id,
                    parameters: [
                        AgenticToolParameter(name: "query", type: "String", required: true, description: "Search query or filter"),
                        AgenticToolParameter(name: "limit", type: "Int", required: false, description: "Maximum results to return")
                    ],
                    derivedFrom: "\(manager.name) [\(readMethods.joined(separator: ", "))]"
                ))
            }

            if !writeMethods.isEmpty {
                tools.append(AgenticToolDefinition(
                    name: "modify\(module.name)Data",
                    description: "Create, update, or delete data in the \(module.domain) system via \(manager.name)",
                    sourceModule: module.id,
                    parameters: [
                        AgenticToolParameter(name: "operation", type: "String", required: true, description: "Operation: create, update, or delete"),
                        AgenticToolParameter(name: "data", type: "String", required: true, description: "JSON payload for the operation"),
                        AgenticToolParameter(name: "itemID", type: "String", required: false, description: "Item identifier for update/delete")
                    ],
                    derivedFrom: "\(manager.name) [\(writeMethods.joined(separator: ", "))]"
                ))
            }
        }

        let services = module.declarations.filter { $0.name.hasSuffix("Service") }
        for service in services {
            if !service.methods.isEmpty {
                tools.append(AgenticToolDefinition(
                    name: "invoke\(service.name)",
                    description: "Execute \(service.name) operations from the \(module.domain) system",
                    sourceModule: module.id,
                    parameters: [
                        AgenticToolParameter(name: "method", type: "String", required: true, description: "Service method to invoke"),
                        AgenticToolParameter(name: "arguments", type: "String", required: false, description: "JSON arguments for the method")
                    ],
                    derivedFrom: "\(service.name) [\(service.methods.prefix(5).joined(separator: ", "))]"
                ))
            }
        }

        if capabilities.contains("UI Layer") && capabilities.contains("Data Models") {
            tools.append(AgenticToolDefinition(
                name: "inspect\(module.name)State",
                description: "Inspect current state of the \(module.domain) UI and data layer",
                sourceModule: module.id,
                parameters: [
                    AgenticToolParameter(name: "component", type: "String", required: false, description: "Specific component to inspect")
                ],
                derivedFrom: "Module capabilities: \(capabilities.joined(separator: ", "))"
            ))
        }

        return tools
    }

    // MARK: - Cross-Module Tools

    private func generateCrossModuleTools(from graph: WorkspaceGraph) -> [AgenticToolDefinition] {
        var tools: [AgenticToolDefinition] = []

        tools.append(AgenticToolDefinition(
            name: "analyzeWorkspaceArchitecture",
            description: "Analyze the full workspace architecture including modules, relationships, and dependencies",
            sourceModule: "workspace",
            parameters: [
                AgenticToolParameter(name: "focus", type: "String", required: false, description: "Specific domain to focus analysis on")
            ],
            derivedFrom: "WorkspaceGraph [\(graph.modules.count) modules, \(graph.relationships.count) relationships]"
        ))

        tools.append(AgenticToolDefinition(
            name: "searchWorkspaceCode",
            description: "Search across workspace source files for declarations, patterns, or references",
            sourceModule: "workspace",
            parameters: [
                AgenticToolParameter(name: "query", type: "String", required: true, description: "Search query"),
                AgenticToolParameter(name: "scope", type: "String", required: false, description: "Limit search to specific domain")
            ],
            derivedFrom: "WorkspaceAnalyzer [recursive file scan]"
        ))

        tools.append(AgenticToolDefinition(
            name: "generateCodeSuggestion",
            description: "Generate code suggestions based on workspace patterns and existing implementations",
            sourceModule: "workspace",
            parameters: [
                AgenticToolParameter(name: "intent", type: "String", required: true, description: "What you want to generate"),
                AgenticToolParameter(name: "targetModule", type: "String", required: false, description: "Target module for the generated code")
            ],
            derivedFrom: "WorkspaceGraph [pattern analysis]"
        ))

        if graph.featureDomains.count > 1 {
            tools.append(AgenticToolDefinition(
                name: "crossDomainQuery",
                description: "Query data across multiple workspace domains simultaneously",
                sourceModule: "workspace",
                parameters: [
                    AgenticToolParameter(name: "query", type: "String", required: true, description: "Natural language query"),
                    AgenticToolParameter(name: "domains", type: "String", required: false, description: "Comma-separated domain filter")
                ],
                derivedFrom: "Domains: \(graph.featureDomains.joined(separator: ", "))"
            ))
        }

        return tools
    }

    // MARK: - Deduplication

    private func deduplicateTools(_ tools: [AgenticToolDefinition]) -> [AgenticToolDefinition] {
        var seen = Set<String>()
        return tools.filter { tool in
            guard !seen.contains(tool.name) else { return false }
            seen.insert(tool.name)
            return true
        }
    }
}
