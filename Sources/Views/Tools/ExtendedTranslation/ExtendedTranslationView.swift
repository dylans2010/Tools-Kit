import SwiftUI

@available(macOS 11.0, *)
struct ExtendedTranslationView: View {
    @StateObject private var backend = ExtendedTranslationBackend()

    var body: some View {
        Form {
            Section(header: Text("Voice & Input")) {
                HStack {
                    TextEditor(text: $backend.inputText)
                        .frame(height: 100)

                    Button(action: {
                        backend.startSpeechToText()
                    }) {
                        Image(systemName: backend.isListening ? "mic.fill" : "mic")
                            .foregroundColor(backend.isListening ? .red : .blue)
                            .font(.title)
                    }
                    .padding()
                }

                Button("Translate Text") {
                    backend.translate()
                }
                .buttonStyle(.borderedProminent)
            }

            Section(header: Text("Translation Output")) {
                Text(backend.translatedText)
                    .font(.headline)
                    .foregroundColor(.blue)

                Button("Play Speech") {
                    backend.playSpeech()
                }
                .disabled(backend.translatedText.isEmpty)
            }
        }
        .navigationTitle("Extended Translation")
    }
}

@available(macOS 11.0, *)
struct ExtendedTranslationTool: Tool {
    let name = "Extended Translation"
    let icon = "text.bubble"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "AI translation with voice input/output"

    var view: AnyView {
        AnyView(ExtendedTranslationView())
    }
}
