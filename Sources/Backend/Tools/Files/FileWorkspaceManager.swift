import Foundation

struct FileWorkspaceManager: Sendable {
    let rootURL: URL

    init(workspaceName: String = "FilesWorkspace") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        rootURL = documents.appendingPathComponent(workspaceName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: rootURL.path) {
            try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
    }

    func uniqueURL(for fileName: String, fileExtension: String? = nil) -> URL {
        var baseName = fileName
        var ext = fileExtension

        if ext == nil, !fileName.isEmpty {
            let url = URL(fileURLWithPath: fileName)
            if !url.pathExtension.isEmpty {
                ext = url.pathExtension
                baseName = url.deletingPathExtension().lastPathComponent
            }
        }

        var candidate = rootURL.appendingPathComponent(baseName)
        if let ext, !ext.isEmpty {
            candidate = candidate.appendingPathExtension(ext)
        }

        var index = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            var fallback = rootURL.appendingPathComponent("\(baseName)-\(index)")
            if let ext, !ext.isEmpty {
                fallback = fallback.appendingPathExtension(ext)
            }
            candidate = fallback
            index += 1
        }
        return candidate
    }
}
