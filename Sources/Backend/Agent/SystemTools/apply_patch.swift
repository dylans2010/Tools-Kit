import Foundation

final class ApplyPatchTool: SystemTool {
    let name = "apply_patch"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
