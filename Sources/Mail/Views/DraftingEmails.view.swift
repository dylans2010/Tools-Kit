import SwiftUI
import Aurora

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    @Environment(\.dismiss) private var dismiss

    enum MailGoal: String, CaseIterable, Identifiable {
        case statusUpdate = "Status Update", followUp = "Follow Up", request = "Request", apology = "Apology", introduction = "Introduction", pitch = "Pitch"
        var id: String { rawValue }
    }

    enum MailStyle: String, CaseIterable, Identifiable {
        case professional = "Professional", friendly = "Friendly", executive = "Executive", concise = "Concise", persuasive = "Persuasive"
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

                // Ambient glow
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection

                        VStack(spacing: 20) {
                            modernInputField(label: "Recipient", text: $recipient, placeholder: "example@email.com", icon: "person.fill")
                            modernInputField(label: "Subject", text: $subject, placeholder: "What is this about?", icon: "tag.fill")

                            VStack(alignment: .leading, spacing: 10) {
                                Label("Context & Details", systemImage: "text.alignleft")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)

                                TextEditor(text: $context)
                                    .frame(height: 140)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }

                        VStack(spacing: 16) {
                            HStack {
                                Label("Primary Goal", systemImage: "target")
                                    .font(.subheadline.bold())
                                Spacer()
                                Picker("", selection: $selectedGoal) {
                                    ForEach(MailGoal.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(.blue)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            HStack {
                                Label("Communication Style", systemImage: "paintpalette.fill")
                                    .font(.subheadline.bold())
                                Spacer()
                                Picker("", selection: $selectedStyle) {
                                    ForEach(MailStyle.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(.purple)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if !generatedBody.isEmpty {
                            outputPreview
                                .transition(.scale.combined(with: .opacity))
                        }

                        Spacer(minLength: 120)
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
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glowWhileLoading(isGenerating) {
            CustomGlow(anchorAmp: 0.5, anchorSpd: 2.5, flameAmp: 3.0, decayRate: 1.2)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "apple.intelligence")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                .padding(.bottom, 4)

            Text("Email Assist")
                .font(.title2.bold())

            Text("Draft a perfect email with AI.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func modernInputField(label: String, text: Binding<String>, placeholder: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }

    private var outputPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Draft Preview", systemImage: "doc.text.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    onApply(.init(recipient: recipient, subject: subject, body: generatedBody))
                    dismiss()
                } label: {
                    Text("Apply To Email")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            ScrollView {
                Text(generatedBody)
                    .font(.subheadline)
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.blue.opacity(0.2), lineWidth: 1.5))
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate AI Draft")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: context.isEmpty ? [.gray.opacity(0.5)] : [.blue, .indigo], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .foregroundStyle(.white)
            .shadow(color: context.isEmpty ? .clear : .blue.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(context.isEmpty || isGenerating)
        .padding()
        .background(.ultraThinMaterial)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                Text("Drafting Your Email...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
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
                withAnimation {
                    generatedBody = result
                }
                isGenerating = false
            }
        } catch {
            await MainActor.run { isGenerating = false }
        }
    }
}
