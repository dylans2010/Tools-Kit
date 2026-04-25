import Foundation

final class ListFilesTool: SystemTool {
    let name = "list_files"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let path = (input["path"] as? String) ?? "."
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            return SystemToolResponse(
                tool: name,
                status: "success",
                requestId: UUID().uuidString,
                input: input.mapValues { AnyCodable($0) },
                output: ["files": AnyCodable(files)],
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
                error: SystemToolError(message: error.localizedDescription, code: "list_files_error"),
                context: context
            )
        }
    }
}
