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

    @State private var aiPanelExpanded = false
    @State private var selectedAIToolID = "email_rewrite"
    @State private var aiResult = ""
    @State private var subjectSuggestions: [String] = []
    @State private var isGeneratingSuggestions = false
    @State private var showPreview = false
    @State private var proofreadDiff: [DiffLine] = []

    let currentBody: String
    let onApply: (DraftingEmailResult) -> Void

    enum AIToolType: String, CaseIterable {
        case rewrite = "Rewrite"
        case improveTone = "Improve Tone"
        case summarize = "Summarize"
        case proofread = "Proofread"
        case subjects = "Generate Subject Lines"

        var toolID: String {
            switch self {
            case .rewrite: return "email_rewrite"
            case .improveTone: return "tone_shift"
            case .summarize: return "email_summarize"
            case .proofread: return "proofread"
            case .subjects: return "subject_line"
            }
        }
    }

    struct DiffLine: Identifiable {
        let id = UUID()
        let text: String
        let type: DiffType
    }

    enum DiffType {
        case original, corrected, unchanged
    }

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

                            VStack(alignment: .leading, spacing: 8) {
                                modernInputField(label: "Subject", text: $subject, placeholder: "What is this about?", icon: "tag.fill")

                                if !subjectSuggestions.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(subjectSuggestions, id: \.self) { suggestion in
                                                Button {
                                                    subject = suggestion
                                                } label: {
                                                    Text(suggestion)
                                                        .font(.caption2.bold())
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(Color.blue.opacity(0.15), in: Capsule())
                                                        .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("Context & Details", systemImage: "text.alignleft")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    toneBadge
                                    Button {
                                        showPreview.toggle()
                                    } label: {
                                        Label(showPreview ? "Edit" : "Preview", systemImage: showPreview ? "pencil" : "eye")
                                            .font(.caption.bold())
                                    }
                                }

                                if showPreview {
                                    MailMarkdownRenderer(source: context, schema: EmailDraftingTool().outputSchema)
                                        .padding(12)
                                        .frame(minHeight: 140, alignment: .topLeading)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                } else {
                                    TextEditor(text: $context)
                                        .frame(height: 140)
                                        .padding(12)
                                        .scrollContentBackground(.hidden)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                }
                            }

                            aiAssistPanel
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
            }
            .aiAnimationLoading(isGenerating)
            .navigationTitle("Drafting Assistant")
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

    private var toneBadge: some View {
        let (tone, color) = analyzeTone(context)
        return Text(tone)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }

    private func analyzeTone(_ text: String) -> (String, Color) {
        let formalMarkers = ["hereby", "concerning", "sincerely", "regards", "pleasure", "appreciation"]
        let informalMarkers = ["hey", "hi", "thanks", "awesome", "great", "deal", "cool"]

        let lowerText = text.lowercased()
        let formalCount = formalMarkers.filter { lowerText.contains($0) }.count
        let informalCount = informalMarkers.filter { lowerText.contains($0) }.count

        if formalCount > informalCount {
            return ("Formal", .blue)
        } else if informalCount > formalCount {
            return ("Casual", .green)
        } else {
            return ("Mixed", .orange)
        }
    }

    private var aiAssistPanel: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { aiPanelExpanded.toggle() }
            } label: {
                HStack {
                    Label("AI Assistant", systemImage: "sparkles")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: aiPanelExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.bold())
                }
                .padding()
                .background(Color.white.opacity(0.05))
            }

            if aiPanelExpanded {
                VStack(spacing: 16) {
                    Picker("Tool", selection: $selectedAIToolID) {
                        ForEach(AIToolType.allCases, id: \.toolID) { tool in
                            Text(tool.rawValue).tag(tool.toolID)
                        }
                    }
                    .pickerStyle(.segmented)

                    if !aiResult.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI Result")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                Spacer()
                                Button("Apply") {
                                    if selectedAIToolID == "subject_line" {
                                        subject = aiResult
                                    } else {
                                        context = MarkdownSyntaxStripper.plainText(from: aiResult)
                                    }
                                    aiResult = ""
                                }
                                .font(.caption.bold())
                            }

                            if selectedAIToolID == "proofread" && !proofreadDiff.isEmpty {
                                diffView
                            } else {
                                MailMarkdownRenderer(source: aiResult, schema: EmailDraftingTool().outputSchema)
                                    .padding(12)
                                    .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        runAITool()
                    } label: {
                        if isGeneratingSuggestions {
                            ProgressView().tint(.white)
                        } else {
                            Text("Run AI Assist")
                                .font(.subheadline.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .disabled(isGeneratingSuggestions || context.isEmpty)
                }
                .padding()
                .background(Color.white.opacity(0.03))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var diffView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(proofreadDiff) { line in
                Text(line.text)
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 4)
                    .background(line.type == .original ? Color.red.opacity(0.2) : (line.type == .corrected ? Color.green.opacity(0.2) : Color.clear))
                    .foregroundStyle(line.type == .original ? .red : (line.type == .corrected ? .green : .primary))
            }

            Button("Accept All") {
                context = MarkdownSyntaxStripper.plainText(from: aiResult)
                aiResult = ""
                proofreadDiff = []
            }
            .font(.caption2.bold())
            .padding(.top, 8)
        }
    }

    private func runAITool() {
        Task {
            isGeneratingSuggestions = true
            defer { isGeneratingSuggestions = false }

            guard let tool = MailAIToolRegistry.shared.tool(for: selectedAIToolID) else { return }

            do {
                let result = try await AIService.shared.processText(prompt: context, systemPrompt: tool.systemPrompt)
                await MainActor.run {
                    aiResult = result
                    if selectedAIToolID == "subject_line" {
                        subjectSuggestions = result.components(separatedBy: "\n").filter { $0.contains("- ") || $0.contains("* ") }.map { $0.replacingOccurrences(of: "- ", with: "").replacingOccurrences(of: "* ", with: "").trimmingCharacters(in: .whitespaces) }
                    } else if selectedAIToolID == "proofread" {
                        calculateDiff(original: context, corrected: result)
                    }
                }
            } catch {
                print("AI Assist failed: \(error)")
            }
        }
    }

    private func calculateDiff(original: String, corrected: String) {
        let origLines = original.components(separatedBy: "\n")
        let corrLines = corrected.components(separatedBy: "\n")

        var diff: [DiffLine] = []
        // Minimal LCS-like diff (line by line)
        let maxLines = max(origLines.count, corrLines.count)
        for i in 0..<maxLines {
            let o = i < origLines.count ? origLines[i] : ""
            let c = i < corrLines.count ? corrLines[i] : ""

            if o == c {
                diff.append(.init(text: o, type: .unchanged))
            } else {
                if !o.isEmpty { diff.append(.init(text: "- \(o)", type: .original)) }
                if !c.isEmpty { diff.append(.init(text: "+ \(c)", type: .corrected)) }
            }
        }
        self.proofreadDiff = diff
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

    private func generate() async {
        isGenerating = true
        do {
            let prompt = """
            Style: \(selectedStyle.rawValue)
            Goal: \(selectedGoal.rawValue)
            Context: \(context)
            """
            let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: MailAIToolsSystem.draftingSystemPrompt)
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
