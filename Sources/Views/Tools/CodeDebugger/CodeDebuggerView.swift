import SwiftUI

struct CodeDebuggerView: View {
    @State private var code = ""
    @State private var analysis = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextEditor(text: $code)
                    .frame(height: 250)
                    .font(.system(.body, design: .monospaced))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    .padding()

                Button(action: { Task { await debug() } }) {
                    if isAnalyzing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Analyze Code")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(code.isEmpty || isAnalyzing)

                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).padding()
                }

                if !analysis.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("AI Analysis", systemImage: "ladybug.fill")
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

    private func debug() async {
        isAnalyzing = true
        errorMessage = nil
        do {
            analysis = try await aiService.debugCode(code: code)
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }
}

struct CodeDebuggerTool: Tool {
    let id = UUID()
    let name = "Code Debugger"
    let icon = "ant.fill"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Identify bugs and optimize logic in your source code"
    let requiresAPI = true
    var view: AnyView { AnyView(CodeDebuggerView()) }
}
