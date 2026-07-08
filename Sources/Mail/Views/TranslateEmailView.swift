import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TranslateEmailView: View {
    let sourceText: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sourceLanguage = "English"
    @State private var targetLanguage = "Spanish"
    @State private var translatedText = ""
    @State private var translatedSubject = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?
    @State private var translationTone = "Natural"
    @State private var formality = "Auto"
    @State private var preserveLineBreaks = true
    @State private var keepNamesUntranslated = true
    @State private var includeLocalizedDateStyle = false
    @State private var preserveMarkdownFormatting = true
    @State private var translateSubjectLine = true
    @State private var keepEmojiAndASCIIArt = true
    @State private var localizeHonorifics = false
    @State private var showAdvancedOptions = false

    struct LanguageOption: Identifiable, Hashable {
        let id = UUID()
        let code: String
        let displayName: String
        let nativeName: String
        let flag: String
    }

    private let languages: [LanguageOption] = [
        .init(code: "en", displayName: "English", nativeName: "English", flag: "🇺🇸"),
        .init(code: "es", displayName: "Spanish", nativeName: "Español", flag: "🇪🇸"),
        .init(code: "fr", displayName: "French", nativeName: "Français", flag: "🇫🇷"),
        .init(code: "de", displayName: "German", nativeName: "Deutsch", flag: "🇩🇪"),
        .init(code: "it", displayName: "Italian", nativeName: "Italiano", flag: "🇮🇹"),
        .init(code: "pt", displayName: "Portuguese", nativeName: "Português", flag: "🇵🇹"),
        .init(code: "nl", displayName: "Dutch", nativeName: "Nederlands", flag: "🇳🇱"),
        .init(code: "ja", displayName: "Japanese", nativeName: "日本語", flag: "🇯🇵"),
        .init(code: "ko", displayName: "Korean", nativeName: "한국어", flag: "🇰🇷"),
        .init(code: "zh", displayName: "Chinese", nativeName: "中文", flag: "🇨🇳"),
        .init(code: "ar", displayName: "Arabic", nativeName: "العربية", flag: "🇸🇦"),
        .init(code: "hi", displayName: "Hindi", nativeName: "हिन्दी", flag: "🇮🇳"),
        .init(code: "pl", displayName: "Polish", nativeName: "Polski", flag: "🇵🇱"),
        .init(code: "tr", displayName: "Turkish", nativeName: "Türkçe", flag: "🇹🇷"),
        .init(code: "sv", displayName: "Swedish", nativeName: "Svenska", flag: "🇸🇪"),
        .init(code: "vi", displayName: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳"),
        .init(code: "ru", displayName: "Russian", nativeName: "Русский", flag: "🇷🇺"),
        .init(code: "id", displayName: "Indonesian", nativeName: "Bahasa Indonesia", flag: "🇮🇩"),
        .init(code: "th", displayName: "Thai", nativeName: "ไทย", flag: "🇹🇭"),
        .init(code: "cs", displayName: "Czech", nativeName: "Čeština", flag: "🇨🇿"),
        .init(code: "da", displayName: "Danish", nativeName: "Dansk", flag: "🇩🇰"),
        .init(code: "fi", displayName: "Finnish", nativeName: "Suomi", flag: "🇫🇮"),
        .init(code: "el", displayName: "Greek", nativeName: "Ελληνικά", flag: "🇬🇷"),
        .init(code: "hu", displayName: "Hungarian", nativeName: "Magyar", flag: "🇭🇺"),
        .init(code: "no", displayName: "Norwegian", nativeName: "Norsk", flag: "🇳🇴"),
        .init(code: "ro", displayName: "Romanian", nativeName: "Română", flag: "🇷🇴"),
        .init(code: "sk", displayName: "Slovak", nativeName: "Slovenčina", flag: "🇸🇰"),
        .init(code: "uk", displayName: "Ukrainian", nativeName: "Українська", flag: "🇺🇦"),
        .init(code: "he", displayName: "Hebrew", nativeName: "עברית", flag: "🇮🇱"),
        .init(code: "ms", displayName: "Malay", nativeName: "Bahasa Melayu", flag: "🇲🇾")
    ]
    private let toneOptions = ["Natural", "Business", "Friendly", "Diplomatic", "Direct", "Warm", "Concise"]
    private let formalityOptions = ["Auto", "Formal", "Informal"]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 20) {
                        headerSection

                        languageSection

                        displayCard(title: "Original", icon: "doc.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sourceText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        if !translatedText.isEmpty && !isTranslating {
                            displayCard(title: "Translation", icon: "character.bubble", isResult: true) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Translated from \(sourceLanguage)")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1), in: Capsule())
                                            .foregroundStyle(.blue)
                                        Spacer()
                                    }

                                    if !translatedSubject.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Subject")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.secondary)
                                            Text(translatedSubject)
                                                .font(.subheadline.bold())
                                        }
                                        Divider()
                                    }

                                    ScrollView {
                                        if preserveMarkdownFormatting && detectMarkdown(translatedText) {
                                            MailMarkdownRenderer(source: translatedText, schema: EmailTranslationTool().outputSchema)
                                        } else {
                                            Text(translatedText)
                                                .font(.subheadline)
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .textSelection(.enabled)
                                        }
                                    }
                                    .frame(minHeight: 140)

                                    HStack(spacing: 12) {
                                        Button {
                                            UIPasteboard.general.string = translatedText
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                                .font(.caption.bold())
                                                .padding(.vertical, 8)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.white.opacity(0.1), in: Capsule())
                                        }

                                        Button {
                                            onApply(translatedText)
                                            dismiss()
                                        } label: {
                                            Label("Insert", systemImage: "arrow.right.circle.fill")
                                                .font(.caption.bold())
                                                .padding(.vertical, 8)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.blue, in: Capsule())
                                                .foregroundStyle(.white)
                                        }

                                        Button {
                                            Task { await translate() }
                                        } label: {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.caption.bold())
                                                .padding(8)
                                                .background(Color.white.opacity(0.1), in: Circle())
                                        }
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

            }
            .aiAnimationLoading(isTranslating)
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

    @State private var searchText = ""

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    languagePicker(selection: $sourceLanguage)
                }

                Button {
                    let temp = sourceLanguage
                    sourceLanguage = targetLanguage
                    targetLanguage = temp

                    let tempText = sourceText
                    // In a real app we'd swap current source and translated but sourceText is let
                    // Let's just swap state
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.bold())
                        .padding(8)
                        .background(Color.blue.opacity(0.1), in: Circle())
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Target")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    languagePicker(selection: $targetLanguage)
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

    private func languagePicker(selection: Binding<String>) -> some View {
        Menu {
            ForEach(languages) { lang in
                Button("\(lang.flag) \(lang.displayName)") {
                    selection.wrappedValue = lang.displayName
                }
            }
        } label: {
            HStack {
                let current = languages.first(where: { $0.displayName == selection.wrappedValue })
                Text("\(current?.flag ?? "") \(selection.wrappedValue)")
                    .font(.subheadline.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1), in: Capsule())
        }
    }

    private func detectMarkdown(_ text: String) -> Bool {
        let patterns = ["^#", "^- ", "^\\* ", "^> ", "\\*\\*"]
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
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
                                .foregroundStyle(selection.wrappedValue == option ? Color.white : Color.secondary)
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
                .foregroundStyle(isResult ? Color.blue : Color.secondary)

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
            colors: [Color(hex: "#05070F"), Color(hex: "#101A31"), Color(hex: "#1B1231")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor
    private func translate() async {
        isTranslating = true
        errorMessage = nil

        guard let tool = MailAIToolRegistry.shared.tool(for: "email_translation") else { return }

        do {
            let prompt = """
            Source Language: \(sourceLanguage)
            Target Language: \(targetLanguage)
            Tone: \(translationTone)
            Formality: \(formality)

            Options:
            - Preserve line breaks: \(preserveLineBreaks)
            - Keep names untranslated: \(keepNamesUntranslated)
            - Localize dates: \(includeLocalizedDateStyle)
            - Preserve markdown: \(preserveMarkdownFormatting)

            Input to translate:
            \(sourceText)
            """

            let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: tool.systemPrompt)

            if let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                await MainActor.run {
                    translatedSubject = json["subject"] ?? ""
                    translatedText = json["body"] ?? ""
                    isTranslating = false
                }
            } else {
                // Fallback if AI didn't return JSON
                await MainActor.run {
                    translatedText = result
                    isTranslating = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isTranslating = false
            }
        }
    }
}
