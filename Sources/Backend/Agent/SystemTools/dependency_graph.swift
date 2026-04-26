import Foundation

final class DependencyGraphTool: SystemTool {
    let name = "dependency_graph"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
