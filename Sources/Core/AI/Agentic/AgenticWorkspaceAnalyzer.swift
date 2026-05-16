import Foundation
import os

final class AgenticWorkspaceAnalyzer: @unchecked Sendable {
    static let shared = AgenticWorkspaceAnalyzer()

    private let logger = Logger(subsystem: "com.toolskit.agentic", category: "workspace-analyzer")
    private let fileManager = FileManager.default
    private var cachedGraph: WorkspaceGraph?

    private init() {}

    // MARK: - Public API

    func analyzeWorkspace() async throws -> WorkspaceGraph {
        logger.info("Starting workspace analysis...")

        let sourcesURL = resolveSourcesDirectory()

        guard fileManager.fileExists(atPath: sourcesURL.path) else {
            logger.error("Sources directory not found at: \(sourcesURL.path)")
            throw AnalyzerError.sourcesNotFound(sourcesURL.path)
        }

        let fileEntries = try scanDirectoryRecursively(at: sourcesURL)
        logger.info("Scanned \(fileEntries.count) Swift files")

        var modules: [WorkspaceModule] = []
        var allDeclarations: [String: [WorkspaceDeclaration]] = [:]

        let domainGroups = groupFilesByDomain(fileEntries, rootURL: sourcesURL)

        for (domain, files) in domainGroups {
            let workspaceFiles = files.map { entry -> WorkspaceFile in
                WorkspaceFile(
                    id: entry.path,
                    name: entry.name,
                    path: entry.path,
                    lineCount: entry.lineCount,
                    imports: entry.imports
                )
            }

            var declarations: [WorkspaceDeclaration] = []
            for file in files {
                let parsed = parseSwiftDeclarations(from: file.content, filePath: file.path)
                declarations.append(contentsOf: parsed)
            }

            let moduleName = domain.components(separatedBy: "/").last ?? domain
            let moduleID = domain

            allDeclarations[moduleID] = declarations

            let module = WorkspaceModule(
                id: moduleID,
                name: moduleName,
                domain: inferFeatureDomain(from: domain),
                path: domain,
                files: workspaceFiles,
                declarations: declarations
            )
            modules.append(module)
        }

        let relationships = buildRelationships(modules: modules, declarations: allDeclarations)

        let graph = WorkspaceGraph(
            modules: modules,
            relationships: relationships,
            scannedAt: Date()
        )

        cachedGraph = graph
        logger.info("Workspace analysis complete: \(modules.count) modules, \(relationships.count) relationships, \(graph.featureDomains.count) domains")

        return graph
    }

    func getCachedGraph() -> WorkspaceGraph? {
        cachedGraph
    }

    func invalidateCache() {
        cachedGraph = nil
    }

    // MARK: - Directory Scanning

    private func resolveSourcesDirectory() -> URL {
        if let bundlePath = Bundle.main.resourceURL?.appendingPathComponent("Sources") {
            if fileManager.fileExists(atPath: bundlePath.path) {
                return bundlePath
            }
        }

        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        return projectRoot.appendingPathComponent("Sources")
    }

    private struct FileEntry {
        let name: String
        let path: String
        let relativePath: String
        let content: String
        let lineCount: Int
        let imports: [String]
    }

    private func scanDirectoryRecursively(at url: URL) throws -> [FileEntry] {
        var entries: [FileEntry] = []

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AnalyzerError.scanFailed("Cannot enumerate directory: \(url.path)")
        }

        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }

            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                let imports = extractImports(from: lines)

                let relativePath = fileURL.path.replacingOccurrences(of: url.path, with: "")

                entries.append(FileEntry(
                    name: fileURL.lastPathComponent,
                    path: fileURL.path,
                    relativePath: relativePath,
                    content: content,
                    lineCount: lines.count,
                    imports: imports
                ))
            } catch {
                logger.warning("Cannot read file: \(fileURL.path)")
            }
        }

        return entries
    }

    // MARK: - Swift File Parsing

    private func parseSwiftDeclarations(from content: String, filePath: String) -> [WorkspaceDeclaration] {
        var declarations: [WorkspaceDeclaration] = []
        let lines = content.components(separatedBy: .newlines)

        var currentDeclaration: (name: String, kind: DeclarationKind, properties: [String], methods: [String], conformances: [String])?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let parsed = parseDeclarationLine(trimmed) {
                if let current = currentDeclaration {
                    declarations.append(WorkspaceDeclaration(
                        id: "\(filePath):\(current.name)",
                        name: current.name,
                        kind: current.kind,
                        filePath: filePath,
                        properties: current.properties,
                        methods: current.methods,
                        conformances: current.conformances
                    ))
                }
                currentDeclaration = (
                    name: parsed.name,
                    kind: parsed.kind,
                    properties: [],
                    methods: [],
                    conformances: parsed.conformances
                )
            } else if currentDeclaration != nil {
                if trimmed.hasPrefix("var ") || trimmed.hasPrefix("let ") || trimmed.hasPrefix("@Published") {
                    let propName = extractPropertyName(from: trimmed)
                    if let propName = propName {
                        currentDeclaration?.properties.append(propName)
                    }
                } else if trimmed.hasPrefix("func ") {
                    let methodName = extractMethodName(from: trimmed)
                    if let methodName = methodName {
                        currentDeclaration?.methods.append(methodName)
                    }
                }
            }
        }

        if let current = currentDeclaration {
            declarations.append(WorkspaceDeclaration(
                id: "\(filePath):\(current.name)",
                name: current.name,
                kind: current.kind,
                filePath: filePath,
                properties: current.properties,
                methods: current.methods,
                conformances: current.conformances
            ))
        }

        return declarations
    }

    private struct ParsedDeclaration {
        let name: String
        let kind: DeclarationKind
        let conformances: [String]
    }

    private func parseDeclarationLine(_ line: String) -> ParsedDeclaration? {
        let declarationPatterns: [(String, DeclarationKind)] = [
            ("struct ", .structDecl),
            ("class ", .classDecl),
            ("enum ", .enumDecl),
            ("protocol ", .protocolDecl),
            ("actor ", .actorDecl)
        ]

        let stripped = line
            .replacingOccurrences(of: "final ", with: "")
            .replacingOccurrences(of: "public ", with: "")
            .replacingOccurrences(of: "private ", with: "")
            .replacingOccurrences(of: "internal ", with: "")
            .replacingOccurrences(of: "@MainActor ", with: "")
            .replacingOccurrences(of: "@Observable ", with: "")
            .trimmingCharacters(in: .whitespaces)

        for (prefix, kind) in declarationPatterns {
            guard stripped.hasPrefix(prefix) else { continue }

            let afterPrefix = String(stripped.dropFirst(prefix.count))
            let components = afterPrefix.components(separatedBy: CharacterSet(charactersIn: ":{< "))
            guard let name = components.first, !name.isEmpty else { continue }

            var conformances: [String] = []
            if let colonIndex = afterPrefix.firstIndex(of: ":") {
                let afterColon = String(afterPrefix[afterPrefix.index(after: colonIndex)...])
                let braceIndex = afterColon.firstIndex(of: "{") ?? afterColon.endIndex
                let conformanceStr = String(afterColon[..<braceIndex])
                conformances = conformanceStr
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }

            return ParsedDeclaration(name: name, kind: kind, conformances: conformances)
        }

        return nil
    }

    private func extractPropertyName(from line: String) -> String? {
        let cleaned = line
            .replacingOccurrences(of: "@Published ", with: "")
            .replacingOccurrences(of: "@State ", with: "")
            .replacingOccurrences(of: "@Binding ", with: "")
            .replacingOccurrences(of: "private ", with: "")
            .replacingOccurrences(of: "public ", with: "")
            .trimmingCharacters(in: .whitespaces)

        if cleaned.hasPrefix("var ") || cleaned.hasPrefix("let ") {
            let afterKeyword = String(cleaned.dropFirst(4))
            let name = afterKeyword.components(separatedBy: CharacterSet(charactersIn: ":= ")).first
            return name?.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private func extractMethodName(from line: String) -> String? {
        let cleaned = line
            .replacingOccurrences(of: "private ", with: "")
            .replacingOccurrences(of: "public ", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard cleaned.hasPrefix("func ") else { return nil }
        let afterFunc = String(cleaned.dropFirst(5))
        let name = afterFunc.components(separatedBy: "(").first
        return name?.trimmingCharacters(in: .whitespaces)
    }

    private func extractImports(from lines: [String]) -> [String] {
        lines
            .filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("import ") }
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: " ")
                return parts.count >= 2 ? parts[1] : nil
            }
    }

    // MARK: - Domain Inference

    private func groupFilesByDomain(_ files: [FileEntry], rootURL: URL) -> [String: [FileEntry]] {
        var groups: [String: [FileEntry]] = [:]

        for file in files {
            let pathComponents = file.relativePath
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                .components(separatedBy: "/")

            let domain: String
            if pathComponents.count >= 2 {
                domain = pathComponents.prefix(2).joined(separator: "/")
            } else {
                domain = "Root"
            }

            groups[domain, default: []].append(file)
        }

        return groups
    }

    private func inferFeatureDomain(from path: String) -> String {
        let lowered = path.lowercased()

        if lowered.contains("music") { return "Music" }
        if lowered.contains("mail") || lowered.contains("messages") { return "Mail" }
        if lowered.contains("calendar") { return "Calendar" }
        if lowered.contains("task") { return "Tasks" }
        if lowered.contains("note") || lowered.contains("notebook") { return "Notes" }
        if lowered.contains("slide") { return "Slides" }
        if lowered.contains("spreadsheet") { return "Spreadsheets" }
        if lowered.contains("collaboration") || lowered.contains("collab") { return "Collaboration" }
        if lowered.contains("persona") { return "Persona" }
        if lowered.contains("agent") { return "Agent" }
        if lowered.contains("workspace") { return "Workspace" }
        if lowered.contains("views") { return "UI" }
        if lowered.contains("models") { return "DataModels" }
        if lowered.contains("core") { return "Core" }
        if lowered.contains("backend") { return "Backend" }
        if lowered.contains("sdk") { return "SDK" }
        if lowered.contains("security") { return "Security" }
        if lowered.contains("keyboard") { return "Keyboard" }
        if lowered.contains("components") { return "Components" }
        if lowered.contains("editing") { return "Editing" }
        if lowered.contains("intelligence") { return "Intelligence" }
        if lowered.contains("plugin") { return "Plugins" }

        return "General"
    }

    // MARK: - Relationship Building

    private func buildRelationships(modules: [WorkspaceModule], declarations: [String: [WorkspaceDeclaration]]) -> [WorkspaceRelation] {
        var relations: [WorkspaceRelation] = []
        let modulesByID = Dictionary(uniqueKeysWithValues: modules.map { ($0.id, $0) })

        for module in modules {
            let moduleImports = Set(module.files.flatMap(\.imports))

            for otherModule in modules where otherModule.id != module.id {
                let otherDeclNames = Set((declarations[otherModule.id] ?? []).map(\.name))

                if !moduleImports.intersection(otherDeclNames).isEmpty {
                    relations.append(WorkspaceRelation(
                        id: "\(module.id)->\(otherModule.id)",
                        sourceModuleID: module.id,
                        targetModuleID: otherModule.id,
                        kind: .dependsOn
                    ))
                }
            }

            let moduleConformances = Set((declarations[module.id] ?? []).flatMap(\.conformances))
            for otherModule in modules where otherModule.id != module.id {
                let otherProtocols = Set((declarations[otherModule.id] ?? [])
                    .filter { $0.kind == .protocolDecl }
                    .map(\.name))

                if !moduleConformances.intersection(otherProtocols).isEmpty {
                    relations.append(WorkspaceRelation(
                        id: "\(module.id)-conforms->\(otherModule.id)",
                        sourceModuleID: module.id,
                        targetModuleID: otherModule.id,
                        kind: .conformsTo
                    ))
                }
            }
        }

        return relations
    }

    // MARK: - Capability Detection

    func detectExistingCapabilities(from graph: WorkspaceGraph) -> [String: [String]] {
        var capabilities: [String: [String]] = [:]

        for module in graph.modules {
            var moduleCaps: [String] = []

            let hasViews = module.declarations.contains { $0.conformances.contains("View") || $0.name.hasSuffix("View") }
            let hasManagers = module.declarations.contains { $0.name.hasSuffix("Manager") }
            let hasServices = module.declarations.contains { $0.name.hasSuffix("Service") }
            let hasModels = module.declarations.contains { $0.kind == .structDecl && !$0.name.hasSuffix("View") }

            if hasViews { moduleCaps.append("UI Layer") }
            if hasManagers { moduleCaps.append("State Management") }
            if hasServices { moduleCaps.append("Service Layer") }
            if hasModels { moduleCaps.append("Data Models") }

            if !moduleCaps.isEmpty {
                capabilities[module.domain] = moduleCaps
            }
        }

        return capabilities
    }

    func detectMissingCapabilities(from graph: WorkspaceGraph) -> [String] {
        var missing: [String] = []
        let existingDomains = Set(graph.featureDomains)
        let capabilities = detectExistingCapabilities(from: graph)

        for (domain, caps) in capabilities {
            if !caps.contains("Service Layer") && caps.contains("UI Layer") {
                missing.append("\(domain): Missing dedicated service layer")
            }
            if !caps.contains("Data Models") && caps.contains("UI Layer") {
                missing.append("\(domain): Missing structured data models")
            }
        }

        return missing
    }

    // MARK: - Errors

    enum AnalyzerError: Error, LocalizedError {
        case sourcesNotFound(String)
        case scanFailed(String)
        case parseFailed(String)

        var errorDescription: String? {
            switch self {
            case .sourcesNotFound(let path):
                return "Sources directory not found at: \(path)"
            case .scanFailed(let reason):
                return "Directory scan failed: \(reason)"
            case .parseFailed(let reason):
                return "Swift parsing failed: \(reason)"
            }
        }
    }
}
