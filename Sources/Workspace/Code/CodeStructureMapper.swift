import Foundation

struct CodeModule: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let path: String
    let type: ModuleType
    let dependencies: [String]

    enum ModuleType: String, Codable, Sendable {
        case feature
        case core
        case utility
        case ui
    }
}

final class CodeStructureMapper {
    func map(structure: CodeAuditEngine.RepoStructure) -> [CodeModule] {
        var modules: [CodeModule] = []

        // Group files into potential modules based on directory structure
        let dirs = structure.files.filter { $0.type == "dir" }

        for dir in dirs {
            let type: CodeModule.ModuleType
            if dir.path.contains("Features") || dir.path.contains("UI") {
                type = .feature
            } else if dir.path.contains("Core") || dir.path.contains("Backend") {
                type = .core
            } else {
                type = .utility
            }

            modules.append(CodeModule(
                id: dir.path,
                name: dir.name,
                path: dir.path,
                type: type,
                dependencies: [] // Dependency extraction would require parsing Swift files
            ))
        }

        return modules
    }
}
