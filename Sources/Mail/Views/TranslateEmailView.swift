import SwiftUI
import UIKit

struct TranslateEmailView: View {
    let sourceText: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var targetLanguage = "Spanish"
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?
    @State private var translationTone = "Natural"
    @State private var formality = "Professional"
    @State private var preserveLineBreaks = true
    @State private var keepNamesUntranslated = true
    @State private var includeLocalizedDateStyle = false
    @State private var preserveMarkdownFormatting = true
    @State private var translateSubjectLine = true
    @State private var keepEmojiAndASCIIArt = true
    @State private var localizeHonorifics = false
    @State private var showAdvancedOptions = false

    private let languages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese", "Dutch", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Polish", "Turkish", "Swedish", "Vietnamese"
    ]
    private let toneOptions = ["Natural", "Business", "Friendly", "Diplomatic", "Direct", "Warm", "Concise"]
    private let formalityOptions = ["Professional", "Neutral", "Formal", "Informal", "Executive"]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 20) {
                        headerSection

                        languageSection

                        displayCard(title: "Original", icon: "doc.text") {
                            Text(sourceText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !translatedText.isEmpty && !isTranslating {
                            displayCard(title: "Translation", icon: "character.bubble", isResult: true) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ScrollView {
                                        Text(translatedText)
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                    }
                                    .frame(minHeight: 140)

                                    HStack {
                                        Spacer()
                                        Button {
                                            UIPasteboard.general.string = translatedText
                                        } label: {
                                            Label("Copy Translation", systemImage: "doc.on.doc")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                    }
                                }
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
                .scrollBounceBehavior(.basedOnSize)

                MailAILoadingView(
                    isActive: isTranslating,
                    title: "Translating message",
                    subtitle: "Preserving tone, meaning, and context"
                )
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
        MailAITitleHeader(
            title: "Translate Emails",
            subtitle: "Translate your message while maintaining its original intent.",
            symbol: "apple.intelligence",
            symbolSize: 16
        )
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

            Divider().overlay(Color.white.opacity(0.15))

            compactSelector(title: "Tone", selection: $translationTone, options: toneOptions)
            compactSelector(title: "Formality", selection: $formality, options: formalityOptions)

            DisclosureGroup("Advanced translation controls", isExpanded: $showAdvancedOptions) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Preserve line breaks and paragraph layout", isOn: $preserveLineBreaks)
                    Toggle("Keep names and proper nouns as-is", isOn: $keepNamesUntranslated)
                    Toggle("Use localized date/number formatting", isOn: $includeLocalizedDateStyle)
                    Toggle("Preserve markdown formatting", isOn: $preserveMarkdownFormatting)
                    Toggle("Translate subject line too", isOn: $translateSubjectLine)
                    Toggle("Keep emoji / ASCII art", isOn: $keepEmojiAndASCIIArt)
                    Toggle("Localize honorifics", isOn: $localizeHonorifics)
                }
                .font(.caption.bold())
                .padding(.top, 8)
            }
            .font(.caption.bold())
        }
        .padding(16)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func compactSelector(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection.wrappedValue = option
                        } label: {
                            Text(option)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selection.wrappedValue == option ? Color.blue : Color.white.opacity(0.1), in: Capsule())
                                .foregroundStyle(selection.wrappedValue == option ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func displayCard<Content: View>(title: String, icon: String, isResult: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(isResult ? .blue : .secondary)

            content()
                .padding(12)
                .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(isResult ? Color.blue.opacity(0.05) : Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isResult ? Color.blue.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1))
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#05070F") ?? .black, Color(hex: "#101A31") ?? .black, Color(hex: "#1B1231") ?? .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
            - Tone: \(translationTone).
            - Formality: \(formality).
            - Preserve line breaks: \(preserveLineBreaks ? "yes" : "no").
            - Keep names/proper nouns unchanged when possible: \(keepNamesUntranslated ? "yes" : "no").
            - Localize dates and number formatting: \(includeLocalizedDateStyle ? "yes" : "no").
            - Preserve markdown formatting: \(preserveMarkdownFormatting ? "yes" : "no").
            - Translate the subject line too: \(translateSubjectLine ? "yes" : "no").
            - Keep emoji / ASCII art: \(keepEmojiAndASCIIArt ? "yes" : "no").
            - Localize honorifics and titles: \(localizeHonorifics ? "yes" : "no").
            - Do not explain the translation.
            - Return only the translated email text. DO NOT SAY ANYTHING ELSE

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
