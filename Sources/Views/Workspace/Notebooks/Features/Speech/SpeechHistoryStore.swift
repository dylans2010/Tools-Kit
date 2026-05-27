import Foundation

@MainActor
final class SpeechHistoryStore: ObservableObject {
    static let shared = SpeechHistoryStore()

    @Published var recordings: [SpeechRecording] = []

    private let storageKey = "speech_recordings_history"
    private let fileManager = FileManager.default

    private init() {
        loadRecordings()
    }

    func saveRecording(_ recording: SpeechRecording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
        } else {
            recordings.insert(recording, at: 0)
        }
        persist()
    }

    func deleteRecording(_ recording: SpeechRecording) {
        // Delete audio file
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(recording.audioFilename)
        try? fileManager.removeItem(at: fileURL)

        recordings.removeAll { $0.id == recording.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadRecordings() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SpeechRecording].self, from: data) {
            self.recordings = decoded.sorted(by: { $0.date > $1.date })
        }
    }

    func search(query: String) -> [SpeechRecording] {
        if query.isEmpty { return recordings }
        return recordings.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            ($0.analysis?.fullTranscript.localizedCaseInsensitiveContains(query) ?? false) ||
            ($0.analysis?.summary.localizedCaseInsensitiveContains(query) ?? false) ||
            ($0.analysis?.insights.contains(where: { $0.text.localizedCaseInsensitiveContains(query) }) ?? false) ||
            ($0.tags.contains(where: { $0.name.localizedCaseInsensitiveContains(query) }))
        }
    }

    // MARK: - Advanced Capabilities

    func compareAndMerge(recordingIds: [UUID]) async -> SpeechAnalysis? {
        let selected = recordings.filter { recordingIds.contains($0.id) }
        guard selected.count > 1 else { return nil }

        let transcripts = selected.map { "\($0.title):\n\($0.analysis?.fullTranscript ?? "")" }.joined(separator: "\n\n")
        let prompt = "Analyze these multiple recordings together. Detect contradictions, repeated themes, trend analysis, and provide merged action items.\n\n\(transcripts)"

        do {
            let schema = """
            {
                "summary": "String",
                "keyPoints": ["String"],
                "actionItems": ["String"],
                "topics": [],
                "insights": [],
                "highlights": [],
                "suggestions": [],
                "sentiment": "String",
                "intentClassification": "String",
                "priorityScore": "Number"
            }
            """
            let jsonString = try await AIService.shared.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
            if let data = jsonString.data(using: .utf8) {
                return try JSONDecoder().decode(SpeechAnalysis.self, from: data)
            }
        } catch {
            print("Compare and merge error: \(error)")
        }
        return nil
    }
}
