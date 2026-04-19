import SwiftUI

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    enum MailStyle: String, CaseIterable, Identifiable, Hashable {
        case professional = "Professional"
        case friendly = "Friendly"
        case executive = "Executive"
        case persuasive = "Persuasive"

        var id: String { rawValue }
    }

    enum MailGoal: String, CaseIterable, Identifiable, Hashable {
        case statusUpdate = "Status Update"
        case followUp = "Follow Up"
        case proposal = "Proposal"
        case support = "Support"
        case introduction = "Introduction"

        var id: String { rawValue }
    }

    enum OutputLength: String, CaseIterable, Identifiable, Hashable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"

        var id: String { rawValue }
    }

    struct PromptPreset: Identifiable {
        let id = UUID()
        let title: String
        let subjectHint: String
        let descriptionHint: String
    }

    @Environment(\.dismiss) private var dismiss

    @State private var recipient = ""
    @State private var subject = ""
    @State private var context = ""
    @State private var mustInclude = ""
    @State private var selectedGoal: MailGoal = .statusUpdate
    @State private var selectedStyle: MailStyle = .professional
    @State private var selectedLength: OutputLength = .medium

    @State private var generatedBody = ""
    @State private var alternatives: [String] = []
    @State private var isGenerating = false
    @State private var isGeneratingAlternatives = false
    @State private var errorMessage: String?

    let currentBody: String
    let onApply: (DraftingEmailResult) -> Void

    private var canGenerate: Bool {
        !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    private var canApply: Bool {
        !generatedBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var draftWordCount: Int {
        generatedBody.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var presets: [PromptPreset] {
        [
            .init(title: "Executive Update", subjectHint: "Weekly Platform Update", descriptionHint: "Summarize outcomes, blockers, and decisions needed this week."),
            .init(title: "Polite Follow Up", subjectHint: "Following Up On Prior Request", descriptionHint: "Follow up respectfully and ask for a response by a clear deadline."),
            .init(title: "Proposal", subjectHint: "Proposal: Q3 Launch Strategy", descriptionHint: "Pitch a plan with timeline, expected impact, and next steps."),
            .init(title: "Customer Support", subjectHint: "Update On Your Support Case", descriptionHint: "Acknowledge issue, explain the fix, and set expectations for completion.")
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    setupCard
                    optionsCard
                    outputCard
                    alternativesCard
                }
                .padding(16)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Draft Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Generate") { Task { await generateDraft() } }
                        .disabled(!canGenerate)
                    Button("Apply") {
                        onApply(.init(recipient: recipient, subject: subject, body: generatedBody))
                        dismiss()
                    }
                    .disabled(!canApply)
                }
            }
            .onAppear {
                if generatedBody.isEmpty {
                    generatedBody = currentBody
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Write Better Emails Faster")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Set the intent and style, then generate a polished draft with alternates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets) { preset in
                        Button {
                            subject = preset.subjectHint
                            context = preset.descriptionHint
                        } label: {
                            Text(preset.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .draftingCardSurface()
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Message Setup", systemImage: "slider.horizontal.3")
                .font(.headline)

            Group {
                textField("Recipient", text: $recipient)
                textField("Subject", text: $subject)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("What should this email achieve?")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $context)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Must Include (optional)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $mustInclude)
                    .frame(minHeight: 72)
                    .padding(8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .draftingCardSurface()
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tone & Structure", systemImage: "text.bubble")
                .font(.headline)

            HStack(spacing: 10) {
                pickerChip(title: "Goal", selection: $selectedGoal)
                pickerChip(title: "Style", selection: $selectedStyle)
                pickerChip(title: "Length", selection: $selectedLength)
            }

            HStack(spacing: 10) {
                metricPill(title: "Words", value: "\(draftWordCount)")
                metricPill(title: "Goal", value: selectedGoal.rawValue)
                metricPill(title: "Tone", value: selectedStyle.rawValue)
            }
        }
        .padding(18)
        .draftingCardSurface()
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Draft", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                if isGenerating {
                    ProgressView()
                }
            }

            TextEditor(text: $generatedBody)
                .frame(minHeight: 220)
                .padding(8)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(18)
        .draftingCardSurface()
    }

    private var alternativesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Alternatives", systemImage: "square.stack.3d.up")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await generateAlternatives() }
                } label: {
                    if isGeneratingAlternatives {
                        ProgressView()
                    } else {
                        Text("Generate 2")
                    }
                }
                .disabled(generatedBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingAlternatives)
            }

            if alternatives.isEmpty {
                Text("Generate variants to compare voice and directness.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(alternatives.enumerated()), id: \.offset) { item in
                        Button {
                            generatedBody = item.element
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Variant \(item.offset + 1)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(item.element)
                                    .font(.subheadline)
                                    .lineLimit(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .draftingCardSurface()
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func pickerChip<T: CaseIterable & Identifiable & RawRepresentable & Hashable>(title: String, selection: Binding<T>) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(Array(T.allCases), id: \.id) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#0A0E16") ?? .black, Color(hex: "#11192A") ?? .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @MainActor
    private func generateDraft() async {
        guard !isGenerating else { return }
        isGenerating = true
        errorMessage = nil

        do {
            let prompt = """
            Write a \(selectedLength.rawValue.lowercased()) \(selectedStyle.rawValue.lowercased()) email.
            Goal: \(selectedGoal.rawValue).
            Recipient: \(recipient.isEmpty ? "Not specified" : recipient)
            Subject hint: \(subject.isEmpty ? "Generate one" : subject)

            Context:
            \(context)

            Must include:
            \(mustInclude.isEmpty ? "None" : mustInclude)

            Return plain email body only.
            """

            let result = try await AIService.shared.processText(prompt: prompt)
            generatedBody = result.trimmingCharacters(in: .whitespacesAndNewlines)

            if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let subjectPrompt = "Create one concise email subject line for this draft:\n\(generatedBody)"
                let generatedSubject = try await AIService.shared.processText(prompt: subjectPrompt)
                subject = generatedSubject
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    @MainActor
    private func generateAlternatives() async {
        guard !isGeneratingAlternatives else { return }
        isGeneratingAlternatives = true
        defer { isGeneratingAlternatives = false }

        do {
            let prompt = """
            Rewrite this email into 2 alternatives:
            - Version 1: more concise
            - Version 2: warmer tone

            Keep intent and key details.
            Output with separator: ===

            Email:
            \(generatedBody)
            """
            let result = try await AIService.shared.processText(prompt: prompt)
            let parts = result
                .components(separatedBy: "===")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            alternatives = Array(parts.prefix(2))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension View {
    func draftingCardSurface() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
