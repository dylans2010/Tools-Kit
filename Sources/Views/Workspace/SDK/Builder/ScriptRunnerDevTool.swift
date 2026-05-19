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
    @State private var script = "// SDK Automation Hook\nconsole.log('Initializing workflow...');\nToolsKit.sync();\nconsole.log('Sync complete.');"

    var body: some View {
        List {
            Section("Logic Console") {
                VStack(spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        TextEditor(text: $script)
                            .frame(height: 200)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)

                        Button {
                            UIPasteboard.general.string = script
                        } label: {
                            Image(systemName: "doc.on.doc").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }

                    HStack {
                        Menu {
                            Button("Health Check Loop") { script = "while(true) { check(); wait(1000); }" }
                            Button("Batch Processing") { script = "items.forEach(i => process(i));" }
                        } label: {
                            Label("Templates", systemImage: "text.badge.plus")
                        }
                        .font(.caption2)

                        Spacer()

                        Button {
                            Task { await viewModel.run(script) }
                        } label: {
                            if viewModel.isRunning {
                                ProgressView().controlSize(.small)
                            } else {
                                Label("Execute Script", systemImage: "play.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isRunning)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Output Trace") {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView {
                        Text(viewModel.output)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 150)
                    .background(Color.black)
                    .cornerRadius(8)

                    HStack {
                        Text("Exit Code: \(viewModel.isRunning ? "--" : "0")")
                        Spacer()
                        Button("Clear Terminal") { viewModel.output = "" }
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Automation")
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

#Preview {
    ScriptRunnerView()
}
