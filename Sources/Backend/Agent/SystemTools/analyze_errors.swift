import Foundation

final class AnalyzeErrorsTool: SystemTool {
    let name = "analyze_errors"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
