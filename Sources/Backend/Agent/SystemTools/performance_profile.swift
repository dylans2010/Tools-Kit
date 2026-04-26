import Foundation

final class PerformanceProfileTool: SystemTool {
    let name = "performance_profile"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
