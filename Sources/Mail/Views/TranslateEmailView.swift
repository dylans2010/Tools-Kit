import SwiftUI

struct TranslateEmailView: View {
    let sourceText: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sourceLanguage = "English"
    @State private var targetLanguage = "Spanish"
    @State private var outputStyle: OutputStyle = .natural
    @State private var preserveFormatting = true

    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?

    enum OutputStyle: String, CaseIterable, Identifiable {
        case natural = "Natural"
        case formal = "Formal"
        case concise = "Concise"

        var id: String { rawValue }
    }

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
            ScrollView {
                VStack(spacing: 14) {
                    languageCard
                    styleCard
                    inputCard
                    outputCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(cardBackground)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
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

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Languages", systemImage: "globe")
                .font(.headline)

            HStack(spacing: 10) {
                modernLanguagePicker("From", selection: $sourceLanguage)

                Button {
                    swap(&sourceLanguage, &targetLanguage)
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.top, 16)

                modernLanguagePicker("To", selection: $targetLanguage)
            }
        }
        .padding()
        .background(cardBackground)
    }

    private var styleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Output", systemImage: "slider.horizontal.3")
                .font(.headline)

            Picker("Style", selection: $outputStyle) {
                ForEach(OutputStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Preserve formatting and links", isOn: $preserveFormatting)
                .toggleStyle(.switch)
        }
        .padding()
        .background(cardBackground)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Input", systemImage: "text.quote")
                    .font(.headline)
                Spacer()
                Text("\(sourceText.trimmingCharacters(in: .whitespacesAndNewlines).count) chars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Text(sourceText.isEmpty ? "Message body is empty." : sourceText)
                    .foregroundStyle(sourceText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 130)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(cardBackground)
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Output", systemImage: "character.bubble")
                    .font(.headline)
                Spacer()
                if !translatedText.isEmpty {
                    Button {
                        UIPasteboard.general.string = translatedText
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }

            if isTranslating {
                ProgressView("Translating…")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 32)
            } else if translatedText.isEmpty {
                Text("Translation will appear here.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 32)
            } else {
                markdownView(translatedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(cardBackground)
    }

    private func modernLanguagePicker(_ label: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker(label, selection: selection) {
                ForEach(languages, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func markdownView(_ text: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributed)
        } else {
            Text(text)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    @MainActor
    private func translate() async {
        guard !isTranslating else { return }
        isTranslating = true
        errorMessage = nil
        translatedText = ""

        let styleInstruction: String = {
            switch outputStyle {
            case .natural: return "Use a natural, native-sounding tone."
            case .formal: return "Use a formal and professional tone."
            case .concise: return "Keep the translation concise while preserving meaning."
            }
        }()

        let formattingInstruction = preserveFormatting
            ? "Preserve original formatting, bullets, and links."
            : "You may simplify formatting if needed."

        do {
            let prompt = """
            Translate the following email from \(sourceLanguage) to \(targetLanguage).
            \(styleInstruction)
            \(formattingInstruction)

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
