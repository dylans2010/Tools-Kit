import Foundation
import UIKit
import AuthenticationServices

@MainActor
final class LMLinkAuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = LMLinkAuthManager()
    @Published private(set) var state: LMLinkAuthState = .idle {
        didSet {
            let connected: Bool
            if case .connected = state {
                connected = true
            } else {
                connected = false
            }
            isConnected = connected
            isLinked = connected
        }
    }

    @Published var isConnected: Bool = false
    @Published var isLinked: Bool = false

    var keyId: String? {
        if case .connected(let session) = state {
            return session.keyId
        }
        return nil
    }

    private let keychain = LMLinkKeychainService()
    private let validator = LMLinkAPIValidator()
    private var pendingKeyId: String?
    private var timeoutTask: Task<Void, Never>?
    private var authSession: ASWebAuthenticationSession?

    override init() {
        super.init()
    }

    func initiateLink() {
        Task {
            await beginAuthorization()
        }
    }

    func beginAuthorization() async {
        guard state == .idle || {
            if case .error = state { return true }
            return false
        }() else { return }
        state = .authorizing

        do {
            let (keyId, publicKeyBase64) = try LMLinkKeyPairService.generateKeyPair()
            pendingKeyId = keyId

            var components = URLComponents(string: "https://lmstudio.ai/authentication-request")
            components?.queryItems = [
                URLQueryItem(name: "keyId",         value: keyId),
                URLQueryItem(name: "publicKey",     value: publicKeyBase64),
                URLQueryItem(name: "feature",       value: "lmlink"),
                URLQueryItem(name: "returnTo",      value: "toolskit://lm-callback"),
                URLQueryItem(name: "clientKind",    value: "ios"),
                URLQueryItem(name: "clientVersion", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            ]
            guard let authURL = components?.url else {
                state = .error(.browserOpenFailed)
                return
            }

            LMLinkLogger.auth.info("Opening ASWebAuthenticationSession for keyId: \(keyId, privacy: .private(mask: .hash))")

            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "toolskit"
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    if let error = error {
                        if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                            self?.state = .error(.cancelled)
                        } else {
                            self?.state = .error(.browserOpenFailed)
                        }
                        LMLinkLogger.auth.error("ASWebAuthenticationSession failed: \(error.localizedDescription, privacy: .public)")
                        return
                    }

                    if let callbackURL = callbackURL {
                        await self?.handleCallback(url: callbackURL)
                    }
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            self.authSession = session
            if session.start() {
                state = .awaitingCallback
                startTimeoutTimer()
            } else {
                state = .error(.browserOpenFailed)
                LMLinkLogger.auth.error("Failed to start ASWebAuthenticationSession")
            }
        } catch {
            LMLinkLogger.auth.error("Key pair generation failed: \(error.localizedDescription, privacy: .public)")
            state = .error(.keyPairGenerationFailed)
        }
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func handleCallback(url: URL) async {
        let result = LMLinkCallbackParser.parse(url: url)

        // Handle Cold-start or unexpected state transitions
        if case .awaitingCallback = state {
            // Normal flow
        } else {
            // Check if this is a valid callback for a key we generated
            if case .success(_, let keyId, _) = result {
                do {
                    _ = try LMLinkKeyPairService.loadPrivateKey(for: keyId)
                    LMLinkLogger.deeplink.info("Processing callback for known keyId: \(keyId) despite state: \(String(describing: self.state))")
                } catch {
                    LMLinkLogger.deeplink.error("Ignoring callback for unknown keyId: \(keyId)")
                    return
                }
            } else {
                LMLinkLogger.deeplink.info("Ignoring duplicate or invalid callback — state is not awaitingCallback")
                return
            }
        }

        cancelTimeoutTimer()
        state = .awaitingCallback
        LMLinkLogger.deeplink.info("Handling callback URL: \(url.host ?? "nil", privacy: .public)")

        switch result {
        case .success(let credential, let keyId, let userId):
            // Skip ping during callback on iOS to avoid localhost/sandbox issues.
            // Connectivity is verified during discovery or first request.
            let isReachable = false
            let modelCount = 0

            let session = LMLinkSession(
                keyId: keyId,
                credential: credential,
                userId: userId,
                connectedAt: Date(),
                localServerReachable: isReachable,
                localModelCount: modelCount
            )
            let saveResult = keychain.save(credential: credential, keyId: keyId, userId: userId)
            if case .failure(let err) = saveResult {
                state = .error(err)
                return
            }
            state = .connected(session: session)
            LMLinkLogger.auth.info("Auth complete. User: \(userId, privacy: .private(mask: .hash))")

        case .cancelled:
            state = .error(.cancelled)
        case .denied:
            state = .error(.denied)
        case .error(let reason):
            LMLinkLogger.deeplink.error("Callback error param: \(reason, privacy: .public)")
            state = .error(.malformedCallback)
        case .malformed:
            state = .error(.malformedCallback)
        }
    }

    func restoreSession() async {
        switch keychain.load() {
        case .success(let (credential, keyId, userId)):
            // Skip ping during restore on iOS.
            let isReachable = false
            let modelCount = 0

            let session = LMLinkSession(
                keyId: keyId, credential: credential, userId: userId,
                connectedAt: Date(),
                localServerReachable: isReachable,
                localModelCount: modelCount
            )
            state = .connected(session: session)
            LMLinkLogger.auth.info("Session restored from Keychain")
        case .failure:
            state = .idle
        }
    }

    func unlink() {
        disconnect()
    }

    func disconnect() {
        cancelTimeoutTimer()
        if case .connected(let session) = state {
            LMLinkKeyPairService.deleteKeyPair(for: session.keyId)
        }
        _ = keychain.clear()
        state = .idle
        LMLinkLogger.auth.info("User disconnected")
    }

    private func startTimeoutTimer() {
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if case .awaitingCallback = self?.state {
                    self?.state = .error(.timeout)
                    self?.pendingKeyId = nil
                    LMLinkLogger.auth.error("Auth timed out after 120 seconds")
                }
            }
        }
    }

    private func cancelTimeoutTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}
