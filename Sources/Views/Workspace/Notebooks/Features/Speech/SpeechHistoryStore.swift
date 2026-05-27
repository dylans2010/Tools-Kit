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
            ($0.analysis?.fullTranscript.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}
