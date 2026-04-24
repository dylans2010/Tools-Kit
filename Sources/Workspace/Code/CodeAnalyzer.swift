import Foundation
import Combine

final class CodeAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var currentRepo: String?
    @Published var auditResult: CodeAuditEngine.RepoStructure?
    @Published var modules: [CodeModule] = []
    @Published var importPlan: [ImportAction] = []

    private let auditEngine = CodeAuditEngine.shared
    private let mapper = CodeStructureMapper()
    private let planner = CodeImportPlanner()

    func analyze(owner: String, repo: String) async {
        await MainActor.run {
            isAnalyzing = true
            currentRepo = "\(owner)/\(repo)"
        }

        do {
            let structure = try await auditEngine.auditRepository(owner: owner, repo: repo)
            let mappedModules = mapper.map(structure: structure)
            let plan = planner.planImports(modules: mappedModules)

            await MainActor.run {
                self.auditResult = structure
                self.modules = mappedModules
                self.importPlan = plan
                self.isAnalyzing = false
            }
        } catch {
            print("Analysis failed: \(error)")
            await MainActor.run {
                isAnalyzing = false
            }
        }
    }
}
