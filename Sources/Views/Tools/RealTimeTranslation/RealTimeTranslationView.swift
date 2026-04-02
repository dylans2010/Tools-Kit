import SwiftUI

struct RealTimeTranslationView: View {
    @StateObject private var backend = RealTimeTranslationBackend()

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Language Selection")) {
                    HStack {
                        Picker("From", selection: $backend.sourceLanguage) {
                            ForEach(backend.languages.keys.sorted(), id: \.self) { key in
                                Text(backend.languages[key] ?? "").tag(key)
                            }
                        }

                        Spacer()

                        Button(action: {
                            let temp = backend.sourceLanguage
                            backend.sourceLanguage = backend.targetLanguage
                            backend.targetLanguage = temp
                            backend.translate()
                        }) {
                            Image(systemName: "arrow.left.arrow.right")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Picker("To", selection: $backend.targetLanguage) {
                            ForEach(backend.languages.keys.sorted(), id: \.self) { key in
                                Text(backend.languages[key] ?? "").tag(key)
                            }
                        }
                    }
                }

                Section(header: Text("Input Text")) {
                    TextEditor(text: $backend.inputText)
                        .frame(height: 120)
                        .onChange(of: backend.inputText) { _ in
                            backend.translate()
                        }
                }

                Section(header: Text("Translation")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if backend.isTranslating {
                            ProgressView()
                        }

                        Text(backend.translatedText)
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !backend.translatedText.isEmpty {
                            Button(action: { UIPasteboard.general.string = backend.translatedText }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Real-time Translation")
    }
}

struct RealTimeTranslationTool: Tool {
    let name = "Real-time Translation"
    let icon = "character.book.closed"
    let category = ToolCategory.general
    let complexity = ToolComplexity.basic
    let description = "Instant text translation as you type"
    let requiresAPI = false // Functional simulation
    var view: AnyView { AnyView(RealTimeTranslationView()) }
}
