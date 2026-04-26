import Foundation

final class RefactorCodeTool: SystemTool {
    let name = "refactor_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let oldValue = try requireString(input, key: "old_text")
        let newValue = try requireString(input, key: "new_text")
        let root = toolsWorkingDirectory(from: input)
        let targetFiles: [URL]
        if let path = input["path"] as? String, !path.isEmpty {
            targetFiles = [try resolveFileURL(from: ["path": path, "workspacePath": root.path])]
        } else {
            targetFiles = enumerateFiles(root: root, allowedExtensions: ["swift", "md", "txt", "json", "yaml", "yml"])
        }

        var changed: [String] = []
        for file in targetFiles {
            guard var content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            guard content.contains(oldValue) else { continue }
            content = content.replacingOccurrences(of: oldValue, with: newValue)
            try content.write(to: file, atomically: true, encoding: .utf8)
            changed.append(file.path.replacingOccurrences(of: root.path + "/", with: ""))
        }

        return successResponse(input: input, context: context, output: [
            "files_changed": changed,
            "change_count": changed.count
        ])
    }
}
