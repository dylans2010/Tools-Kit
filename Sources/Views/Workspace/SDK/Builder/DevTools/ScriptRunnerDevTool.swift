import SwiftUI

struct ScriptRunnerTool: DevTool {
    let id = UUID()
    let name = "Script Runner"
    let category: DevToolCategory = .automation
    let icon = "play.rectangle"
    let description = "Write and execute Swift-like scripts"
    func render() -> some View { ScriptRunnerDevToolView() }
}

struct ScriptRunnerDevToolView: View {
    @State private var script = "// Write expressions to evaluate\nlet greeting = \"Hello, World!\"\nprint(greeting)"
    @State private var output = ""
    @State private var isRunning = false
    @State private var history: [(String, String, Date)] = []

    var body: some View {
        Form {
            Section("Script") {
                TextEditor(text: $script)
                    .frame(minHeight: 120)
                    .font(.system(.body, design: .monospaced))
            }
            Section {
                Button(action: runScript) {
                    HStack {
                        Label("Run", systemImage: "play.fill")
                        if isRunning { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(script.isEmpty || isRunning)
                Button("Clear Output") { output = "" }
            }
            if !output.isEmpty {
                Section("Output") {
                    Text(output)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            Section("Snippets") {
                Button("Date Info") { script = "let now = Date()\nprint(\"Current: \\(now)\")\nprint(\"Timestamp: \\(now.timeIntervalSince1970)\")" }
                Button("UUID Generator") { script = "for i in 1...5 {\n    print(\"\\(i). \\(UUID().uuidString)\")\n}" }
                Button("System Info") { script = "print(\"OS: \\(ProcessInfo.processInfo.operatingSystemVersionString)\")\nprint(\"Memory: \\(ProcessInfo.processInfo.physicalMemory / 1_073_741_824) GB\")" }
            }
            if !history.isEmpty {
                Section("History (\(history.count))") {
                    ForEach(Array(history.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.0.prefix(50)).font(.caption).lineLimit(1)
                            Text(entry.1.prefix(100)).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                            Text(entry.2, style: .time).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Script Runner")
    }

    private func runScript() {
        isRunning = true
        output = ""
        DispatchQueue.global().async {
            var result = ""
            let lines = script.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }
                if trimmed.hasPrefix("print(") {
                    let content = trimmed.dropFirst(6).dropLast(1)
                    result += evaluateExpression(String(content)) + "\n"
                } else if trimmed.contains("let ") || trimmed.contains("var ") {
                    result += "Declared: \(trimmed)\n"
                } else {
                    result += "Eval: \(trimmed)\n"
                }
            }
            DispatchQueue.main.async {
                output = result.trimmingCharacters(in: .whitespacesAndNewlines)
                history.insert((script, output, Date()), at: 0)
                if history.count > 10 { history.removeLast() }
                isRunning = false
            }
        }
    }

    private func evaluateExpression(_ expr: String) -> String {
        let cleaned = expr.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\(Date())", with: Date().description)
            .replacingOccurrences(of: "\\(UUID().uuidString)", with: UUID().uuidString)
        return cleaned
    }
}
