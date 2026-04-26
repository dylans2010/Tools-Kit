import Foundation

final class SimulateRunTool: SystemTool {
    let name = "simulate_run"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
