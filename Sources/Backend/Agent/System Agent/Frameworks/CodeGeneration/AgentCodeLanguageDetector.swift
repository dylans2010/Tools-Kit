import Foundation

public final class AgentCodeLanguageDetector {
    public init() {}

    public func detect(from code: String) -> String {
        if code.contains("import SwiftUI") || code.contains("func ") { return "swift" }
        if code.contains("import React") || code.contains("const ") { return "javascript" }
        if code.contains("import os") || code.contains("def ") { return "python" }
        if code.contains("<html>") { return "html" }
        return "text"
    }
}
