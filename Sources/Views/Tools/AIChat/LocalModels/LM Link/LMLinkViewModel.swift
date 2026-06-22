import Foundation
import Observation

@MainActor
@Observable
final class LMLinkViewModel {
    private let manager = LMLinkAuthManager.shared

    var authState: LMLinkAuthState { manager.state }

    var isLoading: Bool {
        switch manager.state {
        case .authorizing, .awaitingCallback: return true
        default: return false
        }
    }

    var statusTitle: String {
        switch manager.state {
        case .idle:               return "Connect with LM Link"
        case .authorizing:        return "Opening lmstudio.ai…"
        case .awaitingCallback:   return "Waiting for sign-in…"
        case .connected:          return "Connected"
        case .error:              return "Sign In Failed"
        }
    }

    var statusSubtitle: String {
        switch manager.state {
        case .idle:               return "Sign in with your LM Studio account to use local models"
        case .authorizing:        return "Complete sign-in in your browser"
        case .awaitingCallback:   return "Return to Tools-Kit after authorizing in the browser"
        case .connected(let s):   return s.localServerReachable ? "Local server online · \(s.localModelCount) model\(s.localModelCount == 1 ? "" : "s")" : "Connected · Local server offline"
        case .error(let e):       return e.errorDescription ?? "An unknown error occurred"
        }
    }

    var errorMessage: String? {
        if case .error(let e) = manager.state { return e.errorDescription }
        return nil
    }

    func signIn() {
        Task { await manager.beginAuthorization() }
    }

    func disconnect() {
        manager.disconnect()
    }
}
