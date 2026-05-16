import Foundation

public final class SDKSourceScanner {
    public static let shared = SDKSourceScanner()

    private init() {}

    /// Scans the project source directory for 'import' statements to trace usage of frameworks and libraries.
    public func scanForImports(in directory: String = "Sources") async -> Set<String> {
        return await Task.detached(priority: .background) {
            self.performScan(in: directory)
        }.value
    }

    private func performScan(in directory: String) -> Set<String> {
        let fm = FileManager.default
        let rootURL = URL(fileURLWithPath: directory)
        var detectedImports = Set<String>()

        guard let enumerator = fm.enumerator(at: rootURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return detectedImports
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }

            if let content = try? String(contentsOf: fileURL) {
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("import ") {
                        let parts = trimmed.components(separatedBy: .whitespaces)
                        if parts.count >= 2 {
                            let moduleName = parts[1].replacingOccurrences(of: ";", with: "")
                            detectedImports.insert(moduleName)
                        }
                    }
                }
            }
        }

        return detectedImports
    }
}
