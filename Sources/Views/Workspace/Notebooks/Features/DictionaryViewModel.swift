import SwiftUI
import AVFoundation

struct DictionaryResult: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]
    let meanings: [DictionaryMeaning]
    let sourceUrls: [String]
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

struct DictionaryMeaning: Codable, Identifiable {
    let id = UUID()
    let partOfSpeech: String
    let definitions: [DictionaryDefinition]

    enum CodingKeys: String, CodingKey {
        case partOfSpeech, definitions
    }
}

struct DictionaryDefinition: Codable, Identifiable {
    let id = UUID()
    let definition: String
    let example: String?
    let synonyms: [String]
    let antonyms: [String]

    enum CodingKeys: String, CodingKey {
        case definition, example, synonyms, antonyms
    }
}

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var result: DictionaryResult? = nil
    @Published var errorMessage: String? = nil
    @Published var recentSearches: [String] = []

    private let recentSearchesKey = "dictionaryRecentSearches"
    private var audioPlayer: AVPlayer?

    init() {
        self.recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    func search(word: String) async {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else { return }

        searchText = trimmedWord
        isLoading = true
        errorMessage = nil
        result = nil

        updateRecentSearches(word: trimmedWord)

        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(trimmedWord.lowercased())") else {
            errorMessage = "Invalid word."
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                errorMessage = "Word not found."
                isLoading = false
                return
            }

            let results = try JSONDecoder().decode([DictionaryResult].self, from: data)
            self.result = results.first
        } catch {
            errorMessage = "Failed to fetch definition."
        }

        isLoading = false
    }

    func playAudio() {
        guard let audioUrlString = result?.phonetics.first(where: { !($0.audio ?? "").isEmpty })?.audio,
              let url = URL(string: audioUrlString) else { return }

        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    private func updateRecentSearches(word: String) {
        if let index = recentSearches.firstIndex(of: word) {
            recentSearches.remove(at: index)
        }
        recentSearches.insert(word, at: 0)
        if recentSearches.count > 20 {
            recentSearches.removeLast()
        }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}
