import Foundation
import LocalAuthentication

struct SecureNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var date: Date
}

class SecureNotesBackend: ObservableObject {
    @Published var notes: [SecureNote] = []
    @Published var isAuthenticated = false
    @Published var error: String? = nil

    private let savePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("secure_notes.json")

    init() {
        loadNotes()
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your secure notes") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                    } else {
                        self.error = authenticationError?.localizedDescription ?? "Authentication failed"
                    }
                }
            }
        } else {
            // Fallback to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your secure notes") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                    } else {
                        self.error = authenticationError?.localizedDescription ?? "Authentication failed"
                    }
                }
            }
        }
    }

    func addNote(title: String, content: String) {
        let note = SecureNote(id: UUID(), title: title, content: content, date: Date())
        notes.append(note)
        saveNotes()
    }

    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }

    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: savePath)
        } catch {
            print("Error saving secure notes: \(error)")
        }
    }

    private func loadNotes() {
        do {
            if FileManager.default.fileExists(atPath: savePath.path) {
                let data = try Data(contentsOf: savePath)
                notes = try JSONDecoder().decode([SecureNote].self, from: data)
            }
        } catch {
            print("Error loading secure notes: \(error)")
        }
    }

    func lock() {
        isAuthenticated = false
    }
}
