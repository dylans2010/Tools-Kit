import Foundation

final class DeleteFileTool: SystemTool {
    let name = "delete_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let path = try requireString(input, key: "path")
        try FileManager.default.removeItem(atPath: path)
        return successResponse(input: input, context: context, output: ["path": path, "deleted": true])
    }
}
