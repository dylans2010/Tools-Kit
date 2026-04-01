import Foundation
class MeetingNotesBackend: ObservableObject {
    @Published var notes = ""
    func generate() { notes = "Sample Meeting Notes" }
}
