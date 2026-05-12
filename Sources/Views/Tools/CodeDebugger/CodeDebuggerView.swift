import SwiftUI

struct CodeDebuggerView: View {
    @StateObject private var backend = CodeDebuggerBackend()
    @State private var code: String = ""

    var body: some View {
        ToolDetailView(tool: CodeDebuggerTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Source Code") {
                    TextEditor(text: $code)
                        .frame(height: 200)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                }

                Button(action: {
                    Task { await backend.debugCode(code) }
                }) {
                    if backend.isProcessing {
                        ProgressView()
                    } else {
                        Text("Analyze & Debug")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.isEmpty || backend.isProcessing)

                if !backend.analysis.isEmpty {
                    ToolOutputView("Analysis Results", value: backend.analysis)
                }
            }
        }
    }
}

struct CodeDebuggerTool: Tool, Sendable {
    let name = "Code Debugger"
    let icon = "ant.circle"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "AI-powered debugging to identify and fix code issues"
    let requiresAPI = true
    var view: AnyView { AnyView(CodeDebuggerView()) }
}
