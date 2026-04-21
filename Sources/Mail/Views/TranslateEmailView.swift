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

                if isTranslating {
                    sheetLoadingOverlay(
                        title: "Translating message",
                        subtitle: "Preserving tone, meaning, and context"
                    )
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
            Text("Translate Emails")
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
            colors: [Color(hex: "#05070F") ?? .black, Color(hex: "#101A31") ?? .black, Color(hex: "#1B1231") ?? .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func sheetLoadingOverlay(title: String, subtitle: String) -> some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.58), Color.blue.opacity(0.25), Color.indigo.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                TimelineView(.animation) { timeline in
                    let phase = timeline.date.timeIntervalSinceReferenceDate
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 118, height: 118)
                        Circle()
                            .trim(from: 0.1, to: 0.8)
                            .stroke(AngularGradient(colors: [.cyan, .blue, .purple, .cyan], center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 118, height: 118)
                            .rotationEffect(.degrees(phase * 140))
                        Image(systemName: "character.bubble.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 118)

                Text(title).font(.title3.weight(.semibold)).foregroundStyle(.white)
                Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }
            .padding(24)
        }
        .transition(.opacity)
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
