import Foundation

final class ArchitectureReviewTool: SystemTool {
    let name = "architecture_review"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let payloadSummary = input.keys.sorted().joined(separator: ",")
        return successResponse(input: input, context: context, output: [
            "message": "\(name) executed with native iOS-safe fallback logic.",
            "input_keys": payloadSummary
        ])
    }
}
