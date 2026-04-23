import SwiftUI

struct AIWriteView: View {
    @Environment(\.dismiss) private var dismiss

    enum EmailType: String, CaseIterable, Identifiable {
        case general = "General"
        case followup = "Follow Up"
        case request = "Request"
        case invitation = "Invitation"
        case response = "Response"
        case apology = "Apology"
        case sales = "Sales"
        case thankYou = "Thank You"
        case announcement = "Announcement"
        case reminder = "Reminder"
        case update = "Update"
        case outreach = "Outreach"
        case onboarding = "Onboarding"

        var id: String { rawValue }
    }

    enum Tone: String, CaseIterable, Identifiable {
        case professional = "Professional"
        case friendly = "Friendly"
        case concise = "Concise"
        case urgent = "Urgent"
        case empathetic = "Empathetic"
        case confident = "Confident"
        case formal = "Formal"
        case warm = "Warm"
        case direct = "Direct"
        case appreciative = "Appreciative"
        case diplomatic = "Diplomatic"
        case visionary = "Visionary"
        case reassuring = "Reassuring"

        var id: String { rawValue }
    }

    enum ReadingLevel: String, CaseIterable, Identifiable {
        case plain = "Plain"
        case standard = "Standard"
        case elevated = "Elevated"
        case conversational = "Conversational"
        case executive = "Executive"

        var id: String { rawValue }
    }

    @State private var emailType: EmailType = .general
    @State private var tone: Tone = .professional
    @State private var prompt: String = ""
    @State private var readingLevel: ReadingLevel = .standard
    @State private var includeSubjectLine = true
    @State private var includeCallToAction = true
    @State private var includeBulletSummary = false
    @State private var includeAlternativeSubject = true
    @State private var includePolishedClosing = true
    @State private var isGenerating = false
    @State private var generatedContent = ""
    @State private var errorMessage: String?

    private let quickPrompts = [
        ("Project Update", "Send a concise status update with blockers and next steps."),
        ("Client Follow Up", "Write a warm follow-up after a meeting with clear actions."),
        ("Invitation", "Invite someone to a meeting with a clear agenda and timing."),
        ("Apology", "Draft a thoughtful apology that takes ownership and offers a fix.")
    ]

    let onCompletion: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "#1A1A2E") ?? .black, Color(hex: "#16213E") ?? .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        optionsSection
                        inputSection

                        if !generatedContent.isEmpty {
                            outputSection
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(16)
                }

                MailAILoadingView(
                    isActive: isGenerating,
                    title: "Generating Email",
                    subtitle: "Building a structured response with your selected tone"
                )
            }
            .navigationTitle("AI Writer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Generate") {
                        Task { await generate() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.isEmpty || isGenerating)
                }
            }
        }
    }

    private var headerSection: some View {
        MailAITitleHeader(
            title: "Spark Intelligence",
            subtitle: "Describe what you want to say, and I'll draft the perfect email.",
            symbol: "apple.intelligence",
            symbolSize: 16
        )
    }

    private var optionsSection: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickPrompts, id: \.0) { item in
                        Button {
                            prompt = item.1
                        } label: {
                            Text(item.0)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text("Type")
                    .font(.caption.bold())
                Spacer()
                Picker("Type", selection: $emailType) {
                    ForEach(EmailType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            HStack {
                Text("Tone")
                    .font(.caption.bold())
                Spacer()
                Picker("Tone", selection: $tone) {
                    ForEach(Tone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            HStack {
                Text("Reading Level")
                    .font(.caption.bold())
                Spacer()
                Picker("Reading Level", selection: $readingLevel) {
                    ForEach(ReadingLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Toggle("Include Subject Line", isOn: $includeSubjectLine)
                .font(.caption.bold())
            Toggle("Include Call To Action", isOn: $includeCallToAction)
                .font(.caption.bold())
            Toggle("Include Bullet Summary", isOn: $includeBulletSummary)
                .font(.caption.bold())
            Toggle("Include Alternate Subject", isOn: $includeAlternativeSubject)
                .font(.caption.bold())
            Toggle("Write Polished Closing", isOn: $includePolishedClosing)
                .font(.caption.bold())
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's the email about?")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            TextEditor(text: $prompt)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Result")
                    .font(.headline)
                Spacer()
                Button {
                    onCompletion(generatedContent)
                    dismiss()
                } label: {
                    Text("Use This")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple, in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            ScrollView {
                Text(generatedContent)
                    .font(.subheadline)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxHeight: 300)
        }
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil

        do {
            let aiPrompt = """
            Write a \(tone.rawValue.lowercased()) \(emailType.rawValue.lowercased()) email about:
            \(prompt)
            Reading level: \(readingLevel.rawValue.lowercased()).
            Include subject line: \(includeSubjectLine ? "yes" : "no").
            Include explicit call-to-action: \(includeCallToAction ? "yes" : "no").
            Include bullet summary: \(includeBulletSummary ? "yes" : "no").
            Include alternate subject options: \(includeAlternativeSubject ? "yes" : "no").
            Include polished closing: \(includePolishedClosing ? "yes" : "no").

            Return only the email body.
            """

            let result = try await AIService.shared.processText(prompt: aiPrompt)
            await MainActor.run {
                generatedContent = result.trimmingCharacters(in: .whitespacesAndNewlines)
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
}
