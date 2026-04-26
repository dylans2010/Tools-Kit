import Foundation

final class MigrationAnalyzerTool: SystemTool {
    let name = "migration_analyzer"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
