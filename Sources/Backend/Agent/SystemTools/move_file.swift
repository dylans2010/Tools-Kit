import Foundation

final class MoveFileTool: SystemTool {
    let name = "move_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let source = try requireString(input, key: "source")
        let destination = try requireString(input, key: "destination")
        try FileManager.default.moveItem(atPath: source, toPath: destination)
        return successResponse(input: input, context: context, output: ["source": source, "destination": destination])
    }
}
