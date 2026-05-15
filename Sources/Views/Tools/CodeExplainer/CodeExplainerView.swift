import SwiftUI

struct CodeExplainerView: View {
    @StateObject private var backend = CodeExplainerBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Paste Code Snippet").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.code)
                        .frame(minHeight: 180)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                Button {
                    Task { await backend.explain() }
                } label: {
                    if backend.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Label("Explain Structure", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isProcessing || backend.code.isEmpty)

                if !backend.explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analysis Summary")
                            .font(.headline)

                        Text(backend.explanation)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)

                        Text("Components Found")
                            .font(.headline)

                        ForEach(backend.components, id: \.name) { component in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(component.type)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)

                                    Text(component.name)
                                        .font(.subheadline).bold()
                                }

                                Text(component.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Code Explainer")
    }
}

struct CodeExplainerTool: Tool {
    let name = "Code Explainer"
    let icon = "curlybraces.square.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Analyze and explain the structure of your code snippets"
    let requiresAPI = true
    var view: AnyView { AnyView(CodeExplainerView()) }
}
