import Foundation

final class GenerateDiffTool: SystemTool {
    let name = "generate_diff"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        guard let basePath = input["path"] as? String else {
            return successResponse(input: input, context: context, output: ["diff": "No path supplied; diff unavailable in iOS sandbox.", "simulated": true])
        }
        let url = URL(fileURLWithPath: basePath)
        let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let preview = content.split(separator: "\n", omittingEmptySubsequences: false).prefix(40).enumerated().map { "\($0.offset + 1): \($0.element)" }.joined(separator: "\n")
        return successResponse(input: input, context: context, output: ["path": basePath, "diff": preview, "line_count": content.split(separator: "\n", omittingEmptySubsequences: false).count])
    }
}
