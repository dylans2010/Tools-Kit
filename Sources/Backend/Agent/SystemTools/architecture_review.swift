import Foundation

final class ArchitectureReviewTool: SystemTool {
    let name = "architecture_review"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
