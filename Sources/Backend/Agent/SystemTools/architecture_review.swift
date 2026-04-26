import Foundation

final class ArchitectureReviewTool: SystemTool {
    let name = "architecture_review"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let root = toolsWorkingDirectory(from: input)
        let files = enumerateFiles(root: root)
        var byExtension: [String: Int] = [:]
        for file in files {
            let ext = file.pathExtension.isEmpty ? "none" : file.pathExtension
            byExtension[ext, default: 0] += 1
        }
        let swiftFiles = files.filter { $0.pathExtension == "swift" }
        let oversizedSwiftFiles = swiftFiles.filter {
            ((try? String(contentsOf: $0, encoding: .utf8).components(separatedBy: .newlines).count) ?? 0) > 500
        }.map { $0.lastPathComponent }
        return successResponse(input: input, context: context, output: [
            "root": root.path,
            "total_files": files.count,
            "file_types": byExtension,
            "oversized_swift_files": oversizedSwiftFiles
        ])
    }
}
