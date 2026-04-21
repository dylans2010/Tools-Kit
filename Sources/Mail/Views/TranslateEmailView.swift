import SwiftUI

struct TranslateEmailView: View {
    let sourceText: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var targetLanguage = "Spanish"
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?

    private let languages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese", "Dutch", "Japanese", "Korean", "Chinese", "Arabic", "Hindi"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        languageSection

                        displayCard(title: "Original", icon: "doc.text") {
                            Text(sourceText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if isTranslating {
                            ProgressView("Translating...")
                                .tint(.blue)
                                .padding()
                        } else if !translatedText.isEmpty {
                            displayCard(title: "Translation", icon: "character.bubble", isResult: true) {
                                ScrollView {
                                    Text(translatedText)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                }
                                .frame(minHeight: 150)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Translate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Translate") {
                        Task { await translate() }
                    }
                    .disabled(isTranslating)

                    if !translatedText.isEmpty {
                        Button("Apply") {
                            onApply(translatedText)
                            dismiss()
                        }
                        .bold()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Global Communication")
                .font(.headline)
                .foregroundStyle(.blue)
            Text("Translate your message while maintaining its original intent.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Language")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(languages, id: \.self) { lang in
                        Button {
                            targetLanguage = lang
                        } label: {
                            Text(lang)
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(targetLanguage == lang ? Color.blue : Color.white.opacity(0.1), in: Capsule())
                                .foregroundStyle(targetLanguage == lang ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func displayCard<Content: View>(title: String, icon: String, isResult: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(isResult ? .blue : .secondary)

            content()
                .padding(12)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(isResult ? Color.blue.opacity(0.05) : Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isResult ? Color.blue.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1))
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#050505") ?? .black, Color(hex: "#101018") ?? .black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @MainActor
    private func translate() async {
        isTranslating = true
        errorMessage = nil

        do {
            let prompt = """
            Translate the email below into \(targetLanguage).
            Rules:
            - Preserve meaning, names, dates, and intent.
            - Output MUST be in \(targetLanguage), not the source language.
            - Do not explain the translation.
            - Return only the translated email text.

            Email:
            \(sourceText)
            """
            var result = try await AIService.shared.processText(prompt: prompt)
            let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.caseInsensitiveCompare(sourceText.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame {
                let retryPrompt = """
                The previous output copied the source text.
                Translate this content to \(targetLanguage) now and ensure the output language is \(targetLanguage) only.
                Return only the final translated text:
                \(sourceText)
                """
                result = try await AIService.shared.processText(prompt: retryPrompt)
            }

            await MainActor.run {
                translatedText = result.trimmingCharacters(in: .whitespacesAndNewlines)
                isTranslating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isTranslating = false
            }
        }
    }
}
