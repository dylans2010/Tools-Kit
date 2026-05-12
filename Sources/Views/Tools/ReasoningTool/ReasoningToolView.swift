import SwiftUI

struct ReasoningToolView: View {
    @StateObject private var backend = ReasoningToolBackend()
    @State private var problem: String = ""

    var body: some View {
        ToolDetailView(tool: ReasoningTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Problem or Query") {
                    TextEditor(text: $problem)
                        .frame(height: 120)
                        .padding(8)
                }

                Button(action: {
                    Task { await backend.solve(problem: problem) }
                }) {
                    if backend.isProcessing {
                        ProgressView()
                    } else {
                        Text("Think & Solve")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(problem.isEmpty || backend.isProcessing)

                if !backend.thoughtProcess.isEmpty {
                    ToolOutputView("Reasoning", value: backend.thoughtProcess)
                }
            }
        }
    }
}

struct ReasoningTool: Tool, Sendable {
    let name = "Reasoning Engine"
    let icon = "brain"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Chain-of-thought AI to help solve complex logical problems"
    let requiresAPI = true
    var view: AnyView { AnyView(ReasoningToolView()) }

    func execute() async throws -> Any? {
        // This allows ToolManager to execute it if needed, but the view has its own state
        return nil
    }
}
