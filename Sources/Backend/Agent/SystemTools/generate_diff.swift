import Foundation

final class GenerateDiffTool: SystemTool {
    let name = "generate_diff"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
