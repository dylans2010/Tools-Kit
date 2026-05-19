import SwiftUI

struct DatamuseResult: Codable {
    let word: String
    let score: Int?
    let tags: [String]?
    let numSyllables: Int?
}

@MainActor
final class WordSuggestionsViewModel: ObservableObject {
    @Published var inputWord = ""
    @Published var isLoading = false
    @Published var synonyms: [String] = []
    @Published var antonyms: [String] = []
    @Published var simplerWords: [String] = []
    @Published var complexerWords: [String] = []
    @Published var rhymes: [String] = []
    @Published var related: [String] = []
    @Published var errorMessage: String? = nil

    private let engine = WritingAnalyticsEngine.shared

    func fetchSuggestions(for word: String) async {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputWord = trimmed
        isLoading = true
        errorMessage = nil

        let inputSyllables = engine.countSyllables(trimmed)

        async let synonymsResults = fetchDatamuse(endpoint: "https://api.datamuse.com/words?ml=\(trimmed)&max=15")
        async let spellingResults = fetchDatamuse(endpoint: "https://api.datamuse.com/words?sp=\(trimmed)*&max=8")
        async let antonymsResults = fetchDatamuse(endpoint: "https://api.datamuse.com/words?rel_ant=\(trimmed)&max=10")
        async let rhymesResults = fetchDatamuse(endpoint: "https://api.datamuse.com/words?rel_rhy=\(trimmed)&max=10")
        async let relatedResults = fetchDatamuse(endpoint: "https://api.datamuse.com/words?rel_jja=\(trimmed)&max=10")

        do {
            let syns = try await synonymsResults
            let spells = try await spellingResults
            let ants = try await antonymsResults
            let rhy = try await rhymesResults
            let rel = try await relatedResults

            self.synonyms = syns.map { $0.word }
            self.antonyms = ants.map { $0.word }
            self.rhymes = rhy.map { $0.word }
            self.related = (rel + spells).map { $0.word }

            self.simplerWords = syns.filter { engine.countSyllables($0.word) < inputSyllables }.map { $0.word }
            self.complexerWords = syns.filter { engine.countSyllables($0.word) > inputSyllables }.map { $0.word }

        } catch {
            errorMessage = "Failed to fetch suggestions."
        }

        isLoading = false
    }

    private func fetchDatamuse(endpoint: String) async throws -> [DatamuseResult] {
        guard let url = URL(string: endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else { return [] }
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode([DatamuseResult].self, from: data)
    }
}
