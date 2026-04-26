import Foundation

final class ApiContractScanTool: SystemTool {
    let name = "api_contract_scan"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
