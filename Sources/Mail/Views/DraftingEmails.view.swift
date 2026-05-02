import SwiftUI

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    @Environment(\.dismiss) private var dismiss

    enum MailGoal: String, CaseIterable, Identifiable {
        case statusUpdate = "Status Update", followUp = "Follow Up", request = "Request", apology = "Apology"
        var id: String { rawValue }
    }

    enum MailStyle: String, CaseIterable, Identifiable {
        case professional = "Professional", friendly = "Friendly", executive = "Executive", concise = "Concise"
        var id: String { rawValue }
    }

    @State private var recipient = ""
    @State private var subject = ""
    @State private var context = ""
    @State private var selectedGoal: MailGoal = .statusUpdate
    @State private var selectedStyle: MailStyle = .professional
    @State private var isGenerating = false
    @State private var generatedBody = ""

    let currentBody: String
    let onApply: (DraftingEmailResult) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        VStack(spacing: 16) {
                            inputField(label: "Recipient", text: $recipient, placeholder: "email@example.com")
                            inputField(label: "Subject", text: $subject, placeholder: "Enter subject")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Context")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                TextEditor(text: $context)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        VStack(spacing: 12) {
                            HStack {
                                Text("Goal")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("", selection: $selectedGoal) {
                                    ForEach(MailGoal.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }

                            HStack {
                                Text("Style")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("", selection: $selectedStyle) {
                                    ForEach(MailStyle.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))

                        if !generatedBody.isEmpty {
                            outputPreview
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
                .safeAreaInset(edge: .bottom) {
                    generateButton
                }

                if isGenerating {
                    loadingOverlay
                }
            }
            .navigationTitle("Drafting Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "pencil.and.outline")
                .font(.title)
                .foregroundStyle(.blue)
            Text("Advanced Drafting")
                .font(.headline)
            Text("Tailor your message with precision.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func inputField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .padding(12)
                .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var outputPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Draft Result")
                    .font(.subheadline.bold())
                Spacer()
                Button("Use Draft") {
                    onApply(.init(recipient: recipient, subject: subject, body: generatedBody))
                    dismiss()
                }
                .font(.caption.bold())
                .foregroundStyle(.blue)
            }

            Text(generatedBody)
                .font(.subheadline)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            Text("Generate Draft")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(context.isEmpty ? Color.gray.opacity(0.3) : Color.blue, in: Capsule())
                .foregroundStyle(.white)
        }
        .disabled(context.isEmpty || isGenerating)
        .padding()
        .background(.ultraThinMaterial)
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.6).ignoresSafeArea()
            .overlay(ProgressView("Drafting...").tint(.white))
    }

    private func generate() async {
        isGenerating = true
        do {
            let prompt = """
            Write a highly effective, \(selectedStyle.rawValue) email.
            Goal: \(selectedGoal.rawValue)
            Context: \(context)

            Ensure the tone is perfectly aligned with \(selectedStyle.rawValue) expectations.
            Include a clear subject line and a strong call to action.
            Use professional formatting and structure.
            """
            let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are an expert executive communications assistant. Your emails are clear, impactful, and follow industry best practices for professional correspondence.")
            await MainActor.run {
                generatedBody = result
                isGenerating = false
            }
        } catch {
            await MainActor.run { isGenerating = false }
        }
    }
}
