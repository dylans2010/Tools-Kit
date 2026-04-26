import Foundation

final class RenameSymbolTool: SystemTool {
    let name = "rename_symbol"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
