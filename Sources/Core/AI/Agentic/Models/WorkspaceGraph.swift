import Foundation

// MARK: - Workspace Knowledge Graph

struct WorkspaceGraph: Sendable {
    var modules: [WorkspaceModule]
    var relationships: [WorkspaceRelation]
    var scannedAt: Date

    init(modules: [WorkspaceModule] = [], relationships: [WorkspaceRelation] = [], scannedAt: Date = Date()) {
        self.modules = modules
        self.relationships = relationships
        self.scannedAt = scannedAt
    }

    var featureDomains: [String] {
        let domains = Set(modules.map(\.domain))
        return domains.sorted()
    }

    var totalFileCount: Int {
        modules.reduce(0) { $0 + $1.files.count }
    }

    func modules(in domain: String) -> [WorkspaceModule] {
        modules.filter { $0.domain == domain }
    }

    func relationships(for moduleID: String) -> [WorkspaceRelation] {
        relationships.filter { $0.sourceModuleID == moduleID || $0.targetModuleID == moduleID }
    }
}

struct WorkspaceModule: Identifiable, Sendable {
    let id: String
    let name: String
    let domain: String
    let path: String
    let files: [WorkspaceFile]
    let declarations: [WorkspaceDeclaration]

    var structCount: Int { declarations.filter { $0.kind == .structDecl }.count }
    var classCount: Int { declarations.filter { $0.kind == .classDecl }.count }
    var enumCount: Int { declarations.filter { $0.kind == .enumDecl }.count }
    var protocolCount: Int { declarations.filter { $0.kind == .protocolDecl }.count }

    var capabilities: [String] {
        var caps: [String] = []
        if declarations.contains(where: { $0.name.contains("View") && $0.kind == .structDecl }) {
            caps.append("UI")
        }
        if declarations.contains(where: { $0.name.contains("Manager") || $0.name.contains("Service") }) {
            caps.append("Service")
        }
        if declarations.contains(where: { $0.name.contains("Model") || $0.kind == .structDecl }) {
            caps.append("DataModel")
        }
        return caps
    }
}

struct WorkspaceFile: Identifiable, Sendable {
    let id: String
    let name: String
    let path: String
    let lineCount: Int
    let imports: [String]
}

struct WorkspaceDeclaration: Identifiable, Sendable {
    let id: String
    let name: String
    let kind: DeclarationKind
    let filePath: String
    let properties: [String]
    let methods: [String]
    let conformances: [String]
}

enum DeclarationKind: String, Sendable {
    case structDecl = "struct"
    case classDecl = "class"
    case enumDecl = "enum"
    case protocolDecl = "protocol"
    case extensionDecl = "extension"
    case actorDecl = "actor"
}

struct WorkspaceRelation: Identifiable, Sendable {
    let id: String
    let sourceModuleID: String
    let targetModuleID: String
    let kind: RelationKind
}

enum RelationKind: String, Sendable {
    case imports
    case conformsTo
    case dependsOn
    case contains
}
