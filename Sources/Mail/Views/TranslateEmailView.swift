import SwiftUI

struct TranslateEmailView: View {
    let sourceText: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sourceLanguage = "English"
    @State private var targetLanguage = "Spanish"
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?

    private let languages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese", "Japanese", "Korean", "Chinese", "Arabic"
    ]

    private var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canTranslate: Bool {
        !trimmedSourceText.isEmpty && !isTranslating
    }

    private var canApply: Bool {
        !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Languages") {
                    Picker("From", selection: $sourceLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }

                    Picker("To", selection: $targetLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                }

                Section("Input") {
                    Text(sourceText.isEmpty ? "Message body is empty." : sourceText)
                        .foregroundStyle(sourceText.isEmpty ? .secondary : .primary)
                }

                Section("Output") {
                    if isTranslating {
                        ProgressView("Translating…")
                    } else {
                        Text(translatedText.isEmpty ? "Translation will appear here." : translatedText)
                            .foregroundStyle(translatedText.isEmpty ? .secondary : .primary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Translate Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Translate") {
                        Task { await translate() }
                    }
                    .disabled(!canTranslate)

                    Button("Apply") {
                        onApply(translatedText)
                        dismiss()
                    }
                    .disabled(!canApply)
                }
            }
        }
    }

    @MainActor
    private func translate() async {
        guard !isTranslating else { return }
        isTranslating = true
        errorMessage = nil
        translatedText = ""

        do {
            let prompt = """
            Translate the following email from \(sourceLanguage) to \(targetLanguage).
            Preserve meaning, formatting, and links.

            Email:
            \(sourceText)
            """
            translatedText = try await AIService.shared.processText(prompt: prompt)
        } catch {
            errorMessage = error.localizedDescription
        }

        isTranslating = false
    }
}
