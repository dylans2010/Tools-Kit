import Foundation

final class DependencyGraphTool: SystemTool {
    let name = "dependency_graph"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let root = toolsWorkingDirectory(from: input)
        let packagePath = root.appendingPathComponent("Package.swift")
        guard FileManager.default.fileExists(atPath: packagePath.path) else {
            return successResponse(input: input, context: context, output: ["modules": [], "count": 0])
        }
        let content = (try? String(contentsOf: packagePath, encoding: .utf8)) ?? ""
        let modules = content.split(separator: "\n").map(String.init).filter { $0.contains(".target(") || $0.contains(".product(") }
        return successResponse(input: input, context: context, output: ["modules": modules, "count": modules.count])
    }
}
