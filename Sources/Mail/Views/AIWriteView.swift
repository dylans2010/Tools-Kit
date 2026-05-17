import SwiftUI
import Aurora

struct AIWriteView: View {
    @Environment(\.dismiss) private var dismiss

    enum Tone: String, CaseIterable, Identifiable {
        case formal = "Formal", friendly = "Friendly", assertive = "Assertive", concise = "Concise", diplomatic = "Diplomatic"
        var id: String { rawValue }
    }

    @State private var selectedToolID: String = EmailDraftingTool().toolID
    @State private var selectedTone: Tone = .friendly
    @State private var prompt: String = ""
    @State private var isGenerating = false
    @State private var streamBuffer: String = ""
    @State private var generatedContent: String = ""
    @State private var errorMessage: String?
    @State private var insufficientInputFields: [String] = []

    @State private var inputTokens: Int = 0
    @State private var outputTokens: Int = 0

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

                            if !insufficientInputFields.isEmpty {
                                errorBanner
                            }

                            VStack(spacing: 12) {
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
            }
            .aiAnimationLoading(isGenerating)
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
                ForEach(MailAIToolRegistry.shared.allTools(), id: \.toolID) { tool in
                    Button {
                        withAnimation(.spring()) {
                            selectedToolID = tool.toolID
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: icon(for: tool.toolID))
                                .font(.system(size: 20))
                            Text(tool.displayName)
                                .font(.caption.bold())
                        }
                        .frame(width: 100, height: 80)
                        .background(selectedToolID == tool.toolID ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedToolID == tool.toolID ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                        .foregroundStyle(selectedToolID == tool.toolID ? Color.blue : Color.primary)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func icon(for id: String) -> String {
        switch id {
        case "email_drafting": return "pencil.and.outline"
        case "email_rewrite": return "arrow.triangle.2.circlepath"
        case "email_translation": return "character.bubble"
        case "subject_line": return "text.quote"
        case "tone_shift": return "paintpalette"
        case "email_summarize": return "text.alignleft"
        case "reply_draft": return "arrowshape.turn.up.left"
        case "follow_up": return "clock.arrow.circlepath"
        case "proofread": return "checkmark.shield"
        case "bullet_to_email": return "list.bullet.indent"
        default: return "sparkles"
        }
    }

    private var errorBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Insufficient Input")
                    .font(.headline)
            }
            Text("Please provide more details for the following fields:")
                .font(.subheadline)
            ForEach(insufficientInputFields, id: \.self) { field in
                Text("• \(field)")
                    .font(.caption.bold())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
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
                Label("AI Output", systemImage: "wand.and.stars")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                Spacer()
            }

            ScrollView {
                let content = isGenerating ? streamBuffer : (generatedContent.isEmpty ? "" : generatedContent)
                let tool = MailAIToolRegistry.shared.tool(for: selectedToolID)

                Group {
                    if let tool = tool, case .markdown = tool.responseFormat {
                        MailMarkdownRenderer(source: content, schema: tool.outputSchema)
                    } else {
                        Text(content)
                    }
                }
                .font(.subheadline)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxHeight: 250)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))

            if !isGenerating && !generatedContent.isEmpty {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = generatedContent
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption.bold())
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1), in: Capsule())
                        }

                        Button {
                            onCompletion(generatedContent)
                            dismiss()
                        } label: {
                            Label("Insert", systemImage: "arrow.right.circle.fill")
                                .font(.caption.bold())
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task { await generate() }
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                                .font(.caption.bold())
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1), in: Capsule())
                        }

                        Picker("Tone", selection: $selectedTone) {
                            ForEach(Tone.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1), in: Capsule())
                        .onChange(of: selectedTone) { _, _ in
                            Task { await generate() }
                        }
                    }

                    usageFooter
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var usageFooter: some View {
        HStack {
            Text("Tokens: \(inputTokens) in / \(outputTokens) out")
            Spacer()
            Text("Est. Cost: $\(String(format: "%.5f", Double(outputTokens) * MailAIToolsSystem.costPerOutputToken))")
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private var placeholderText: String {
        guard let tool = MailAIToolRegistry.shared.tool(for: selectedToolID) else { return "Enter prompt..." }
        switch tool.toolID {
        case "email_drafting": return "What should the email be about?"
        case "email_rewrite": return "Paste the text you want to rewrite..."
        case "email_translation": return "Paste text and target language..."
        case "subject_line": return "Paste the email body..."
        case "tone_shift": return "Paste text to change tone..."
        case "email_summarize": return "Paste a long thread..."
        case "reply_draft": return "Paste original email..."
        case "follow_up": return "Who are you following up with?"
        case "proofread": return "Paste text to proofread..."
        case "bullet_to_email": return "List your bullet points..."
        default: return "Enter context..."
        }
    }

    private var buttonLabel: String {
        guard let tool = MailAIToolRegistry.shared.tool(for: selectedToolID) else { return "Process" }
        return tool.displayName
    }

    private func generate() async {
        guard let tool = MailAIToolRegistry.shared.tool(for: selectedToolID) else { return }

        isGenerating = true
        errorMessage = nil
        insufficientInputFields = []
        streamBuffer = ""

        inputTokens = prompt.count / 4 // Heuristic

        do {
            let fullPrompt = "Task: \(tool.displayName)\nTone: \(selectedTone.rawValue)\nInput: \(prompt)"

            // Simulating streaming if supported
            if tool.supportsStreaming {
                let result = try await AIService.shared.processText(prompt: fullPrompt, systemPrompt: tool.systemPrompt)

                // Simulate streaming display
                for char in result {
                    try await Task.sleep(nanoseconds: 5_000_000)
                    await MainActor.run {
                        streamBuffer.append(char)
                    }
                }

                await MainActor.run {
                    generatedContent = processResult(result, for: tool)
                    outputTokens = result.count / 4
                    isGenerating = false
                }
            } else {
                let result = try await AIService.shared.processText(prompt: fullPrompt, systemPrompt: tool.systemPrompt)

                if result.contains("\"error\": \"insufficient_input\"") {
                    if let data = result.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let missing = json["missing"] as? [String] {
                        await MainActor.run {
                            insufficientInputFields = missing
                            isGenerating = false
                        }
                        return
                    }
                }

                await MainActor.run {
                    generatedContent = processResult(result, for: tool)
                    outputTokens = result.count / 4
                    isGenerating = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }

    private func processResult(_ result: String, for tool: any MailAITool) -> String {
        let sanitized = MarkdownOutputValidator.sanitize(result, against: tool.outputSchema)

        if case .structured(let fields) = tool.responseFormat {
            if let data = sanitized.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                return fields.compactMap { json[$0] }.joined(separator: "\n\n")
            }
        }

        return sanitized
    }
}
