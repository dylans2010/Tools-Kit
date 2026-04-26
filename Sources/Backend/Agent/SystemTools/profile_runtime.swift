import Foundation

final class ProfileRuntimeTool: SystemTool {
    let name = "profile_runtime"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let operation = (input["operation"] as? String) ?? "directory_scan"
        let start = CFAbsoluteTimeGetCurrent()
        let output: [String: Any]

        switch operation {
        case "directory_scan":
            let root = toolsWorkingDirectory(from: input)
            let files = enumerateFiles(root: root)
            output = ["operation": operation, "file_count": files.count, "root": root.path]
        case "json_decode":
            let fileURL = try resolveFileURL(from: input)
            let data = try Data(contentsOf: fileURL)
            _ = try JSONSerialization.jsonObject(with: data)
            output = ["operation": operation, "bytes": data.count, "path": fileURL.path]
        default:
            throw SystemToolError.unsupportedOperation(operation)
        }

        let end = CFAbsoluteTimeGetCurrent()
        var merged = output
        merged["duration_ms"] = (end - start) * 1000
        return successResponse(input: input, context: context, output: [
            "result": merged
        ])
    }
}
