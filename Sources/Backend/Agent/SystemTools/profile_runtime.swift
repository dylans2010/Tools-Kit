import Foundation

final class ProfileRuntimeTool: SystemTool {
    let name = "profile_runtime"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
