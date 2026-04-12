import SwiftUI

struct IdeaGeneratorView: View {
    @StateObject private var backend = IdeaGeneratorBackend()

    var body: some View {
        ToolDetailView(tool: IdeaGeneratorTool()) {
            VStack(spacing: 20) {
                ToolInputSection("Focus Area") {
                    TextField("What kind of idea do you want?", text: $backend.topic)
                        .padding()
                }

                Button {
                    Task { await backend.generate() }
                } label: {
                    if backend.isProcessing {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    } else {
                        Label("Generate Ideas", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isProcessing)

                ToolInputSection("Ideas") {
                    if backend.ideas.isEmpty {
                        Text("No ideas yet. Generate a batch to get started.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        ForEach(backend.ideas, id: \.self) { idea in
                            HStack(alignment: .top) {
                                Text(idea)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(action: { UIPasteboard.general.string = idea }) {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                            .padding()
                            if idea != backend.ideas.last { Divider() }
                        }
                    }
                }

                if !backend.ideas.isEmpty {
                    Button("Clear", role: .destructive) {
                        backend.clear()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

struct IdeaGeneratorTool: Tool {
    let name = "Idea Generator"
    let icon = "lightbulb.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Generate innovative app and business ideas"
    let requiresAPI = true
    var view: AnyView { AnyView(IdeaGeneratorView()) }
}
