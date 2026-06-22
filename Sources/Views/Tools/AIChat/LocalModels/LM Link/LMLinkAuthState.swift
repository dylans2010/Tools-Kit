import Foundation

enum LMLinkAuthState: Equatable {
    case idle
    case authorizing
    case awaitingCallback
    case connected(session: LMLinkSession)
    case error(LMLinkAuthError)
}

struct LMLinkSession: Equatable, Sendable {
    let keyId: String
    let credential: String
    let userId: String
    let connectedAt: Date
    let localServerReachable: Bool
    let localModelCount: Int
}

enum LMLinkAuthError: Error, Equatable, LocalizedError {
    case browserOpenFailed
    case cancelled
    case denied
    case missingCredential
    case malformedCallback
    case keychainFailure(String)
    case serverUnreachable
    case timeout
    case keyPairGenerationFailed

    var errorDescription: String? {
        switch self {
        case .browserOpenFailed:
            return "Could not open lmstudio.ai. Check your internet connection and try again."
        case .cancelled:
            return "Sign in was cancelled. Tap Sign In to try again."
        case .denied:
            return "Access was denied by lmstudio.ai. Ensure you have a valid LM Studio account."
        case .missingCredential:
            return "The authentication response was incomplete. Please try again."
        case .malformedCallback:
            return "An unexpected response was received from lmstudio.ai. Please try again."
        case .keychainFailure(let detail):
            return "Could not save your session (\(detail)). Please try again."
        case .serverUnreachable:
            return "Could not reach the LM Studio local server. Ensure LM Studio is running."
        case .timeout:
            return "Sign in timed out. The browser was open for too long without a response."
        case .keyPairGenerationFailed:
            return "Could not generate a secure key pair. Please restart the app and try again."
        }
    }
}
