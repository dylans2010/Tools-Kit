import SwiftUI

struct AIWriteView: View {
    @Environment(\.dismiss) private var dismiss

    enum EmailType: String, CaseIterable, Identifiable {
        case general = "General", followup = "Follow Up", request = "Request", apology = "Apology", update = "Update"
        var id: String { rawValue }
    }

    enum Tone: String, CaseIterable, Identifiable {
        case professional = "Professional", friendly = "Friendly", concise = "Concise", urgent = "Urgent", academic = "Academic"
        var id: String { rawValue }
    }

    enum AITool: String, CaseIterable, Identifiable {
        case write = "Write", rewrite = "Rewrite", shorten = "Shorten", expand = "Expand", formalize = "Formalize", proofread = "Proofread", suggestSubject = "Suggest Subject"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .write: return "pencil.and.outline"
            case .rewrite: return "arrow.triangle.2.circlepath"
            case .shorten: return "arrow.up.right.and.arrow.down.left.rectangle"
            case .expand: return "arrow.down.left.and.arrow.up.right.rectangle"
            case .formalize: return "briefcase.fill"
            case .proofread: return "checkmark.shield.fill"
            case .suggestSubject: return "text.quote"
            }
        }
    }

    @State private var emailType: EmailType = .general
    @State private var tone: Tone = .professional
    @State private var selectedTool: AITool = .write
    @State private var prompt: String = ""
    @State private var isGenerating = false
    @State private var generatedContent = ""
    @State private var errorMessage: String?

    let onCompletion: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                // Animated background glow
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)

                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 150, y: 200)

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        VStack(spacing: 20) {
                            toolsGrid

                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Email Type")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.secondary)
                                        Picker("Type", selection: $emailType) {
                                            ForEach(EmailType.allCases) { Text($0.rawValue).tag($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                    }

                                    Spacer()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tone")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.secondary)
                                        Picker("Tone", selection: $tone) {
                                            ForEach(Tone.allCases) { Text($0.rawValue).tag($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))

                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $prompt)
                                        .frame(height: 140)
                                        .skillPicker(text: $prompt)
                                        .padding(12)
                                        .scrollContentBackground(.hidden)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))

                                    if prompt.isEmpty {
                                        Text(placeholderText)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                        }

                        if !generatedContent.isEmpty {
                            outputSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .navigationTitle("AI Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                    .opacity(0.3)

                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .top, endPoint: .bottom))
            }

            Text("Draft with Precision")
                .font(.title3.bold())

            Text("Select a tool and provide context to generate high quality email content instantly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var toolsGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AITool.allCases) { tool in
                    Button {
                        withAnimation(.spring()) {
                            selectedTool = tool
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 20))
                            Text(tool.rawValue)
                                .font(.caption.bold())
                        }
                        .frame(width: 100, height: 80)
                        .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedTool == tool ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                        .foregroundStyle(selectedTool == tool ? Color.blue : Color.primary)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack {
                if isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "sparkles")
                    Text(buttonLabel)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: prompt.isEmpty ? [.gray.opacity(0.5)] : [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .foregroundStyle(.white)
            .shadow(color: (prompt.isEmpty ? Color.clear : Color.blue.opacity(0.3)), radius: 10, y: 5)
        }
        .disabled(prompt.isEmpty || isGenerating)
        .padding()
        .background(.ultraThinMaterial)
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Generated Draft", systemImage: "wand.and.stars")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    onCompletion(generatedContent)
                    dismiss()
                } label: {
                    Text("Insert Draft")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            ScrollView {
                Text(generatedContent)
                    .font(.subheadline)
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxHeight: 250)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("AI is processing...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var placeholderText: String {
        switch selectedTool {
        case .write: return "What should the email be about?"
        case .rewrite: return "Paste the text you want to rewrite..."
        case .shorten: return "Paste the text you want to shorten..."
        case .expand: return "Paste the text you want to expand..."
        case .formalize: return "Paste the text you want to make more professional..."
        case .proofread: return "Paste the text you want to proofread..."
        case .suggestSubject: return "Paste the email body to suggest a subject line..."
        }
    }

    private var buttonLabel: String {
        switch selectedTool {
        case .write: return "Generate Email"
        case .suggestSubject: return "Suggest Subject"
        default: return "Process with AI"
        }
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil
        do {
            let systemPrompt = "You are an AI writing assistant specializing in professional email communications. Help users draft, refine, and optimize their emails."
            let fullPrompt: String

            switch selectedTool {
            case .write:
                fullPrompt = "Write a \(tone.rawValue) \(emailType.rawValue) email based on this description: \(prompt)"
            case .rewrite:
                fullPrompt = "Rewrite the following text to be more \(tone.rawValue) and clear: \(prompt)"
            case .shorten:
                fullPrompt = "Make the following email text more concise and brief while maintaining a \(tone.rawValue) tone: \(prompt)"
            case .expand:
                fullPrompt = "Expand on the following email points to make it more detailed and comprehensive in a \(tone.rawValue) tone: \(prompt)"
            case .formalize:
                fullPrompt = "Transform the following text into a highly professional and formal email: \(prompt)"
            case .proofread:
                fullPrompt = "Proofread the following email for grammar, spelling, and flow improvements: \(prompt)"
            case .suggestSubject:
                fullPrompt = "Based on this email body, suggest 3 catchy and professional subject lines: \(prompt)"
            }

            let result = try await AIService.shared.processText(prompt: fullPrompt, systemPrompt: systemPrompt)
            await MainActor.run {
                withAnimation {
                    generatedContent = result
                }
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
