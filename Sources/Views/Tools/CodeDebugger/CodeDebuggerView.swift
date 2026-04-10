import SwiftUI

struct CodeDebuggerView: View {
    @State private var code = ""
    @State private var analysis = ""
    @State private var isAnalyzing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextEditor(text: $code)
                    .frame(height: 250)
                    .font(.system(.body, design: .monospaced))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    .padding()

                Button(action: debug) {
                    if isAnalyzing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Analyze Code")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if !analysis.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Potential Issues", systemImage: "ladybug.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text(analysis)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Code Debugger")
    }

    private func debug() {
        isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            analysis = "1. Found potential memory leak in closure.\n2. Optional value should be unwrapped safely.\n3. Variable 'temp' is never used."
            isAnalyzing = false
        }
    }
}

struct CodeDebuggerTool: Tool {
    let name = "Code Debugger"
    let icon = "ant.fill"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Identify bugs and optimize logic in your source code"
    let requiresAPI = true
    var view: AnyView { AnyView(CodeDebuggerView()) }
}
