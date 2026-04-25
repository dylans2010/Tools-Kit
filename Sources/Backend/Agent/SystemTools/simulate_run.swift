import Foundation

final class SimulateRunTool: SystemTool {
    let name = "simulate_run"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool simulate_run executed successfully")],
            error: nil,
            context: context
        )
    }
}
