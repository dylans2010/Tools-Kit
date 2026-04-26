import Foundation

final class SearchRepoTool: SystemTool {
    let name = "search_repo"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
