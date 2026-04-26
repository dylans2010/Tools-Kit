import Foundation

final class WriteFileTool: SystemTool {
    let name = "write_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        guard let path = input["path"] as? String, let content = input["content"] as? String else {
            return SystemToolResponse(
                tool: name,
                status: "failed",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: [:],
                error: SystemToolError(message: "Missing 'path' or 'content' parameter", code: "missing_param"),
                context: context
            )
        }

        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return SystemToolResponse(
                tool: name,
                status: "success",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: ["message": AnyCodable("File written successfully to \(path)")],
                error: nil,
                context: context
            )
        } catch {
            return SystemToolResponse(
                tool: name,
                status: "failed",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: [:],
                error: SystemToolError(message: error.localizedDescription, code: "write_file_error"),
                context: context
            )
        }
    }
}
