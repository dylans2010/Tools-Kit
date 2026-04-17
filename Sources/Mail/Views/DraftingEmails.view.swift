import SwiftUI

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    enum EmailType: String, CaseIterable {
        case business = "Business"
        case update = "Update"
        case followUp = "Follow-Up"
        case support = "Support"
        case invitation = "Invitation"
    }

    enum EmailTone: String, CaseIterable {
        case professional = "Professional"
        case friendly = "Friendly"
        case formal = "Formal"
        case concise = "Concise"
    }

    enum EmailLength: String, CaseIterable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
    }

    @Environment(\.dismiss) private var dismiss

    @State private var recipient = ""
    @State private var subject = ""
    @State private var emailType: EmailType = .business
    @State private var tone: EmailTone = .professional
    @State private var length: EmailLength = .medium
    @State private var description = ""
    @State private var additionalContext = ""
    @State private var keywords = ""

    @State private var isGenerating = false
    @State private var generatedBody = ""
    @State private var errorMessage: String?

    let currentBody: String
    let onApply: (DraftingEmailResult) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Email Details") {
                    TextField("Email Recipient", text: $recipient)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Email Subject", text: $subject)
                    Picker("Email Type", selection: $emailType) {
                        ForEach(EmailType.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Tone", selection: $tone) {
                        ForEach(EmailTone.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Length", selection: $length) {
                        ForEach(EmailLength.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } footer: {
                    Text("Recipient should be a single email address for best results.")
                }

                Section("Prompt Inputs") {
                    TextField("Email Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Additional Context", text: $additionalContext, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Keywords (comma separated)", text: $keywords)
                }

                Section {
                    Button {
                        generateDraft()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                            }
                            Text(isGenerating ? "Drafting..." : "Generate Draft")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isGenerating)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if !generatedBody.isEmpty {
                    Section("Generated Draft") {
                        if let parsed = try? AttributedString(markdown: generatedBody) {
                            Text(parsed)
                        } else {
                            Text(generatedBody)
                        }

                        Button("Apply To Composer") {
                            onApply(
                                DraftingEmailResult(
                                    recipient: recipient,
                                    subject: subject,
                                    body: generatedBody
                                )
                            )
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("AI Writing Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func generateDraft() {
        isGenerating = true
        errorMessage = nil

        let prompt = """
        Draft an email using the following user-selected fields:
        Recipient: \(recipient)
        Subject: \(subject)
        Type: \(emailType.rawValue)
        Tone: \(tone.rawValue)
        Length: \(length.rawValue)
        Description: \(description)
        Additional Context: \(additionalContext)
        Keywords: \(keywords)

        Existing body context:
        \(currentBody)

        Return a fully drafted email body that is ready to send.
        """

        Task {
            do {
                let draft = try await MailAIService.shared.composeEmail(
                    prompt: prompt,
                    systemPrompt: MailAIToolsSystem.draftingSystemPrompt
                )

                await MainActor.run {
                    generatedBody = draft
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
}
