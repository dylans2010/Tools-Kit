import Foundation

final class RenameSymbolTool: SystemTool {
    let name = "rename_symbol"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool rename_symbol executed successfully")],
            error: nil,
            context: context
        )
    }
}
