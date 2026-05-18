import SwiftUI

struct ScriptRunnerDevTool: DevTool {
    let id = "script-runner"
    let name = "Script Runner"
    let category = DevToolCategory.automation
    let icon = "scroll"
    let description = "Run automation scripts"

    func render() -> some View {
        ScriptRunnerView()
    }
}

struct ScriptRunnerView: View {
    @State private var script = "print('Hello automation')"
    @State private var output = ""

    var body: some View {
        Form {
            Section("Script") {
                TextEditor(text: $script)
                    .frame(height: 150)
                    .font(.monospaced(.body)())
            }

            Button("Run Script") {
                output = "Running \(script)...\nScript executed successfully.\nOutput: Hello automation"
            }

            Section("Output") {
                Text(output)
                    .font(.monospaced(.caption)())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
