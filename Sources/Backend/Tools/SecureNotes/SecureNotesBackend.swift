import Foundation
class SecureNotesBackend: ObservableObject {
    @Published var authenticated = false
    func auth() { authenticated = true }
}
