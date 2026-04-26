import Foundation

final class ExtractFunctionTool: SystemTool {
    let name = "extract_function"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
