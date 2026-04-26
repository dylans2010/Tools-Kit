import Foundation

final class ApplyPatchTool: SystemTool {
    let name = "apply_patch"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let path = try requireString(input, key: "path")
        let patch = try requireString(input, key: "patch")
        let sourceURL = URL(fileURLWithPath: path)
        let current = try String(contentsOf: sourceURL, encoding: .utf8)
        var lines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        for rawLine in patch.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if rawLine.hasPrefix("+") && !rawLine.hasPrefix("+++") {
                lines.append(String(rawLine.dropFirst()))
            }
        }
        let patched = lines.joined(separator: "\n")
        try patched.write(to: sourceURL, atomically: true, encoding: .utf8)
        return successResponse(input: input, context: context, output: ["path": path, "patch_lines": patch.split(separator: "\n", omittingEmptySubsequences: false).count, "patched": true])
    }
}
