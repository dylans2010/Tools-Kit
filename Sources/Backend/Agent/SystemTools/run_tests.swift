import Foundation

final class RunTestsTool: SystemTool {
    let name = "run_tests"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
