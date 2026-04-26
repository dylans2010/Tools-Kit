import Foundation

struct AgentCodeLanguageDetector {
    func detect(from code: String) -> String {
        let lowered = code.lowercased()
        if lowered.contains("import swift") || lowered.contains("struct ") { return "swift" }
        if lowered.contains("def ") || lowered.contains("import os") { return "python" }
        if lowered.contains("function ") || lowered.contains("const ") { return "javascript" }
        return "plaintext"
    }
}
