import SwiftUI

struct AIWriteView: View {
    @Environment(\.dismiss) private var dismiss

    enum EmailType: String, CaseIterable, Identifiable {
        case general = "General", followup = "Follow Up", request = "Request", apology = "Apology", update = "Update"
        var id: String { rawValue }
    }

    enum Tone: String, CaseIterable, Identifiable {
        case professional = "Professional", friendly = "Friendly", concise = "Concise", urgent = "Urgent"
        var id: String { rawValue }
    }

    @State private var emailType: EmailType = .general
    @State private var tone: Tone = .professional
    @State private var prompt: String = ""
    @State private var isGenerating = false
    @State private var generatedContent = ""
    @State private var errorMessage: String?

    let onCompletion: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    headerSection

                    VStack(spacing: 12) {
                        HStack {
                            Picker("Type", selection: $emailType) {
                                ForEach(EmailType.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu)

                            Picker("Tone", selection: $tone) {
                                ForEach(Tone.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(8)
                        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))

                        TextEditor(text: $prompt)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Group {
                                    if prompt.isEmpty {
                                        Text("What should I write?")
                                            .foregroundStyle(.secondary)
                                            .padding(.leading, 12)
                                            .padding(.top, 16)
                                            .allowsHitTesting(false)
                                    }
                                }, alignment: .topLeading
                            )
                    }

                    if !generatedContent.isEmpty {
                        outputSection
                    }

                    Spacer()

                    generateButton
                }
                .padding(20)

                if isGenerating {
                    loadingOverlay
                }
            }
            .navigationTitle("AI Writer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .top, endPoint: .bottom))
            Text("Draft with Intelligence")
                .font(.headline)
            Text("Provide a few details and let AI do the heavy lifting.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            Text(isGenerating ? "Thinking..." : "Generate Draft")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(prompt.isEmpty ? Color.gray.opacity(0.3) : Color.blue, in: Capsule())
                .foregroundStyle(.white)
        }
        .disabled(prompt.isEmpty || isGenerating)
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Result")
                    .font(.subheadline.bold())
                Spacer()
                Button("Apply") {
                    onCompletion(generatedContent)
                    dismiss()
                }
                .font(.caption.bold())
                .foregroundStyle(.blue)
            }

            ScrollView {
                Text(generatedContent)
                    .font(.subheadline)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxHeight: 200)
        }
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.6).ignoresSafeArea()
            .overlay(ProgressView("Generating...").tint(.white))
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil
        do {
            let fullPrompt = """
            Write a \(tone.rawValue) \(emailType.rawValue) email based on this description:
            \(prompt)

            Guidelines:
            - Tone: \(tone.rawValue)
            - Type: \(emailType.rawValue)
            - Ensure clarity and professionalism.
            - Use appropriate greetings and sign-offs.
            """
            let result = try await AIService.shared.processText(prompt: fullPrompt, systemPrompt: "You are an AI writing assistant specializing in email communications. You help users draft clear, effective, and well-structured emails tailored to their specific needs.")
            await MainActor.run {
                generatedContent = result
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
