import Foundation

final class ComplexityAnalysisTool: SystemTool {
    let name = "complexity_analysis"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
