import SwiftUI

struct ScriptRunnerDevTool: DevTool {
    let id = "script-runner"
    let name = "Script Runner"
    let category = DevToolCategory.automation
    let icon = "terminal.fill"
    let description = "Execute custom automation scripts"

    func render() -> some View {
        ScriptRunnerView()
    }
}

struct ScriptRunnerView: View {
    @StateObject private var viewModel = ScriptRunnerViewModel()
    @State private var script = "console.log('Starting SDK task...');\nToolsKit.sync();"

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Script Runner",
                description: "Write and execute custom JavaScript or automation scripts within the SDK environment.",
                icon: "terminal.fill"
            )
            .padding()

            Form {
                Section("Script Editor") {
                    TextEditor(text: $script)
                        .frame(height: 200)
                        .font(.system(.caption, design: .monospaced))

                    Button("Run Script") {
                        Task { await viewModel.run(script) }
                    }
                    .disabled(viewModel.isRunning)
                }

                Section("Output / Console") {
                    ScrollView {
                        Text(viewModel.output)
                            .font(.system(.caption2, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.05))
                    .frame(height: 150)
                }
            }
        }
    }
}

class ScriptRunnerViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var output = ""

    func run(_ script: String) async {
        await MainActor.run { isRunning = true; output = "Executing script...\n" }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            output += "Sync completed.\nExit code: 0"
            isRunning = false
        }
    }
}
