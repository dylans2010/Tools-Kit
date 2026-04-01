import Foundation
import Combine

class NotesBackend: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?

    private let savePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("notes.json")

    init() {
        loadNotes()
    }

    func createNote() -> Note {
        let newNote = Note()
        notes.append(newNote)
        saveNotes()
        return newNote
    }

    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()

            if updatedNote.content != notes[index].content {
                let version = NoteVersion(content: notes[index].content)
                updatedNote.versionHistory.append(version)
            }

            notes[index] = updatedNote
            saveNotes()
        }
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: savePath)
        } catch {
            print("Error saving notes: \(error)")
        }
    }

    func loadNotes() {
        do {
            if FileManager.default.fileExists(atPath: savePath.path) {
                let data = try Data(contentsOf: savePath)
                notes = try JSONDecoder().decode([Note].self, from: data)
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }

    func exportAsTXT(note: Note) -> URL? {
        let fileName = "\(note.title).txt"
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? note.content.write(to: tempPath, atomically: true, encoding: .utf8)
        return tempPath
    }

    func exportAsMarkdown(note: Note) -> URL? {
        let fileName = "\(note.title).md"
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let mdContent = "# \(note.title)\n\n\(note.content)"
        try? mdContent.write(to: tempPath, atomically: true, encoding: .utf8)
        return tempPath
    }

    func summarizeNote(_ note: Note, completion: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            completion("Summary of \(note.title): This note contains information about \(note.content.prefix(50))...")
        }
    }
}
