import Foundation

final class AppendFileTool: SystemTool {
    let name = "append_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let path = try requireString(input, key: "path")
        let content = try requireString(input, key: "content")
        let data = Data(content.utf8)
        if FileManager.default.fileExists(atPath: path) {
            let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } else {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
        return successResponse(input: input, context: context, output: ["path": path, "appended_bytes": data.count])
    }
}
