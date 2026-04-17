import Foundation

final class AIMentorMemoryStore {
    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Workouts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var memoryURL: URL {
        saveDir.appendingPathComponent("mentor_memory.json")
    }

    func load() -> [MentorMessageModel] {
        guard let data = try? Data(contentsOf: memoryURL),
              let decoded = try? JSONDecoder().decode([MentorMessageModel].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ messages: [MentorMessageModel]) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        try? data.write(to: memoryURL, options: .atomic)
    }
}
