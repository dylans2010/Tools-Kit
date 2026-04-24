import Foundation

struct ImportAction: Identifiable, Codable {
    let id: UUID = UUID()
    let module: CodeModule
    let action: ActionType
    let targetPath: String

    enum ActionType: String, Codable {
        case importAsIs
        case refactor
        case discard
    }
}

final class CodeImportPlanner {
    func planImports(modules: [CodeModule]) -> [ImportAction] {
        return modules.map { module in
            let action: ImportAction.ActionType
            let targetPath: String

            if module.name.lowercased().contains("test") || module.name.hasPrefix(".") {
                action = .discard
                targetPath = ""
            } else if module.type == .feature {
                action = .refactor
                targetPath = "Sources/Workspace/Code/Features/\(module.name)"
            } else {
                action = .importAsIs
                targetPath = "Sources/Workspace/Code/Shared/\(module.name)"
            }

            return ImportAction(module: module, action: action, targetPath: targetPath)
        }
    }
}
