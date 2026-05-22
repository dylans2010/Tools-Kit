import SwiftUI
import Aurora

// MARK: - SuggestEssayDraft Animation

struct SuggestEssayDraft: ViewModifier {
    let isAnimating: Bool
    @State private var sweepDirection = false
    @State private var glowPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isAnimating {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color.accentColor.opacity(0.0),
                                        Color.accentColor.opacity(0.6),
                                        Color.purple.opacity(0.5),
                                        Color.accentColor.opacity(0.8),
                                        Color.blue.opacity(0.4),
                                        Color.accentColor.opacity(0.0)
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(glowPhase),
                                    endAngle: .degrees(glowPhase + 360)
                                ),
                                lineWidth: 2.5
                            )
                            .onAppear {
                                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                    glowPhase = 360
                                }
                            }
                            .transition(.opacity)

                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                            .blur(radius: 4)

                        AuroraGlow(.dramatic)
                            .washSweepDuration(1.5)
                            .washPulseWidth(0.6)
                            .washPeak(0.4)
                            .direction(sweepDirection ? .leftToRight : .rightToLeft)
                            .introStyle(.borderFill)
                            .introDuration(0.3)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(lineWidth: 6)
                            )
                            .allowsHitTesting(false)
                            .onAppear {
                                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                                    sweepDirection.toggle()
                                }
                            }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: isAnimating)
            )
            .shadow(
                color: isAnimating ? Color.accentColor.opacity(0.25) : .clear,
                radius: isAnimating ? 10 : 0
            )
            .animation(.easeInOut(duration: 0.4), value: isAnimating)
    }
}

extension View {
    func suggestEssayDraftAnimation(_ isAnimating: Bool) -> some View {
        self.modifier(SuggestEssayDraft(isAnimating: isAnimating))
    }
}

// MARK: - Enums

enum EssayTone: String, CaseIterable, Identifiable {
    case formal       = "Formal"
    case balanced     = "Balanced"
    case conversational = "Conversational"
    case persuasive   = "Persuasive"
    case analytical   = "Analytical"
    case narrative    = "Narrative"
    case critical     = "Critical"
    case inspirational = "Inspirational"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .formal:         return "building.columns"
        case .balanced:       return "scale.3d"
        case .conversational: return "bubble.left.and.bubble.right"
        case .persuasive:     return "megaphone"
        case .analytical:     return "chart.xyaxis.line"
        case .narrative:      return "book.pages"
        case .critical:       return "magnifyingglass"
        case .inspirational:  return "star"
        }
    }
}

enum EssayStandard: String, CaseIterable, Identifiable {
    case general       = "General"
    case highSchool    = "High School"
    case undergraduate = "Undergraduate"
    case graduate      = "Graduate"
    case doctoral      = "Doctoral"
    case professional  = "Professional"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general:       return "doc.text"
        case .highSchool:    return "pencil.and.ruler"
        case .undergraduate: return "graduationcap"
        case .graduate:      return "books.vertical"
        case .doctoral:      return "shield.lefthalf.filled"
        case .professional:  return "briefcase"
        }
    }
}

enum CitationStyle: String, CaseIterable, Identifiable {
    case none    = "None"
    case mla     = "MLA"
    case apa     = "APA"
    case chicago = "Chicago"
    case harvard = "Harvard"
    case ieee    = "IEEE"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .none:    return "minus.circle"
        case .mla:     return "text.alignleft"
        case .apa:     return "a.circle"
        case .chicago: return "c.circle"
        case .harvard: return "h.circle"
        case .ieee:    return "i.circle"
        }
    }
}

enum EssayLength: String, CaseIterable, Identifiable {
    case short    = "Short (~300w)"
    case medium   = "Medium (~600w)"
    case standard = "Standard (~900w)"
    case long     = "Long (~1200w)"
    case extended = "Extended (~1800w)"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .short:    return "doc"
        case .medium:   return "doc.text"
        case .standard: return "doc.plaintext"
        case .long:     return "doc.richtext"
        case .extended: return "doc.on.doc"
        }
    }
}

enum FormattingStyle: String, CaseIterable, Identifiable {
    case flowing       = "Flowing Prose"
    case structured    = "Structured"
    case argumentative = "Argumentative"
    case fiveparagraph = "5-Paragraph"
    case listicle      = "Listicle"
    case comparative   = "Compare & Contrast"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .flowing:       return "wind"
        case .structured:    return "list.bullet.rectangle"
        case .argumentative: return "flag"
        case .fiveparagraph: return "5.circle"
        case .listicle:      return "list.number"
        case .comparative:   return "arrow.left.arrow.right"
        }
    }
}

enum PointOfView: String, CaseIterable, Identifiable {
    case firstPerson  = "First Person"
    case thirdPerson  = "Third Person"
    case secondPerson = "Second Person"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .firstPerson:  return "person"
        case .thirdPerson:  return "person.3"
        case .secondPerson: return "person.crop.circle"
        }
    }
}

enum LanguageComplexity: String, CaseIterable, Identifiable {
    case simple   = "Simple"
    case moderate = "Moderate"
    case advanced = "Advanced"
    case expert   = "Expert"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .simple:   return "textformat.size.smaller"
        case .moderate: return "textformat.size"
        case .advanced: return "textformat.size.larger"
        case .expert:   return "brain"
        }
    }
}

enum EssayVocabularyLevel: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case scholarly = "Scholarly"
    var id: String { rawValue }
}

enum EssayParagraphStyle: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case concise = "Concise"
    case detailed = "Detailed"
    case mixed = "Mixed"
    var id: String { rawValue }
}

// MARK: - Models

struct AIDetectionResult {
    let score: Double          // 0.0 = fully human, 1.0 = fully AI
    let classification: AIClassification
    let sentenceScores: [SentenceScore]

    enum AIClassification {
        case human, mixed, aiGenerated
        var label: String {
            switch self {
            case .human:       return "Likely Human"
            case .mixed:       return "Mixed Content"
            case .aiGenerated: return "AI Generated"
            }
        }
        var color: Color {
            switch self {
            case .human:       return .green
            case .mixed:       return .orange
            case .aiGenerated: return .red
            }
        }
        var icon: String {
            switch self {
            case .human:       return "checkmark.seal.fill"
            case .mixed:       return "questionmark.circle"
            case .aiGenerated: return "xmark.seal.fill"
            }
        }
    }

    struct SentenceScore: Identifiable {
        let id = UUID()
        let sentence: String
        let score: Double
    }
}

// MARK: - ViewModel

class EssayDraftingViewModel: ObservableObject {
    // Inputs
    @Published var topic: String = ""
    @Published var goal: String = "Inform"
    @Published var thesis: String = ""
    @Published var keyPoints: [String] = [""]
    @Published var selectedTone: EssayTone = .balanced
    @Published var selectedComplexity: LanguageComplexity = .moderate
    @Published var audience: String = ""
    @Published var selectedLength: EssayLength = .medium
    @Published var selectedStandard: EssayStandard = .general
    @Published var selectedCitationStyle: CitationStyle = .none
    @Published var selectedFormatting: FormattingStyle = .flowing
    @Published var selectedPOV: PointOfView = .thirdPerson
    @Published var struggle: String = "Starting"
    @Published var hookEnabled: Bool = true
    @Published var sourceRequirement: String = "None"
    @Published var outputMode: String = "Full Essay"
    @Published var styleReference: String = ""
    @Published var keywords: String = ""
    @Published var vocabularyLevel: EssayVocabularyLevel = .intermediate
    @Published var paragraphStyle: EssayParagraphStyle = .standard
    @Published var includeCounterArguments: Bool = false
    @Published var includeTransitions: Bool = true
    @Published var targetWordCount: Int = 800

    // UI State
    @Published var currentStep: Int = 1
    @Published var isGenerating: Bool = false
    @Published var isHumanizing: Bool = false
    @Published var isTransitioning: Bool = false
    @Published var generatedContent: String = ""
    @Published var showPreview: Bool = false
    @Published var suggestedThesisLoading: Bool = false

    // AI Detection
    @Published var aiDetectionResult: AIDetectionResult? = nil
    @Published var isDetecting: Bool = false
    @Published var detectionError: String? = nil

    let goals = ["Inform", "Argue", "Analyze", "Reflect"]
    let struggles = ["Starting", "Organizing", "Making Arguments", "Grammar"]
    let sourceRequirements = ["None", "Light", "Strict"]
    let outputModes = ["Full Essay", "Outline Only", "Paragraph by Paragraph"]

    func parseEssay(_ raw: String) -> (title: String, body: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: "\n") {
            let title = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let body = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if title.count <= 120 { return (title, body) }
        }
        return ("", trimmed)
    }

    func suggestThesis() {
        guard !topic.isEmpty else { return }
        suggestedThesisLoading = true
        Task {
            do {
                let prompt = "Suggest a clear, compelling thesis statement for a \(goal) essay about: \(topic)"
                let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are an expert academic advisor. Provide only the thesis statement WITHOUT any additional explanation or formatting. Don't include quotes or 'Thesis:' prefix, ONLY the thesis statement.")
                await MainActor.run {
                    self.thesis = result.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.suggestedThesisLoading = false
                }
            } catch {
                await MainActor.run {
                    self.suggestedThesisLoading = false
                }
            }
        }
    }

    func generateEssay() {
        isGenerating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            do {
                var taskPrompt = "Generate a \(outputMode) for an essay."
                if outputMode == "Full essay" {
                    taskPrompt = "Generate a complete essay."
                } else if outputMode == "Outline only" {
                    taskPrompt = "Generate a detailed structured outline for an essay."
                } else if outputMode == "Paragraph-by-paragraph" {
                    taskPrompt = "Generate the first few paragraphs of an essay."
                }

                let context = """
                Topic: \(topic)
                Goal: \(goal)
                Thesis: \(thesis)
                Key Points: \(keyPoints.joined(separator: ", "))
                Tone: \(selectedTone.rawValue)
                Complexity: \(selectedComplexity.rawValue)
                Length: \(selectedLength.rawValue)
                Audience: \(audience)
                Academic Standard: \(selectedStandard.rawValue)
                Citation Style: \(selectedCitationStyle.rawValue)
                Formatting Style: \(selectedFormatting.rawValue)
                Point of View: \(selectedPOV.rawValue)
                User Struggle: \(struggle)
                Hook: \(hookEnabled ? "Yes" : "No")
                Source Requirements: \(sourceRequirement)
                Keywords: \(keywords)
                Style Reference: \(styleReference)
                """

                var systemPrompt = "You are a professional essay writer. "
                if struggle == "Starting" {
                    systemPrompt += "Prioritize a strong, engaging introduction and clear structural foundation. "
                } else if struggle == "Organizing" {
                    systemPrompt += "Ensure a highly logical flow and well-structured progression of ideas. "
                } else if struggle == "Making arguments" {
                    systemPrompt += "Focus on depth of reasoning, evidence-based claims, and persuasive strength. "
                } else if struggle == "Grammar" {
                    systemPrompt += "Ensure perfectly polished, sophisticated, and error-free writing. "
                }

                if hookEnabled {
                    systemPrompt += "Always start with a compelling opening hook. "
                } else {
                    systemPrompt += "Start directly with a formal academic introduction. "
                }

                if sourceRequirement == "Light" {
                    systemPrompt += "Include general references where appropriate. "
                } else if sourceRequirement == "Strict" {
                    systemPrompt += "Include properly formatted \(selectedCitationStyle.rawValue) citations for all major claims. "
                }

                if !styleReference.isEmpty {
                    systemPrompt += "Mimic the tone and structure of the provided style reference. "
                }

                if !keywords.isEmpty {
                    systemPrompt += "Naturally integrate the following keywords: \(keywords). "
                }

                let prompt = "\(taskPrompt)\n\nEssay Context:\n\(context)"

                let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: systemPrompt)
                await MainActor.run {
                    self.generatedContent = result
                    self.isGenerating = false
                    self.showPreview = true
                }
            } catch {
                await MainActor.run {
                    self.generatedContent = "Error generating essay: \(error.localizedDescription)"
                    self.isGenerating = false
                    self.showPreview = true
                }
            }
        }
    }

    func humanize() {
        isHumanizing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            do {
                let systemPrompt = """
                You are an elite-tier essay humanizer and stealth rewriter — the most advanced text
                transformation engine designed to convert AI-generated prose into writing that is
                indistinguishable from authentic human authorship. Your rewritten output MUST defeat
                every major AI detection platform including GPTZero, Turnitin AI Detection, Copyleaks,
                Originality.ai, Winston AI, Sapling, ZeroGPT, Crossplag, Writer.com AI Detector,
                Content at Scale, Hive Moderation, and any future detection model — while preserving
                the original meaning, argument structure, thesis, and factual accuracy completely.

                === PHASE 1: STRUCTURAL HUMANIZATION (Always Do) ===
                1.  Vary sentence length dramatically. Alternate between very short punchy sentences
                    (4-8 words) and longer complex ones (25-40 words). Never allow 3+ consecutive
                    sentences of similar length. Aim for a standard deviation in sentence length that
                    mirrors natural speech (~40-60% variance).
                2.  Begin sentences with conjunctions occasionally (But, And, Yet, So, Or, Still) —
                    real humans do this roughly 8-12% of the time. Mirror that frequency.
                3.  Use contractions naturally and consistently: don't, isn't, can't, won't, it's,
                    they're, there's, we've, I'd, who's, that's, wouldn't, shouldn't, couldn't.
                    At least 70% of eligible contractions should be contracted.
                4.  Insert first-person perspective where appropriate: "I would argue", "In my view",
                    "It strikes me that", "What becomes clear is", "I find it worth noting",
                    "From where I stand", "My reading of this suggests".
                5.  Use colloquial transitions: "That said,", "Here's the thing:", "Of course,",
                    "To put it plainly,", "And yet,", "Look,", "The point is,", "Now,",
                    "Granted,", "Fair enough,", "In a way,", "Funny enough,".
                6.  Include hedging language: "perhaps", "it seems", "arguably", "in many cases",
                    "for the most part", "more often than not", "to some extent", "broadly speaking",
                    "as far as I can tell", "if we're being honest".
                7.  Write at least one sentence per major paragraph that reflects personal observation,
                    opinion framing, or reflective commentary — even if abstract or speculative.
                8.  Vary paragraph length intentionally. Some paragraphs should be 1-2 sentences.
                    Others 4-6. Never produce more than 2 paragraphs of similar sentence count in a row.
                9.  Use em dashes — like this — to interrupt or add parenthetical thoughts. Use them
                    2-4 times across the entire essay, not more.
                10. Replace academic synonyms with simpler, more natural word choices: "use" over
                    "utilize", "show" over "demonstrate", "help" over "facilitate", "get" over
                    "obtain", "start" over "commence", "end" over "terminate", "need" over "necessitate",
                    "try" over "endeavor", "enough" over "sufficient", "basic" over "fundamental".
                11. Rephrase all list-like or parallel structures so they feel organic, not enumerated.
                    If the original has "First... Second... Third...", break those into varied
                    transition styles.
                12. Change passive voice to active voice wherever possible. Target 85%+ active voice.
                13. Add subtle imperfections — a slight redundancy, an informal aside, a self-correction
                    ("or rather,"), a rhetorical question, or a parenthetical clarification — that
                    signals authentic human writing rather than optimized machine output.

                === PHASE 2: LEXICAL & SEMANTIC HUMANIZATION ===
                14. Introduce natural vocabulary variation. Don't repeat the same adjective or adverb
                    within 3 paragraphs. Rotate synonyms but prefer common over exotic words.
                15. Use idiomatic expressions sparingly but naturally: "at the end of the day" (only
                    once if ever), "the bottom line", "when push comes to shove", "for what it's
                    worth", "all things considered" — limit to 1-2 per essay.
                16. Embed rhetorical questions naturally (1-2 per essay): "But does this really hold
                    up?", "So what does this actually mean in practice?", "Why should we care?"
                17. Occasionally front-load subordinate clauses: "While the data suggests otherwise,",
                    "Even though this seems counterintuitive,", "Despite what critics argue,".
                18. Use sensory or concrete language where abstract phrasing exists. Replace "this has
                    significant implications" with "this changes how we think about X in a real way."
                19. Mirror natural written cadence by occasionally breaking grammar rules the way real
                    writers do: sentence fragments for emphasis ("Not quite.", "Far from it."),
                    comma splices in informal contexts, starting with "Because" or "Which".

                === PHASE 3: ANTI-DETECTION COUNTERMEASURES ===
                20. Perplexity injection: Ensure the text has naturally high perplexity (unpredictable
                    next-word choices) by avoiding the most statistically probable word in at least
                    30% of positions. Choose the 2nd or 3rd most natural word instead.
                21. Burstiness calibration: Human writing has high burstiness (alternating between
                    complex and simple passages). Ensure at least 3 clear shifts in complexity level
                    across the essay.
                22. Avoid formulaic essay patterns: Do NOT follow "Topic sentence → Evidence →
                    Analysis → Transition" rigidly in every paragraph. Mix up the internal structure.
                23. Scatter micro-digressions: Brief 1-sentence asides that show the writer's thought
                    process ("This might seem tangential, but...", "I realize this is a simplification,
                    but...") placed naturally 1-2 times.
                24. Avoid over-coherence: Real human essays sometimes have slightly abrupt transitions
                    or unexpected topic pivots. Don't over-smooth every connection.
                25. Use demonstrative references naturally: "this idea", "that claim", "these findings"
                    — but not in a pattern. Vary between demonstrative, pronoun, and noun repetition.

                === ABSOLUTE PROHIBITIONS (Never Do) ===
                1.  NEVER use these words/phrases — they are primary AI detection markers:
                    "delve", "tapestry", "nuanced", "multifaceted", "it is important to note",
                    "in conclusion", "to summarize", "in today's world", "in the realm of",
                    "stands as a testament", "pivotal", "crucial role", "underscore", "shed light on",
                    "embark", "landscape" (metaphorical), "moreover" (as opener), "furthermore" (as
                    opener), "in essence", "game-changer", "paradigm shift", "holistic",
                    "comprehensive", "robust", "leverage" (as verb), "foster" (as verb), "navigate"
                    (metaphorical), "intersection of", "myriad", "plethora", "synergy", "catalyst",
                    "cornerstone", "underpinning", "overarching", "spearhead", "harness",
                    "groundbreaking", "trailblazing", "thought-provoking", "noteworthy",
                    "ever-evolving", "fast-paced", "cutting-edge", "realm", "facet", "intricate",
                    "indispensable", "commendable", "meticulous".
                2.  NEVER produce more than 2 consecutive sentences of similar grammatical structure.
                3.  NEVER use overly formal academic phrasing that a real student would not naturally
                    write in a homework essay.
                4.  NEVER produce perfectly symmetrical paragraph structures (same sentence count,
                    same length) — this is a primary AI detection signal.
                5.  NEVER use bulleted or numbered lists in the output unless the input explicitly
                    required them.
                6.  NEVER begin more than 2 sentences in a row with "The", "This", "These", or "It".
                7.  NEVER introduce new arguments, facts, or claims not present in the original essay.
                8.  NEVER change the thesis, topic sentences, or core evidence.
                9.  NEVER output markdown formatting — output plain prose only.
                10. NEVER make the essay longer than 110% of the original word count or shorter than
                    90% of the original word count.
                11. NEVER use the same transition word/phrase more than twice in the entire essay.
                12. NEVER produce a paragraph where every sentence starts with a subject-verb pattern.
                13. NEVER use overly enthusiastic or promotional language ("amazing", "incredible",
                    "revolutionary", "remarkable").
                14. NEVER use filler phrases that add no meaning: "It goes without saying",
                    "Needless to say", "It should be noted that", "It is worth mentioning".
                15. NEVER produce text that sounds like a corporate blog post, press release, or
                    marketing copy.

                === OUTPUT INSTRUCTIONS ===
                Return ONLY the rewritten essay text. No preamble, no explanation, no labels, no
                meta-commentary, no "Here is your rewritten essay:", ONLY the rewritten prose.
                Maintain the same paragraph breaks as the original. Preserve any citations or
                references exactly as they appear.
                """

                let result = try await AIService.shared.processText(prompt: generatedContent, systemPrompt: systemPrompt)
                await MainActor.run {
                    self.generatedContent = result
                    self.isHumanizing = false
                }
            } catch {
                await MainActor.run {
                    self.isHumanizing = false
                }
            }
        }
    }

    func runAIDetection() async {
        guard !generatedContent.isEmpty else { return }
        await MainActor.run {
            isDetecting = true
            detectionError = nil
            aiDetectionResult = nil
        }
        do {
            let url = URL(string: "https://api.gptzero.me/v2/predict/text")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(AppConfig.gptzeroAPIKey, forHTTPHeaderField: "x-api-key")

            let body: [String: Any] = [
                "document": generatedContent,
                "version": "2024-01-09"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let documents = json?["documents"] as? [[String: Any]]
            let doc = documents?.first

            let averageGeneratedProb = doc?["average_generated_prob"] as? Double ?? 0.0

            // Map score to classification
            let score = averageGeneratedProb
            let classification: AIDetectionResult.AIClassification
            if score < 0.2 {
                classification = .human
            } else if score < 0.65 {
                classification = .mixed
            } else {
                classification = .aiGenerated
            }

            // Parse per-sentence scores if available
            var sentenceScores: [AIDetectionResult.SentenceScore] = []
            if let sentences = doc?["sentences"] as? [[String: Any]] {
                for s in sentences {
                    if let text = s["sentence"] as? String,
                       let prob = s["generated_prob"] as? Double {
                        sentenceScores.append(
                            AIDetectionResult.SentenceScore(sentence: text, score: prob)
                        )
                    }
                }
            }

            let result = AIDetectionResult(
                score: score,
                classification: classification,
                sentenceScores: sentenceScores
            )

            await MainActor.run {
                self.aiDetectionResult = result
                self.isDetecting = false
            }

        } catch {
            await MainActor.run {
                self.detectionError = "Coming Soon!"
                self.isDetecting = false
            }
        }
    }
}

// MARK: - Views

struct EssayDraftingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EssayDraftingViewModel()
    @StateObject private var manager = NotebooksManager.shared
    @State private var didCopy: Bool = false
    @State private var thesisSuggestAnimating: Bool = false
    @State private var contentFontSize: CGFloat = 16
    @State private var contentLineSpacing: CGFloat = 5

    private var isAnyLoading: Bool {
        viewModel.isGenerating || viewModel.isHumanizing || viewModel.isTransitioning
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator

                    ScrollView {
                        VStack(spacing: 24) {
                            if !viewModel.showPreview {
                                stepContent
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                previewContent
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding()
                    }

                    if !viewModel.showPreview {
                        navigationButtons
                    }
                }
                .navigationTitle("Essay Drafting")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                        .disabled(isAnyLoading)
                    }
                }
            }
            .modifier(AIAnimationCoreModifier(isLoading: isAnyLoading))
            .overlay {
                if isAnyLoading {
                    loadingOverlay
                        .transition(.opacity)
                }
            }
        }
    }

    private var loadingOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(loadingLabel)
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 50)
        }
        .zIndex(200)
    }

    private var loadingLabel: String {
        if viewModel.isGenerating { return "Drafting Your Essay..." }
        if viewModel.isHumanizing { return "Humanizing Content..." }
        return "Loading..."
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...6, id: \.self) { step in
                Capsule()
                    .fill(viewModel.currentStep == step ? Color.accentColor : (viewModel.currentStep > step ? Color.accentColor.opacity(0.4) : Color(.tertiarySystemBackground)))
                    .frame(height: 6)
                    .animation(.spring(), value: viewModel.currentStep)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch viewModel.currentStep {
            case 6:
                VStack(alignment: .leading, spacing: 24) {
                    Text("Outline & References").font(.title2.bold())

                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Structured Outline", systemImage: "list.number")
                                .font(.headline)
                            Text("1. Introduction & Hook\n2. Thesis Statement\n3. Evidence Point A\n4. Evidence Point B\n5. Counter-argument\n6. Conclusion")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reference Manager", systemImage: "books.vertical.fill")
                            .font(.subheadline.bold())

                        Button {} label: {
                            Label("Add Source URL/DOI", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)

                        Text("No references added yet.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .id(6)
            case 1:
                VStack(alignment: .leading, spacing: 20) {
                    Text("What are you writing about?").font(.title2.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Topic", systemImage: "pencil.line")
                            .font(.subheadline).fontWeight(.semibold)
                        TextEditor(text: $viewModel.topic)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Essay Goal", systemImage: "theatermasks")
                            .font(.subheadline).fontWeight(.semibold)
                        Picker("Goal", selection: $viewModel.goal) {
                            ForEach(viewModel.goals, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .id(1)

            case 2:
                VStack(alignment: .leading, spacing: 20) {
                    Text("Define Core Thesis").font(.title2.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Thesis Statement", systemImage: "lightbulb")
                                .font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            if viewModel.suggestedThesisLoading {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        thesisSuggestAnimating = true
                                    }
                                    viewModel.suggestThesis()
                                } label: {
                                    Label("Suggest", systemImage: "sparkles")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                                }
                                .disabled(isAnyLoading)
                            }
                        }
                        TextEditor(text: $viewModel.thesis)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .suggestEssayDraftAnimation(thesisSuggestAnimating)
                            .onChange(of: viewModel.suggestedThesisLoading) { _, isLoading in
                                if !isLoading && thesisSuggestAnimating {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        thesisSuggestAnimating = false
                                    }
                                }
                            }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Key Points", systemImage: "list.bullet.indent")
                            .font(.subheadline).fontWeight(.semibold)
                        ForEach(0..<viewModel.keyPoints.count, id: \.self) { index in
                            HStack {
                                TextField("Key Point \(index + 1)", text: $viewModel.keyPoints[index])
                                    .textFieldStyle(.roundedBorder)
                                if viewModel.keyPoints.count > 1 {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        viewModel.keyPoints.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                    }
                                    .disabled(isAnyLoading)
                                }
                            }
                        }
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.keyPoints.append("")
                        }) {
                            Label("Add Key Point", systemImage: "plus.circle.fill")
                        }
                        .disabled(isAnyLoading)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .id(2)

            case 3:
                VStack(alignment: .leading, spacing: 24) {
                    Text("Style & Audience").font(.title2.bold())

                    ChipSelectorView(title: "Tone", icon: "theatermasks", selection: $viewModel.selectedTone, iconFor: { $0.icon })
                    ChipSelectorView(title: "Academic Standard", icon: "graduationcap", selection: $viewModel.selectedStandard, iconFor: { $0.icon })
                    ChipSelectorView(title: "Language Complexity", icon: "brain.head.profile", selection: $viewModel.selectedComplexity, iconFor: { $0.icon })

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Audience", systemImage: "person.text.rectangle")
                            .font(.subheadline).fontWeight(.semibold)
                        TextField("Students, Researchers, etc", text: $viewModel.audience)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Vocabulary Level", systemImage: "textformat.abc")
                            .font(.subheadline).fontWeight(.semibold)
                        Picker("Vocabulary", selection: $viewModel.vocabularyLevel) {
                            ForEach(EssayVocabularyLevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Paragraph Style", systemImage: "text.alignleft")
                            .font(.subheadline).fontWeight(.semibold)
                        Picker("Paragraph Style", selection: $viewModel.paragraphStyle) {
                            ForEach(EssayParagraphStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .disabled(isAnyLoading)
                .id(3)

            case 4:
                VStack(alignment: .leading, spacing: 24) {
                    Text("Smart Refinements").font(.title2.bold())

                    ChipSelectorView(title: "Citation Style", icon: "quote.bubble", selection: $viewModel.selectedCitationStyle, iconFor: { $0.icon })
                    ChipSelectorView(title: "Essay Length", icon: "ruler", selection: $viewModel.selectedLength, iconFor: { $0.icon })
                    ChipSelectorView(title: "Formatting Style", icon: "list.bullet.indent", selection: $viewModel.selectedFormatting, iconFor: { $0.icon })
                    ChipSelectorView(title: "Point Of View", icon: "person.text.rectangle", selection: $viewModel.selectedPOV, iconFor: { $0.icon })

                    VStack(alignment: .leading, spacing: 8) {
                        Label("What is your struggle?", systemImage: "questionmark.text.page.fill")
                            .font(.subheadline).fontWeight(.semibold)
                        Picker("Struggle", selection: $viewModel.struggle) {
                            ForEach(viewModel.struggles, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle(isOn: $viewModel.hookEnabled) {
                        Label("Include Compelling Hook", systemImage: "lightbulb")
                            .font(.subheadline).fontWeight(.semibold)
                    }

                    Toggle(isOn: $viewModel.includeCounterArguments) {
                        Label("Include Counter-Arguments", systemImage: "arrow.left.arrow.right")
                            .font(.subheadline).fontWeight(.semibold)
                    }

                    Toggle(isOn: $viewModel.includeTransitions) {
                        Label("Strong Paragraph Transitions", systemImage: "arrow.right.arrow.left")
                            .font(.subheadline).fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Source Citation Requirements", systemImage: "quote.bubble")
                            .font(.subheadline).fontWeight(.semibold)
                        Picker("Sources", selection: $viewModel.sourceRequirement) {
                            ForEach(viewModel.sourceRequirements, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Target Word Count", systemImage: "number.circle")
                                .font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text("\(viewModel.targetWordCount) words").font(.caption.bold()).foregroundStyle(Color.accentColor)
                        }
                        Slider(value: Binding(get: { Double(viewModel.targetWordCount) }, set: { viewModel.targetWordCount = Int($0) }), in: 200...5000, step: 100)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .disabled(isAnyLoading)
                .id(4)

            case 5:
                VStack(alignment: .leading, spacing: 20) {
                    Text("Finalize Generation").font(.title2.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Keywords (Optional)", systemImage: "tag")
                            .font(.subheadline).fontWeight(.semibold)
                        TextField("Enter keywords separated by commas", text: $viewModel.keywords)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Style Reference / Sample (Optional)", systemImage: "doc.text")
                            .font(.subheadline).fontWeight(.semibold)
                        TextEditor(text: $viewModel.styleReference)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Output Mode", systemImage: "doc.plaintext")
                            .font(.subheadline).fontWeight(.semibold)
                        ForEach(viewModel.outputModes, id: \.self) { mode in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.outputMode = mode
                            }) {
                                HStack {
                                    Text(mode)
                                    Spacer()
                                    if viewModel.outputMode == mode {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                            .disabled(isAnyLoading)
                        }
                    }

                    Button(action: {
                        viewModel.generateEssay()
                    }) {
                        HStack {
                            if viewModel.isGenerating {
                                ProgressView().tint(.white).padding(.trailing, 8)
                            }
                            Label(viewModel.isGenerating ? "Generating..." : "Generate Essay", systemImage: "doc.text.magnifyingglass")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isAnyLoading || viewModel.topic.isEmpty)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .id(5)
            default:
                EmptyView()
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep > 1 {
                Button {
                    transitionToStep(viewModel.currentStep - 1)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.tertiarySystemBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnyLoading)
            }

            if viewModel.currentStep < 6 {
                Button {
                    transitionToStep(viewModel.currentStep + 1)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnyLoading || (viewModel.currentStep == 1 && viewModel.topic.isEmpty))
            }
        }
        .padding()
    }

    private func transitionToStep(_ step: Int) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.isTransitioning = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            viewModel.currentStep = step
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            viewModel.isTransitioning = false
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with modern controls
            VStack(spacing: 12) {
                HStack {
                    Label("Generated Content", systemImage: "doc.text.magnifyingglass")
                        .font(.title3.bold())
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.showPreview = false
                    } label: {
                        Label("Edit Inputs", systemImage: "slider.horizontal.3")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemBackground), in: Capsule())
                    }
                    .disabled(isAnyLoading)
                }

                // Stats bar
                let wordCount = viewModel.generatedContent.split { $0.isWhitespace }.count
                let charCount = viewModel.generatedContent.count
                let sentenceCount = viewModel.generatedContent.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                let readingTime = max(1, wordCount / 200)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        previewStatChip(icon: "textformat.123", label: "\(wordCount) words")
                        previewStatChip(icon: "character.cursor.ibeam", label: "\(charCount) chars")
                        previewStatChip(icon: "text.alignleft", label: "\(sentenceCount) sentences")
                        previewStatChip(icon: "clock", label: "~\(readingTime) min read")
                    }
                }

                // Action toolbar
                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = viewModel.generatedContent
                        didCopy = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { didCopy = false }
                    } label: {
                        Label(didCopy ? "Copied" : "Copy All", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.caption.bold())
                            .foregroundColor(didCopy ? .green : .accentColor)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .disabled(isAnyLoading)

                    ShareLink(item: viewModel.generatedContent) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .disabled(isAnyLoading)

                    Spacer()

                    HStack(spacing: 4) {
                        Button {
                            contentFontSize = max(12, contentFontSize - 2)
                        } label: {
                            Image(systemName: "textformat.size.smaller")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            contentFontSize = min(28, contentFontSize + 2)
                        } label: {
                            Image(systemName: "textformat.size.larger")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            let parsed = viewModel.parseEssay(viewModel.generatedContent)
            let paragraphs = parsed.body
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // Content display
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !parsed.title.isEmpty {
                        Text(parsed.title)
                            .font(.system(size: contentFontSize + 4, weight: .bold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                        Text(LocalizedStringKey(paragraph))
                            .font(.system(size: contentFontSize))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(contentLineSpacing)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 500)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

            AIDetectorSectionView(viewModel: viewModel)
                .disabled(isAnyLoading)

            // Action buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: addToNote) {
                        Label("Add To Note", systemImage: "plus.square.on.square")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isAnyLoading)

                    Button(action: { viewModel.generateEssay() }) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.tertiarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isAnyLoading)
                }

                Button(action: { viewModel.humanize() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.shield.checkmark")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Humanizer")
                                .font(.subheadline.bold())
                            Text("Make it sound 100% human-written")
                                .font(.caption2)
                                .opacity(0.85)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .opacity(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnyLoading)
            }
        }
    }

    private func previewStatChip(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.accentColor)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground), in: Capsule())
    }

    private func addToNote() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let nb = manager.notebooks.first, let folder = nb.folders.first {
            manager.addPage(to: folder.id, in: nb.id, title: "Draft: \(viewModel.topic)", content: viewModel.generatedContent)
        }
        dismiss()
    }
}

// MARK: - Subviews

struct ChipSelectorView<T: RawRepresentable & CaseIterable & Identifiable>: View
    where T.RawValue == String {
    let title: String
    let icon: String
    @Binding var selection: T
    let iconFor: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(T.allCases) as! [T]) { option in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selection = option
                        } label: {
                            Label(option.rawValue, systemImage: iconFor(option))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selection.id == option.id
                                        ? Color.accentColor
                                        : Color(.tertiarySystemBackground)
                                )
                                .foregroundColor(
                                    selection.id == option.id ? .white : .primary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        selection.id == option.id
                                            ? Color.clear
                                            : Color(.separator),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

struct AIDetectorSectionView: View {
    @ObservedObject var viewModel: EssayDraftingViewModel
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (tappable to expand/collapse)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring()) { isExpanded.toggle() }
            } label: {
                HStack {
                    Label("AI Detection", systemImage: "eye.trianglebadge.exclamationmark")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if isExpanded {
                VStack(spacing: 16) {
                    // Scan button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await viewModel.runAIDetection() }
                    } label: {
                        if viewModel.isDetecting {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Scanning...")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Scan for AI Content", systemImage: "waveform.badge.magnifyingglass")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .disabled(viewModel.isDetecting || viewModel.generatedContent.isEmpty)

                    // Error state
                    if let error = viewModel.detectionError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Result card
                    if let result = viewModel.aiDetectionResult {
                        VStack(spacing: 14) {
                            // Classification badge
                            HStack {
                                Image(systemName: result.classification.icon)
                                    .font(.title2)
                                    .foregroundColor(result.classification.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.classification.label)
                                        .font(.headline)
                                        .foregroundColor(result.classification.color)
                                    Text("Confidence: \(Int(result.score * 100))% AI probability")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }

                            // Score meter
                            VStack(alignment: .leading, spacing: 6) {
                                Label("AI Probability Score", systemImage: "gauge.with.dots.needle.33percent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.tertiarySystemBackground))
                                            .frame(height: 10)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.green, .orange, .red],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: geo.size.width * result.score,
                                                height: 10
                                            )
                                            .animation(.spring(), value: result.score)
                                    }
                                }
                                .frame(height: 10)

                                HStack {
                                    Text("Human")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Spacer()
                                    Text("AI")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }

                            // Per-sentence breakdown (if available)
                            if !result.sentenceScores.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("Sentence Breakdown", systemImage: "list.bullet.rectangle")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    ForEach(result.sentenceScores.prefix(8)) { item in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle()
                                                .fill(item.score > 0.65 ? Color.red :
                                                      item.score > 0.2 ? Color.orange : Color.green)
                                                .frame(width: 8, height: 8)
                                                .padding(.top, 5)
                                            Text(item.sentence)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                            Text("\(Int(item.score * 100))%")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    if result.sentenceScores.count > 8 {
                                        Text("+ \(result.sentenceScores.count - 8) More Sentences")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Advice based on result
                            if result.classification == .aiGenerated || result.classification == .mixed {
                                HStack(spacing: 6) {
                                    Image(systemName: "lightbulb")
                                        .foregroundColor(.yellow)
                                    Text("Try using the Humanizer to reduce AI signals.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
