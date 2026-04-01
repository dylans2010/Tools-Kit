import SwiftUI

struct RealTimeTranslationView: View {
    @StateObject private var backend = RealTimeTranslationBackend()

    var body: some View {
        Form {
            Section(header: Text("Language Selection")) {
                Picker("From", selection: $backend.sourceLanguage) {
                    ForEach(Array(backend.languages.keys.sorted()), id: \.self) { key in
                        Text(backend.languages[key] ?? "").tag(key)
                    }
                }

                Button("Switch Languages") {
                    let temp = backend.sourceLanguage
                    backend.sourceLanguage = backend.targetLanguage
                    backend.targetLanguage = temp
                }

                Picker("To", selection: $backend.targetLanguage) {
                    ForEach(Array(backend.languages.keys.sorted()), id: \.self) { key in
                        Text(backend.languages[key] ?? "").tag(key)
                    }
                }
            }

            Section(header: Text("Input Text")) {
                TextEditor(text: $backend.inputText)
                    .frame(height: 100)
                    .onChange(of: backend.inputText) { _ in
                        backend.translate()
                    }
            }

            Section(header: Text("Live Translation")) {
                Text(backend.translatedText)
                    .font(.headline)
                    .foregroundColor(.blue)
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
    let description = "Real-time text translation"
    let requiresAPI = true

    var view: AnyView {
        AnyView(RealTimeTranslationView())
    }
}
