import SwiftUI
import Combine

@MainActor
final class WritingAnalyticsViewModel: ObservableObject {
    enum AnalyticsTab: String, CaseIterable, Identifiable {
        case overview, readability, tone, structure, vocabulary, grammar, plagiarism, search, craftread
        var id: String { rawValue }
        var label: String {
            switch self {
            case .overview: return "Overview"
            case .readability: return "Readability"
            case .tone: return "Tone"
            case .structure: return "Structure"
            case .vocabulary: return "Vocabulary"
            case .grammar: return "Grammar"
            case .plagiarism: return "Plagiarism"
            case .search: return "Search"
            case .craftread: return "CraftRead"
            }
        }
        var systemImage: String {
            switch self {
            case .overview: return "doc.text.magnifyingglass"
            case .readability: return "book.closed"
            case .tone: return "face.smiling"
            case .structure: return "reproduction"
            case .vocabulary: return "character.book.closed"
            case .grammar: return "checkmark.circle"
            case .plagiarism: return "doc.on.doc"
            case .search: return "magnifyingglass"
            case .craftread: return "sparkles"
            }
        }
        var accentColor: Color {
            switch self {
            case .overview: return .blue
            case .readability: return .green
            case .tone: return .orange
            case .structure: return .purple
            case .vocabulary: return .indigo
            case .grammar: return .teal
            case .plagiarism: return .red
            case .search: return .gray
            case .craftread: return .pink
            }
        }
    }

    enum GrammarCheckMode {
        case idle, running, done
    }

    @Published var activeTab: AnalyticsTab = .overview
    @Published var stats = WritingStats()
    @Published var tone = ToneAnalysis()
    @Published var sentenceLengths = SentenceLengthAnalysis()
    @Published var complexity = WordComplexity()
    @Published var wordFrequency: [WordFrequencyItem] = []
    @Published var overusedWords: [OverusedWord] = []
    @Published var suggestions: [ImprovementSuggestion] = []
    @Published var grammarIssues: [GrammarIssue] = []
    @Published var isCheckingGrammar = false
    @Published var grammarCheckMode: GrammarCheckMode = .idle
    @Published var plagiarismResult: PlagiarismResult? = nil
    @Published var isRunningPlagiarism = false
    @Published var searchTerm = ""
    @Published var searchMatches: [SearchMatch] = []
    @Published var chatMessages: [AnalyticsChatMessage] = []
    @Published var chatInput = ""
    @Published var isGenerating = false

    private let engine = WritingAnalyticsEngine.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchTerm
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] term in
                guard let self = self else { return }
                // We'll call this from the View with the text
            }
            .store(in: &cancellables)
    }

    func runAnalysis(text: String) {
        Task {
            let stats = engine.computeStats(text: text)
            let tone = engine.analyzeTone(text: text)
            let structure = engine.analyzeSentenceLength(text: text)
            let complexity = engine.analyzeWordComplexity(text: text)
            let frequency = engine.computeWordFrequency(text: text)
            let overused = engine.findOverusedWords(from: frequency, totalWords: stats.wordCount)
            let suggestions = engine.generateImprovementSuggestions(stats: stats, overused: overused, tone: tone)

            self.stats = stats
            self.tone = tone
            self.sentenceLengths = structure
            self.complexity = complexity
            self.wordFrequency = frequency
            self.overusedWords = overused
            self.suggestions = suggestions
        }
    }

    func performSearch(text: String) {
        searchMatches = engine.searchMatches(in: text, term: searchTerm)
    }

    func checkGrammar(text: String, useAPI: Bool) {
        isCheckingGrammar = true
        grammarCheckMode = .running
        Task {
            do {
                if useAPI {
                    grammarIssues = try await engine.checkGrammarWithAPI(text: text)
                } else {
                    grammarIssues = engine.checkGrammarLocally(text: text)
                }
            } catch {
                grammarIssues = engine.checkGrammarLocally(text: text)
            }
            isCheckingGrammar = false
            grammarCheckMode = .done
        }
    }

    func runPlagiarismScan(text: String) {
        isRunningPlagiarism = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // fake delay
            plagiarismResult = engine.runLocalPlagiarismScan(text: text)
            isRunningPlagiarism = false
        }
    }

    func sendChatMessage(documentText: String) {
        guard !chatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = AnalyticsChatMessage(role: "user", content: chatInput)
        chatMessages.append(userMessage)
        let prompt = chatInput
        chatInput = ""
        isGenerating = true

        Task {
            let systemInstruction = "You are CraftRead, an AI writing assistant built into Tools-Kit. You have access to detailed analytics about the user’s writing. Provide specific, actionable advice. Format your responses with Markdown: headings, bullet lists, and tables where helpful."

            let context = """
            ### Document Context
            Title: Writing Analysis
            Stats: \(stats.wordCount) words, \(stats.sentenceCount) sentences, \(stats.paragraphCount) paragraphs.
            Readability: \(stats.readabilityScore) (Flesch Score)
            Tone: \(tone.primary) (Confidence: \(tone.confidence)%)
            Vocabulary Richness: \(stats.vocabularyRichness)%

            ### Document Sample
            \(documentText.prefix(500))
            """

            let fullPrompt = "\(systemInstruction)\n\n\(context)\n\nUser: \(prompt)"

            do {
                let response = try await AIService.shared.processText(prompt: fullPrompt)
                let assistantMessage = AnalyticsChatMessage(role: "assistant", content: response)
                chatMessages.append(assistantMessage)
            } catch {
                let errorMessage = AnalyticsChatMessage(role: "assistant", content: "I encountered an error. Please check your AI configuration in Settings. (\(error.localizedDescription))")
                chatMessages.append(errorMessage)
            }
            isGenerating = false
        }
    }

    let craftReadPrompts: [(label: String, value: String)] = [
        ("💡 Improve Readability", "How can I improve the readability of my writing?"),
        ("🎭 Analyze Tone", "What's the tone of my writing?"),
        ("📚 Word Suggestions", "Suggest better word choices"),
        ("✨ Make It Engaging", "How can I make my writing more engaging?"),
        ("📊 Language Level", "What language level is this?"),
        ("🎖️ Check My Writing", "Is my writing clear?"),
        ("🪄 Vocabulary Suggestions", "Rate my vocabulary usage and give me suggestions"),
        ("📝 Paragraph Structure", "How can I improve the structure of my paragraphs?"),
        ("🔄 Improve Transitions", "What's the best way to transition between these sections?"),
        ("🎬 Create Conclusion", "Can you help me write a strong conclusion?"),
        ("✨ Enhance Introduction", "How can I make my introduction more captivating?"),
        ("🔍 Identify Themes", "What's the main theme of my writing?"),
        ("⚡ Strengthen Arguments", "How can I make my argument more persuasive?"),
        ("🌊 Check Narrative Flow", "Is my narrative flow working well?"),
        ("👔 Assess Formality", "How formal or informal is my writing style?"),
        ("🧭 Clarify Thesis", "What is a clear thesis statement for this?"),
        ("🗂️ Suggest Outline", "Can you outline the key points I should cover?"),
        ("🧹 Remove Repetition", "Which sections feel repetitive and how can I fix them?"),
        ("🧪 Add Supporting Evidence", "Where should I add supporting evidence or examples?"),
        ("🛠️ Fix Passive Voice", "Rewrite my passive sentences to be more active."),
        ("🎢 Vary Sentences", "Give feedback on my sentence variety."),
        ("🚀 Power Up Verbs", "Suggest stronger verbs for this piece."),
        ("🎯 Target Audience", "How can I better address my target audience?"),
        ("📈 Add Call To Action", "Help me write an engaging call to action."),
        ("📌 Summarize Note", "Summarize this note in a few bullet points."),
        ("🧠 Check Logic", "Highlight any logical gaps or jumps in reasoning."),
        ("⏱️ Adjust Pacing", "Offer ways to improve the pacing of this piece."),
        ("🎨 Enhance Descriptions", "How can I make my descriptions more vivid?"),
        ("🏷️ Improve Title", "Suggest a more compelling title."),
        ("❓ Ask Better Questions", "Help me craft better questions to engage readers.")
    ]
}
