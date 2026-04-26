import Foundation

final class BuildProjectTool: SystemTool {
    let name = "build_project"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
