import SwiftUI

struct TranslateEmailView: View {
    let sourceText: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    enum TranslationTone: String, CaseIterable, Identifiable, Hashable {
        case preserve = "Preserve Tone"
        case formal = "Formal"
        case neutral = "Neutral"
        case friendly = "Friendly"

        var id: String { rawValue }
    }

    enum TranslationMode: String, CaseIterable, Identifiable, Hashable {
        case direct = "Direct"
        case polished = "Polished"
        case concise = "Concise"

        var id: String { rawValue }
    }

    @State private var sourceLanguage = "English"
    @State private var targetLanguage = "Spanish"
    @State private var tone: TranslationTone = .preserve
    @State private var mode: TranslationMode = .polished
    @State private var preserveFormatting = true
    @State private var includeCulturalNotes = false

    @State private var translatedText = ""
    @State private var backTranslation = ""
    @State private var qualityNotes = ""

    @State private var isTranslating = false
    @State private var isGeneratingChecks = false
    @State private var errorMessage: String?

    private let languages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese", "Dutch", "Japanese", "Korean", "Chinese", "Arabic", "Hindi"
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

    private var estimatedSourceWords: Int {
        sourceText.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var translatedWordCount: Int {
        translatedText.split { $0.isWhitespace || $0.isNewline }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    languageCard
                    inputCard
                    outputCard
                    qualityCard

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Translate Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline.weight(.semibold))
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await translate() }
                    } label: {
                        Label("Translate", systemImage: "globe")
                            .symbolEffect(.bounce.byLayer, isActive: isTranslating)
                    }
                    .disabled(!canTranslate)

                    Button {
                        onApply(translatedText)
                        dismiss()
                    } label: {
                        Label("Apply", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(!canApply)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Smart Translation")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Translate with tone control, readability checks, and back-translation validation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                statPill("Source", "\(estimatedSourceWords) words")
                statPill("Result", translatedText.isEmpty ? "—" : "\(translatedWordCount) words")
                statPill("Mode", mode.rawValue)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Language & Style", systemImage: "globe")
                .font(.headline)

            HStack(spacing: 10) {
                languagePicker("From", selection: $sourceLanguage)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        let from = sourceLanguage
                        sourceLanguage = targetLanguage
                        targetLanguage = from
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .padding(10)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                languagePicker("To", selection: $targetLanguage)
            }

            HStack(spacing: 10) {
                simplePicker("Tone", selection: $tone)
                simplePicker("Mode", selection: $mode)
            }

            Toggle(isOn: $preserveFormatting) {
                Label("Preserve formatting and bullet structure", systemImage: "text.alignleft")
            }
            Toggle(isOn: $includeCulturalNotes) {
                Label("Include cultural nuance notes", systemImage: "text.badge.star")
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Original", systemImage: "doc.text")
                .font(.headline)

            ScrollView {
                Text(sourceText.isEmpty ? "Message body is empty." : sourceText)
                    .foregroundStyle(sourceText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 130)
            .padding(12)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .cardSurface()
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Translated", systemImage: "character.bubble")
                    .font(.headline)
                Spacer()
                if isTranslating {
                    ProgressView()
                }
            }

            if translatedText.isEmpty {
                Text("Translation will appear here.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                TextEditor(text: $translatedText)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    actionButton("Copy", symbol: "doc.on.doc") {
                        UIPasteboard.general.string = translatedText
                    }
                    actionButton("Back-Translate", symbol: "arrow.uturn.backward") {
                        Task { await runBackTranslation() }
                    }
                    .disabled(isGeneratingChecks)
                    actionButton("Quality Check", symbol: "checkmark.shield") {
                        Task { await runQualityCheck() }
                    }
                    .disabled(isGeneratingChecks)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var qualityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Validation", systemImage: "checklist")
                .font(.headline)

            if isGeneratingChecks {
                ProgressView("Analyzing translation…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !backTranslation.isEmpty {
                qualityBlock(title: "Back Translation", body: backTranslation)
            }

            if !qualityNotes.isEmpty {
                qualityBlock(title: "Quality Notes", body: qualityNotes)
            }

            if backTranslation.isEmpty && qualityNotes.isEmpty {
                Text("Run Back-Translate or Quality Check to validate clarity and intent.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func qualityBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(body)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func actionButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
        }
        .buttonStyle(.bordered)
    }

    private func languagePicker(_ label: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker(label, selection: selection) {
                ForEach(languages, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func simplePicker<T: CaseIterable & Identifiable & RawRepresentable & Hashable>(_ title: String, selection: Binding<T>) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(Array(T.allCases), id: \.id) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#0A1118") ?? .black, Color(hex: "#122233") ?? .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor
    private func translate() async {
        guard !isTranslating else { return }
        isTranslating = true
        errorMessage = nil
        translatedText = ""
        backTranslation = ""
        qualityNotes = ""

        defer { isTranslating = false }

        do {
            let prompt = """
            Translate this email from \(sourceLanguage) to \(targetLanguage).
            Tone: \(tone.rawValue)
            Style: \(mode.rawValue)
            Preserve formatting: \(preserveFormatting ? "yes" : "no")
            Include cultural notes inline: \(includeCulturalNotes ? "yes" : "no")

            Return only the translated email body.

            Email:
            \(sourceText)
            """
            translatedText = try await AIService.shared.processText(prompt: prompt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func runBackTranslation() async {
        guard !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isGeneratingChecks = true
        defer { isGeneratingChecks = false }

        do {
            let prompt = "Back-translate the following text from \(targetLanguage) to \(sourceLanguage). Return only the back-translated text.\n\n\(translatedText)"
            backTranslation = try await AIService.shared.processText(prompt: prompt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func runQualityCheck() async {
        guard !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isGeneratingChecks = true
        defer { isGeneratingChecks = false }

        do {
            let prompt = """
            Review this translation for accuracy, tone alignment, and readability.
            Provide concise bullet points and one recommended improvement.

            Source (\(sourceLanguage)):
            \(sourceText)

            Translation (\(targetLanguage)):
            \(translatedText)
            """
            qualityNotes = try await AIService.shared.processText(prompt: prompt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension View {
    func cardSurface() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
    }
}
