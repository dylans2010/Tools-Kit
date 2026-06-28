import Foundation

@available(iOS 27.0, *)
class RecordingStorageManager {
    static let shared = RecordingStorageManager()

    private let fileManager = FileManager.default

    private var recordingsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("ScreenRecordings", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func getURL(for sessionID: UUID, ext: String) -> URL {
        return recordingsDirectory.appendingPathComponent("\(sessionID.uuidString).\(ext)")
    }

    func saveSession(_ session: SCKRecordingSession) {
        let url = getURL(for: session.id, ext: "json")
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: url)
        } catch {
            print("Failed to save session metadata: \(error)")
        }
    }

    func loadSessions() -> [SCKRecordingSession] {
        guard let files = try? fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        return files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(SCKRecordingSession.self, from: data)
        }.sorted(by: { $0.startTime > $1.startTime })
    }

    func deleteSession(_ session: SCKRecordingSession) {
        let jsonURL = getURL(for: session.id, ext: "json")
        let movURL = getURL(for: session.id, ext: "mov")
        try? fileManager.removeItem(at: jsonURL)
        try? fileManager.removeItem(at: movURL)
    }
}
