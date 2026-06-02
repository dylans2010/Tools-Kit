import SwiftUI

struct SecretScannerDevTool: DevTool {
    let id = "secret-scanner"
    let name = "Secret Scanner"
    let category: DevToolCategory = .security
    let icon = "magnifyingglass.circle"
    let description = "Scan text for accidentally exposed secrets and API keys"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste code to scan") { input in
            var findings: [String] = []
            if input.range(of: "sk-[a-zA-Z0-9]{20,}", options: .regularExpression) != nil { findings.append("Potential OpenAI API key detected") }
            if input.range(of: "AKIA[A-Z0-9]{16}", options: .regularExpression) != nil { findings.append("Potential AWS Access Key detected") }
            if input.range(of: "ghp_[a-zA-Z0-9]{36}", options: .regularExpression) != nil { findings.append("Potential GitHub token detected") }
            return findings.isEmpty ? "No secrets detected." : "Findings:\n" + findings.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
