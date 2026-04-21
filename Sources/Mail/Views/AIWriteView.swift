import SwiftUI

struct AIWriteView: View {
    @Environment(\.dismiss) private var dismiss

    enum EmailType: String, CaseIterable, Identifiable {
        case followUp = "Follow Up"
        case proposal = "Proposal"
        case update = "Status Update"
        case support = "Support"
        case intro = "Introduction"

        var id: String { rawValue }
    }

    enum Tone: String, CaseIterable, Identifiable {
        case professional = "Professional"
        case friendly = "Friendly"
        case direct = "Direct"
        case empathetic = "Empathetic"

        var id: String { rawValue }
    }

    @State private var emailType: EmailType = .followUp
    @State private var tone: Tone = .professional
    @State private var details = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    let onApply: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Picker("Email type", selection: $emailType) {
                    ForEach(EmailType.allCases) { Text($0.rawValue).tag($0) }
                }

                Picker("Tone", selection: $tone) {
                    ForEach(Tone.allCases) { Text($0.rawValue).tag($0) }
                }

                Section("Details") {
                    TextField("What should the email include?", text: $details, axis: .vertical)
                        .lineLimit(4...8)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("AI Write")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await generate() }
                    } label: {
                        if isGenerating { ProgressView() } else { Text("Generate") }
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }

    private func generate() async {
        guard MailRuntimeSettings.aiSmartReplyEnabled else {
            errorMessage = "AI writing is disabled in Mail Settings."
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let prompt = """
            Write a complete email.
            Type: \(emailType.rawValue)
            Tone: \(tone.rawValue)
            Include: \(details)
            Return only the final email body.
            """
            let generated = try await MailAIService.shared.composeEmail(prompt: prompt)
            onApply(generated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
