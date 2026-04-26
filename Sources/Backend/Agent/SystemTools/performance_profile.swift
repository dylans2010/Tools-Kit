import Foundation

final class PerformanceProfileTool: SystemTool {
    let name = "performance_profile"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let payloadSummary = input.keys.sorted().joined(separator: ",")
        return successResponse(input: input, context: context, output: [
            "message": "\(name) executed with native iOS-safe fallback logic.",
            "input_keys": payloadSummary
        ])
    }
}
