import Foundation

final class SecurityScanTool: SystemTool {
    let name = "security_scan"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
