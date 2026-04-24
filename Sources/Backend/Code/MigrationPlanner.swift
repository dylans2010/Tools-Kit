import Foundation

final class MigrationPlanner {
    static let shared = MigrationPlanner()
    func planImports(modules: [CodeModule]) -> [ImportAction] {
        return []
    }
}
