import SwiftUI

struct RealTimeTranslationView: View {
    @StateObject private var backend = RealTimeTranslationBackend()

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select your source and target languages, then type or paste text to translate it instantly.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Picker("From", selection: $backend.sourceLanguage) {
                            ForEach(backend.languages.keys.sorted(), id: \.self) { key in
                                Text(backend.languages[key] ?? "").tag(key)
                            }
                        }
                        .pickerStyle(.menu)

                        Spacer()

                        Button(action: {
                            let temp = backend.sourceLanguage
                            backend.sourceLanguage = backend.targetLanguage
                            backend.targetLanguage = temp
                            backend.translate()
                        }) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.title2)
                        }
                        .foregroundColor(.blue)

                        Spacer()

                        Picker("To", selection: $backend.targetLanguage) {
                            ForEach(backend.languages.keys.sorted(), id: \.self) { key in
                                Text(backend.languages[key] ?? "").tag(key)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Languages")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $backend.inputText)
                        .frame(minHeight: 120)
                        .cornerRadius(8)
                        .onChange(of: backend.inputText) { _ in
                            backend.translate()
                        }

                    if backend.inputText.isEmpty {
                        Text("Type here...")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
            } header: {
                Text("Input Text")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if backend.isTranslating {
                        HStack {
                            ProgressView()
                            Text("Translating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !backend.translatedText.isEmpty {
                        Text(backend.translatedText)
                            .font(.body.bold())
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)

                        HStack {
                            Button(action: { UIPasteboard.general.string = backend.translatedText }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: { backend.inputText = "" }) {
                                Label("Clear", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    } else if !backend.isTranslating {
                        Text("Your translation will appear here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Result")
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
