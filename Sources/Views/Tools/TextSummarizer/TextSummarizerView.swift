import SwiftUI

struct TextSummarizerView: View {
    @StateObject private var backend = TextSummarizerBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Input Text").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.inputText)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Summary Length")
                        Spacer()
                        Text("\(Int(backend.sentenceCount)) sentences").bold()
                    }
                    Slider(value: $backend.sentenceCount, in: 1...10, step: 1)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)

                Button(action: { Task { await backend.summarize() } }) {
                    if backend.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Label("Summarize With AI", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading || backend.inputText.isEmpty)

                if !backend.summaryText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Summary Result").font(.headline)
                            Spacer()
                            Button(action: { UIPasteboard.general.string = backend.summaryText }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        Text(backend.summaryText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.1)))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Text Summarizer")
    }
}

struct TextSummarizerTool: Tool {
    let name = "Text Summarizer"
    let icon = "text.quote"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Generate a concise summary of long articles or documents"
    let requiresAPI = true
    var view: AnyView { AnyView(TextSummarizerView()) }
}
