import SwiftUI

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    enum EmailType: String, CaseIterable, Identifiable {
        case business = "Business"
        case update = "Update"
        case followUp = "Follow-Up"
        case support = "Support"
        case invitation = "Invitation"

        var id: String { rawValue }
    }

    enum EmailTone: String, CaseIterable, Identifiable {
        case professional = "Professional"
        case friendly = "Friendly"
        case formal = "Formal"
        case concise = "Concise"

        var id: String { rawValue }
    }

    enum EmailLength: String, CaseIterable, Identifiable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
        case detailed = "Detailed"

        var id: String { rawValue }

        var rewriteMode: String {
            switch self {
            case .short, .medium:
                return "shorten"
            case .long, .detailed:
                return "expand"
            }
        }
    }

    enum PriorityLevel: String, CaseIterable, Identifiable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"

        var id: String { rawValue }
    }

    enum IntentType: String, CaseIterable, Identifiable {
        case inform = "Inform"
        case persuade = "Persuade"
        case request = "Request"
        case followUp = "Follow-Up"
        case escalate = "Escalate"

        var id: String { rawValue }
    }

    enum AudienceType: String, CaseIterable, Identifiable {
        case executive = "Executive"
        case client = "Client"
        case internalTeam = "Internal"
        case unknown = "Unknown"

        var id: String { rawValue }
    }

    enum EmotionalTone: String, CaseIterable, Identifiable {
        case empathetic = "Empathetic"
        case confident = "Confident"
        case diplomatic = "Diplomatic"
        case assertive = "Assertive"
        case optimistic = "Optimistic"

        var id: String { rawValue }
    }

    enum FormattingStyle: String, CaseIterable, Identifiable {
        case paragraphs = "Paragraph"
        case bullets = "Bullets"
        case hybrid = "Hybrid"

        var id: String { rawValue }
    }

    enum CTAType: String, CaseIterable, Identifiable {
        case reply = "Reply Requested"
        case schedule = "Schedule Call"
        case approve = "Approval Needed"
        case review = "Review & Feedback"
        case custom = "Custom"

        var id: String { rawValue }

        var suggestion: String {
            switch self {
            case .reply:
                return "Please reply by EOD so we can proceed."
            case .schedule:
                return "Please share a time that works for a 20-minute call this week."
            case .approve:
                return "Please confirm approval so we can move to execution."
            case .review:
                return "Please review and share feedback on the proposed approach."
            case .custom:
                return ""
            }
        }
    }

    enum AITool: CaseIterable, Hashable, Identifiable {
        case autoFillSubject
        case enhanceDescription
        case generateVariants
        case rewriteTone
        case shortenExpand
        case fixGrammarClarity
        case explainDraft

        var id: String { title }

        var title: String {
            switch self {
            case .autoFillSubject: return "Auto-fill Subject"
            case .enhanceDescription: return "Enhance Description"
            case .generateVariants: return "Generate Variants"
            case .rewriteTone: return "Rewrite Tone"
            case .shortenExpand: return "Shorten / Expand"
            case .fixGrammarClarity: return "Fix Grammar + Improve Clarity"
            case .explainDraft: return "Explain Draft"
            }
        }

        var symbol: String {
            switch self {
            case .autoFillSubject: return "text.line.first.and.arrowtriangle.forward"
            case .enhanceDescription: return "wand.and.stars"
            case .generateVariants: return "square.stack.3d.up.fill"
            case .rewriteTone: return "theatermasks"
            case .shortenExpand: return "arrow.up.left.and.arrow.down.right"
            case .fixGrammarClarity: return "checkmark.seal"
            case .explainDraft: return "lightbulb"
            }
        }
    }

    struct StrategyPreset: Identifiable {
        let id = UUID()
        let title: String
        let summary: String
        let intent: IntentType
        let tone: EmailTone
        let priority: PriorityLevel
    }

    struct DraftVariant: Identifiable {
        let id = UUID()
        let order: Int
        let text: String
    }

    @Environment(\.dismiss) private var dismiss

    @State private var recipient = ""
    @State private var subject = ""
    @State private var emailType: EmailType = .business
    @State private var baseTone: EmailTone = .professional
    @State private var lengthSliderValue: Double = 1
    @State private var priority: PriorityLevel = .medium
    @State private var intent: IntentType = .inform
    @State private var audience: AudienceType = .internalTeam
    @State private var emotionalTones: Set<EmotionalTone> = []

    @State private var description = ""
    @State private var backgroundInfo = ""
    @State private var keywords = ""

    @State private var wordLimit = ""
    @State private var requiredPhrases = ""
    @State private var formattingStyle: FormattingStyle = .hybrid
    @State private var ctaType: CTAType = .reply
    @State private var ctaText = CTAType.reply.suggestion

    @State private var isCoreExpanded = true
    @State private var isIntentExpanded = true
    @State private var isEnhancementsExpanded = true
    @State private var isAdvancedExpanded = false

    @State private var isGenerating = false
    @State private var generatedBody = ""
    @State private var generatedVariants: [DraftVariant] = []
    @State private var draftExplanation = ""
    @State private var errorMessage: String?
    @State private var activeTool: AITool?

    let currentBody: String
    let onApply: (DraftingEmailResult) -> Void

    private let maxDisplayedEmphasisPhrases = 6
    private let doubleQuoteCharacterSet = CharacterSet(charactersIn: "\"")
    private let confidenceBaseScore = 0.06
    private let confidenceRecipientWeight = 0.14
    private let confidenceSubjectWeight = 0.14
    private let confidenceDescriptionWeight = 0.20
    private let confidenceBackgroundWeight = 0.12
    private let confidenceCTAWeight = 0.12
    private let confidenceRequiredPhrasesWeight = 0.08
    private let confidenceEmotionalToneWeight = 0.08
    private let confidenceKeywordsWeight = 0.06

    private var selectedLength: EmailLength {
        let index = Int(lengthSliderValue.rounded())
        let bounded = min(max(index, 0), EmailLength.allCases.count - 1)
        return EmailLength.allCases[bounded]
    }

    private var confidenceScore: Double {
        var score = confidenceBaseScore
        if !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceRecipientWeight }
        if !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceSubjectWeight }
        if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceDescriptionWeight }
        if !backgroundInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceBackgroundWeight }
        if !ctaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceCTAWeight }
        if !requiredPhrases.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceRequiredPhrasesWeight }
        if !emotionalTones.isEmpty { score += confidenceEmotionalToneWeight }
        if !keywords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += confidenceKeywordsWeight }
        return min(max(score, 0), 1)
    }

    private var confidenceLabel: String {
        switch confidenceScore {
        case 0..<0.45: return "Low Confidence"
        case 0.45..<0.75: return "Moderate Confidence"
        default: return "High Confidence"
        }
    }

    private var emphasisPhrases: [String] {
        let required = requiredPhrases
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let keyTerms = keywords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var phrases = Array((required + keyTerms).prefix(maxDisplayedEmphasisPhrases))
        if phrases.isEmpty, !ctaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            phrases = [ctaText.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        return phrases
    }

    private var previewDraft: String {
        let lengthDirective: String = {
            switch selectedLength {
            case .short: return "Keep this concise and to the point."
            case .medium: return "Balance brevity with enough context for clear decision-making."
            case .long: return "Include fuller context and rationale for alignment."
            case .detailed: return "Include nuanced context, decision framing, and explicit next steps."
            }
        }()

        let intro = greetingText

        let bodySummary = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "This message will focus on a clear \(intent.rawValue.lowercased()) objective for a \(audience.rawValue.lowercased()) audience."
            : description.trimmingCharacters(in: .whitespacesAndNewlines)

        let cta = ctaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Please confirm the next best step."
            : ctaText.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        \(intro)

        \(bodySummary)

        Priority: \(priority.rawValue) • Tone: \(baseTone.rawValue) • Format: \(formattingStyle.rawValue)
        \(lengthDirective)

        \(cta)
        """
    }

    private var greetingText: String {
        guard subject.isEmpty else { return "Hi," }
        switch audience {
        case .executive:
            return "Hi Team,"
        default:
            return "Hi there,"
        }
    }

    private var strategyPresets: [StrategyPreset] {
        switch emailType {
        case .business:
            return [
                StrategyPreset(title: "Decision Request", summary: "Ask for directional approval with a firm CTA.", intent: .request, tone: .professional, priority: .high),
                StrategyPreset(title: "Executive Brief", summary: "Summarize key context and decisions needed.", intent: .inform, tone: .formal, priority: .medium)
            ]
        case .update:
            return [
                StrategyPreset(title: "Milestone Update", summary: "Report progress, blockers, and immediate next step.", intent: .inform, tone: .concise, priority: .medium),
                StrategyPreset(title: "Status Alert", summary: "Highlight impact and mitigation for time-sensitive updates.", intent: .escalate, tone: .professional, priority: .high)
            ]
        case .followUp:
            return [
                StrategyPreset(title: "Gentle Follow-Up", summary: "Nudge politely while preserving momentum.", intent: .followUp, tone: .friendly, priority: .medium),
                StrategyPreset(title: "Firm Follow-Up", summary: "Request decision with explicit timeline.", intent: .followUp, tone: .professional, priority: .high)
            ]
        case .support:
            return [
                StrategyPreset(title: "Resolution Path", summary: "Acknowledge issue and present fix plan.", intent: .inform, tone: .friendly, priority: .high),
                StrategyPreset(title: "Info Collection", summary: "Gather missing details to unblock support.", intent: .request, tone: .friendly, priority: .medium)
            ]
        case .invitation:
            return [
                StrategyPreset(title: "Stakeholder Invite", summary: "Invite with clear purpose and expected outcomes.", intent: .persuade, tone: .professional, priority: .medium),
                StrategyPreset(title: "Reminder Invite", summary: "Reinforce attendance and urgency.", intent: .followUp, tone: .concise, priority: .high)
            ]
        }
    }

    private var ctaTypeBinding: Binding<CTAType> {
        Binding(
            get: { ctaType },
            set: { newValue in
                ctaType = newValue
                if newValue != .custom {
                    ctaText = newValue.suggestion
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    collapsibleSection(
                        title: "Core Info",
                        systemImage: "person.crop.circle",
                        isExpanded: $isCoreExpanded,
                        accent: .blue
                    ) {
                        coreInfoContent
                    }

                    collapsibleSection(
                        title: "Intent & Strategy",
                        systemImage: "target",
                        isExpanded: $isIntentExpanded,
                        accent: .indigo
                    ) {
                        intentStrategyContent
                    }

                    collapsibleSection(
                        title: "AI Enhancements",
                        systemImage: "sparkles",
                        isExpanded: $isEnhancementsExpanded,
                        accent: .purple
                    ) {
                        aiEnhancementContent
                    }

                    collapsibleSection(
                        title: "Advanced Controls",
                        systemImage: "slider.horizontal.3",
                        isExpanded: $isAdvancedExpanded,
                        accent: .orange
                    ) {
                        advancedControlsContent
                    }

                    livePreviewCard
                    generatedOutputCard
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("AI Writing Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        generateDraft()
                    } label: {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Label("Generate", systemImage: "sparkles")
                        }
                    }
                    .disabled(isGenerating || activeTool != nil)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium Drafting Workspace")
                        .font(.headline)
                    Text("Shape intent, audience, tone, and constraints before generation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }

            HStack(spacing: 8) {
                capsuleMetric("Intent", value: intent.rawValue)
                capsuleMetric("Audience", value: audience.rawValue)
                capsuleMetric("Length", value: selectedLength.rawValue)
            }
        }
        .padding()
        .background(cardBackground)
    }

    private var coreInfoContent: some View {
        VStack(spacing: 14) {
            Group {
                iconTextField("Recipient", text: $recipient, icon: "person.crop.circle", autocapitalization: .never)
                iconTextField("Subject", text: $subject, icon: "text.line.first.and.arrowtriangle.forward", autocapitalization: .sentences)
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Email Type", icon: "tray.and.arrow.up")
                Picker("Email Type", selection: $emailType) {
                    ForEach(EmailType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(strategyPresets) { preset in
                            Button {
                                applyPreset(preset)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(preset.summary)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(10)
                                .frame(width: 200, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Tone", icon: "slider.horizontal.3")
                Picker("Tone", selection: $baseTone) {
                    ForEach(EmailTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Length", icon: "ruler")
                Slider(
                    value: $lengthSliderValue,
                    in: 0...Double(EmailLength.allCases.count - 1),
                    step: 1
                )
                HStack {
                    ForEach(EmailLength.allCases) { length in
                        Text(length.rawValue)
                            .font(.caption2)
                            .foregroundStyle(length == selectedLength ? .primary : .secondary)
                        if length != EmailLength.allCases.last {
                            Spacer()
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Priority", icon: "exclamationmark.circle")
                Picker("Priority", selection: $priority) {
                    ForEach(PriorityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var intentStrategyContent: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                labelRow("Intent", icon: "target")
                Picker("Intent", selection: $intent) {
                    ForEach(IntentType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Audience", icon: "person.3.sequence")
                Picker("Audience", selection: $audience) {
                    ForEach(AudienceType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Emotional Tone Blending", icon: "theatermasks")
                toneChipGrid
            }

            iconTextEditor("Description", text: $description, icon: "doc.text", minHeight: 90)
            iconTextEditor("Background Info", text: $backgroundInfo, icon: "text.bubble", minHeight: 90)
            iconTextField("Keywords (comma separated)", text: $keywords, icon: "number", autocapitalization: .never)
        }
    }

    private var aiEnhancementContent: some View {
        VStack(spacing: 12) {
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(AITool.allCases) { tool in
                    Button {
                        runTool(tool)
                    } label: {
                        HStack(spacing: 8) {
                            if activeTool == tool {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: tool.symbol)
                            }
                            Text(tool.title)
                                .font(.caption.weight(.semibold))
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(isGenerating || (activeTool != nil && activeTool != tool))
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var advancedControlsContent: some View {
        VStack(spacing: 14) {
            iconTextField("Word Limit", text: $wordLimit, icon: "textformat.123", keyboard: .numberPad)
            iconTextEditor("Required Phrases (comma separated)", text: $requiredPhrases, icon: "quote.bubble", minHeight: 72)

            VStack(alignment: .leading, spacing: 8) {
                labelRow("Formatting Style", icon: "text.justify")
                Picker("Formatting Style", selection: $formattingStyle) {
                    ForEach(FormattingStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                labelRow("CTA Builder", icon: "paperplane.circle")
                Picker("CTA Type", selection: ctaTypeBinding) {
                    ForEach(CTAType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                iconTextField("CTA Text", text: $ctaText, icon: "text.cursor", autocapitalization: .sentences)
            }
        }
    }

    private var livePreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Intelligence Preview", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                Text(confidenceLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }

            ProgressView(value: confidenceScore)
                .tint(confidenceScore > 0.75 ? .green : .blue)

            if !emphasisPhrases.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key phrases AI will emphasize")
                        .font(.subheadline.weight(.semibold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emphasisPhrases, id: \.self) { phrase in
                                Text(phrase)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.14), in: Capsule())
                            }
                        }
                    }
                }
            }

            Group {
                markdownText(previewDraft, font: .subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Button {
                    generateDraft()
                } label: {
                    Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating || activeTool != nil)

                Button {
                    runTool(.fixGrammarClarity)
                } label: {
                    Label("Refine", systemImage: "wand.and.stars.inverse")
                }
                .buttonStyle(.borderedProminent)
                .disabled((generatedBody.isEmpty && currentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || isGenerating || activeTool != nil)
            }
        }
        .padding()
        .background(cardBackground)
    }

    private var generatedOutputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Generated Draft", systemImage: "doc.richtext")
                .font(.headline)

            if generatedBody.isEmpty {
                Text("Generate a draft to preview and apply it to the composer.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Group {
                    markdownText(generatedBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                Button {
                    onApply(
                        DraftingEmailResult(
                            recipient: recipient,
                            subject: subject,
                            body: generatedBody
                        )
                    )
                    dismiss()
                } label: {
                    Label("Apply To Composer", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if !generatedVariants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Variants", systemImage: "square.stack.3d.up")
                        .font(.subheadline.weight(.semibold))
                    ForEach(generatedVariants) { variant in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Variant \(variant.order)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(variant.text)
                                .font(.footnote)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            if !draftExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Why this draft", systemImage: "lightbulb")
                        .font(.subheadline.weight(.semibold))
                    Text(draftExplanation)
                        .font(.footnote)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(cardBackground)
    }

    private var toneChipGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(EmotionalTone.allCases) { tone in
                let isSelected = emotionalTones.contains(tone)
                Button {
                    if isSelected {
                        emotionalTones.remove(tone)
                    } else {
                        emotionalTones.insert(tone)
                    }
                } label: {
                    Text(tone.rawValue)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            (isSelected ? Color.blue.opacity(0.16) : Color(.secondarySystemGroupedBackground)),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private func collapsibleSection<Content: View>(
        title: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: isExpanded) {
                content()
                    .padding(.top, 8)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .foregroundStyle(accent)
                    Text(title)
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(cardBackground)
    }

    private func labelRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func iconTextField(
        _ title: String,
        text: Binding<String>,
        icon: String,
        autocapitalization: TextInputAutocapitalization = .sentences,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labelRow(title, icon: icon)
            TextField(title, text: text)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboard)
                .disableAutocorrection(true)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func iconTextEditor(_ title: String, text: Binding<String>, icon: String, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labelRow(title, icon: icon)
            TextField(title, text: text, axis: .vertical)
                .lineLimit(3...10)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func capsuleMetric(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }

    private func markdownText(_ content: String, font: Font? = nil) -> some View {
        Group {
            if let attributed = try? AttributedString(markdown: content) {
                Text(attributed)
            } else {
                Text(content)
            }
        }
        .font(font)
    }

    private func applyPreset(_ preset: StrategyPreset) {
        intent = preset.intent
        baseTone = preset.tone
        priority = preset.priority
        description = preset.summary
    }

    private func runTool(_ tool: AITool) {
        guard !isGenerating, activeTool == nil else { return }
        activeTool = tool
        errorMessage = nil

        let prompt = toolPrompt(for: tool)

        Task {
            do {
                let response = try await MailAIService.shared.composeEmail(
                    prompt: prompt,
                    systemPrompt: MailAIToolsSystem.draftingSystemPrompt
                )

                await MainActor.run {
                    applyToolResponse(response, for: tool)
                    activeTool = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    activeTool = nil
                }
            }
        }
    }

    private func toolPrompt(for tool: AITool) -> String {
        switch tool {
        case .autoFillSubject:
            return """
            Generate one optimized email subject line.
            Context:
            \(generationContext())

            Rules:
            - Return only the subject line text.
            - Keep it concise and specific.
            """
        case .enhanceDescription:
            return """
            Rewrite the user's email description to be clearer, specific, and actionable.
            Original description:
            \(description)

            Context:
            \(generationContext())

            Return only the improved description paragraph.
            """
        case .generateVariants:
            return """
            Generate 3 to 5 distinct ready-to-send draft variants.
            Context:
            \(generationContext())

            Return each draft variant separated exactly with:
            ---VARIANT---
            """
        case .rewriteTone:
            return """
            Rewrite the current draft in a \(baseTone.rawValue.lowercased()) style while preserving intent and factual accuracy.

            Current draft:
            \(draftSourceText())

            Context:
            \(generationContext())
            """
        case .shortenExpand:
            let mode = selectedLength.rewriteMode
            return """
            \(mode.capitalized) the draft according to the selected length target: \(selectedLength.rawValue).
            Preserve intent and key constraints.

            Current draft:
            \(draftSourceText())

            Context:
            \(generationContext())
            """
        case .fixGrammarClarity:
            return """
            Fix grammar and improve clarity while preserving the original meaning and commitments.

            Current draft:
            \(draftSourceText())

            Context:
            \(generationContext())
            """
        case .explainDraft:
            return """
            Explain why the draft is structured this way.
            Include: intent alignment, audience adaptation, tone choices, and CTA rationale.
            Keep it concise and high-signal.

            Draft:
            \(draftSourceText())

            Context:
            \(generationContext())
            """
        }
    }

    private func applyToolResponse(_ response: String, for tool: AITool) {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        switch tool {
        case .autoFillSubject:
            subject = cleaned
                .components(separatedBy: .newlines)
                .first?
                .trimmingCharacters(in: doubleQuoteCharacterSet) ?? ""
        case .enhanceDescription:
            description = cleaned
        case .generateVariants:
            generatedVariants = cleaned
                .components(separatedBy: "---VARIANT---")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .enumerated()
                .map { index, text in
                    DraftVariant(order: index + 1, text: text)
                }
        case .rewriteTone, .shortenExpand, .fixGrammarClarity:
            generatedBody = cleaned
        case .explainDraft:
            draftExplanation = cleaned
        }
    }

    private func generationContext() -> String {
        """
        Recipient: \(recipient)
        Subject: \(subject)
        Email Type: \(emailType.rawValue)
        Base Tone: \(baseTone.rawValue)
        Emotional Tones: \(emotionalTones.map(\.rawValue).sorted().joined(separator: ", "))
        Length: \(selectedLength.rawValue)
        Priority: \(priority.rawValue)
        Intent: \(intent.rawValue)
        Audience: \(audience.rawValue)
        Description: \(description)
        Background Info: \(backgroundInfo)
        Keywords: \(keywords)
        Word Limit: \(wordLimit)
        Required Phrases: \(requiredPhrases)
        Formatting Style: \(formattingStyle.rawValue)
        CTA: \(ctaText)
        Existing Body Context: \(currentBody)
        """
    }

    private func draftSourceText() -> String {
        let generated = generatedBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if !generated.isEmpty { return generated }
        let current = currentBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if !current.isEmpty { return current }
        return previewDraft
    }

    private func generateDraft() {
        guard !isGenerating, activeTool == nil else { return }
        isGenerating = true
        errorMessage = nil

        let prompt = """
        Generate a ready-to-send email draft using the following fields.
        Keep the writing precise, grounded, and action-oriented.

        \(generationContext())

        Output requirements:
        - Return only the final email draft body.
        - Respect the selected formatting style and word-limit intent.
        - Include an intentional call to action.
        """

        Task {
            do {
                let draft = try await MailAIService.shared.composeEmail(
                    prompt: prompt,
                    systemPrompt: MailAIToolsSystem.draftingSystemPrompt
                )

                await MainActor.run {
                    generatedBody = draft.trimmingCharacters(in: .whitespacesAndNewlines)
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
