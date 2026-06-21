import Foundation

@MainActor
class AFMSessionManager: ObservableObject {
    static let shared = AFMSessionManager()

    @Published var sessionID = UUID()
    @Published var messageCount = 0

    func startNewSession() {
        AFMService.shared.resetSession()
        sessionID = UUID()
        messageCount = 0
    }

    func recordMessage() {
        messageCount += 1
    }
}
