import Foundation

final class UiRefreshTool: SystemTool {
    let name = "ui_refresh"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool ui_refresh executed successfully")],
            error: nil,
            context: context
        )
    }
}
