import Foundation

final class SchemaValidationTool: SystemTool {
    let name = "schema_validation"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
