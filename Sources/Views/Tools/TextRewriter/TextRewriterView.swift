import SwiftUI

struct TextRewriterView: View {
    @StateObject private var backend = TextRewriterBackend()
    @State private var selectedTone: RewriteTone = .professional

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Original Text").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.inputText)
                        .frame(minHeight: 150)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                HStack {
                    Picker("Target Tone", selection: $selectedTone) {
                        ForEach(RewriteTone.allCases, id: \.self) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(.menu)
                    .buttonStyle(.bordered)

                    Button(action: { Task { await backend.rewrite(to: selectedTone) } }) {
                        if backend.isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Rewrite")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isProcessing || backend.inputText.isEmpty)
                }

                if !backend.rewrittenText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Rewritten Text").font(.headline)
                            Spacer()
                            Button(action: { UIPasteboard.general.string = backend.rewrittenText }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        Text(backend.rewrittenText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.1)))
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Text Rewriter")
    }
}

struct TextRewriterTool: Tool, Sendable {
    let name = "Text Rewriter"
    let icon = "pencil.tip.crop.circle.badge.plus"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Change the tone and style of your text while keeping the meaning"
    let requiresAPI = true
    var view: AnyView { AnyView(TextRewriterView()) }
}
