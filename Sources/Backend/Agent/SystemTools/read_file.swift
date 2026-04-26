import Foundation

final class ReadFileTool: SystemTool {
    let name = "read_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        guard let path = input["path"] as? String else {
            return SystemToolResponse(
                tool: name, status: "failed", requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) }, output: [:],
                error: SystemToolError(message: "Missing 'path' parameter", code: "missing_param"),
                context: context
            )
        }

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            return SystemToolResponse(
                tool: name, status: "success", requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: ["content": AnyCodable(content)],
                error: nil, context: context
            )
        } catch {
            return SystemToolResponse(
                tool: name, status: "failed", requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) }, output: [:],
                error: SystemToolError(message: error.localizedDescription, code: "read_file_error"),
                context: context
            )
        }
    }
}
