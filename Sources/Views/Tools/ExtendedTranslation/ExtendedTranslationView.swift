import SwiftUI

struct ExtendedTranslationView: View {
    @StateObject private var backend = ExtendedTranslationBackend()

    let languages = [
        "en-US": "English (US)",
        "es-ES": "Spanish",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian",
        "ja-JP": "Japanese",
        "zh-CN": "Chinese"
    ]

    var body: some View {
        Form {
            Section(header: Text("Languages")) {
                Picker("Source", selection: $backend.sourceLanguage) {
                    ForEach(languages.keys.sorted(), id: \.self) { key in
                        Text(languages[key] ?? key).tag(key)
                    }
                }
                .onChange(of: backend.sourceLanguage) { newValue in
                    backend.updateSourceLanguage(newValue)
                }

                Picker("Target", selection: $backend.targetLanguage) {
                    ForEach(languages.keys.sorted(), id: \.self) { key in
                        Text(languages[key] ?? key).tag(key)
                    }
                }
            }

            Section(header: Text("Input Text or Voice")) {
                VStack(spacing: 12) {
                    HStack {
                        TextEditor(text: $backend.inputText)
                            .frame(height: 120)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

                        Button(action: backend.startSpeechToText) {
                            VStack {
                                Image(systemName: backend.isListening ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(backend.isListening ? .red : .blue)
                                Text(backend.isListening ? "Listening" : "Speak")
                                    .font(.caption2)
                            }
                        }
                    }

                    Button(action: backend.translate) {
                        if backend.isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Label("Translate", systemImage: "arrow.left.arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.inputText.isEmpty || backend.isProcessing)
                }
                .padding(.vertical, 8)
            }

            if !backend.translatedText.isEmpty {
                Section(header: Text("Translation")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(backend.translatedText)
                            .font(.headline)
                            .foregroundColor(.blue)

                        HStack {
                            Button(action: backend.playSpeech) {
                                Label("Speak", systemImage: "speaker.wave.2.fill")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: { UIPasteboard.general.string = backend.translatedText }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Extended Translation")
    }
}

struct ExtendedTranslationTool: Tool {
    let name = "Extended Translation"
    let icon = "text.bubble"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Multi-language translation with voice input and synthesis"
    let requiresAPI = false
    var view: AnyView { AnyView(ExtendedTranslationView()) }
}
