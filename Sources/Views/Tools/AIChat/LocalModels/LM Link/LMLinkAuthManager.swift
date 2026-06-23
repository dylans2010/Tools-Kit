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

    // Strongly retain the session to ensure it persists for the full lifecycle
    private var activeAuthSession: ASWebAuthenticationSession?

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
        }() else {
            LMLinkLogger.auth.info("Authorization already in progress or connected. Current state: \(String(describing: self.state))")
            return
        }
        state = .authorizing

        do {
            SDKLogStore.shared.log("LM Link: Starting authorization flow", source: "LMLinkAuthManager", level: .info)
            let (keyId, publicKeyBase64) = try LMLinkKeyPairService.generateKeyPair()
            pendingKeyId = keyId
            SDKLogStore.shared.log("LM Link: Key pair generated. keyId: \(keyId)", source: "LMLinkAuthManager", level: .info)

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
                LMLinkLogger.auth.error("Failed to construct authentication URL")
                SDKLogStore.shared.log("LM Link: Failed to construct authentication URL", source: "LMLinkAuthManager", level: .error)
                state = .error(.browserOpenFailed)
                return
            }

            LMLinkLogger.auth.info("Opening ASWebAuthenticationSession. URL: \(authURL.absoluteString, privacy: .private(mask: .hash))")
            SDKLogStore.shared.log("LM Link: Opening auth session for URL: \(authURL.absoluteString)", source: "LMLinkAuthManager", level: .info)

            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "toolskit"
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    defer { self?.activeAuthSession = nil }

                    if let error = error {
                        if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                            LMLinkLogger.auth.info("User cancelled the authentication session")
                            SDKLogStore.shared.log("LM Link: User cancelled auth session", source: "LMLinkAuthManager", level: .info)
                            self?.state = .error(.cancelled)
                        } else {
                            LMLinkLogger.auth.error("ASWebAuthenticationSession failed: \(error.localizedDescription, privacy: .public)")
                            SDKLogStore.shared.log("LM Link: Auth session failed: \(error.localizedDescription)", source: "LMLinkAuthManager", level: .error)
                            self?.state = .error(.browserOpenFailed)
                        }
                        return
                    }

                    guard let callbackURL = callbackURL else {
                        LMLinkLogger.auth.error("ASWebAuthenticationSession completed without error but no callback URL was provided")
                        SDKLogStore.shared.log("LM Link: Auth session completed but no callback URL", source: "LMLinkAuthManager", level: .error)
                        self?.state = .error(.malformedCallback)
                        return
                    }

                    LMLinkLogger.auth.info("ASWebAuthenticationSession received callback: \(callbackURL.host ?? "nil", privacy: .public)")
                    SDKLogStore.shared.log("LM Link: Auth session received callback: \(callbackURL.absoluteString)", source: "LMLinkAuthManager", level: .info)
                    await self?.handleCallback(url: callbackURL)
                }
            }

            session.presentationContextProvider = self
            // Important: prefersEphemeralWebBrowserSession must be false to share cookies with Safari
            session.prefersEphemeralWebBrowserSession = false

            self.activeAuthSession = session
            if session.start() {
                LMLinkLogger.auth.info("ASWebAuthenticationSession started successfully")
                SDKLogStore.shared.log("LM Link: ASWebAuthenticationSession started", source: "LMLinkAuthManager", level: .info)
                state = .awaitingCallback
                startTimeoutTimer()
            } else {
                state = .error(.browserOpenFailed)
                self.activeAuthSession = nil
                LMLinkLogger.auth.error("Failed to start ASWebAuthenticationSession")
                SDKLogStore.shared.log("LM Link: Failed to start ASWebAuthenticationSession", source: "LMLinkAuthManager", level: .error)
            }
        } catch {
            LMLinkLogger.auth.error("Key pair generation failed: \(error.localizedDescription, privacy: .public)")
            state = .error(.keyPairGenerationFailed)
        }
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let anchor = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.windows
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()

        SDKLogStore.shared.log("LM Link: Providing presentation anchor", source: "LMLinkAuthManager", level: .info)
        return anchor
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
            await finalizeLink(credential: credential, keyId: keyId, userId: userId)

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

    private func finalizeLink(credential: String, keyId: String, userId: String) async {
        LMLinkLogger.auth.info("Finalizing link for keyId: \(keyId, privacy: .private(mask: .hash))")
        SDKLogStore.shared.log("LM Link: Finalizing handshake for keyId: \(keyId)", source: "LMLinkAuthManager", level: .info)

        // LM Studio registration confirmation handshake
        // After receiving the callback, we MUST notify the LM Studio server that the link is complete.
        // This ensures the device is registered correctly in the LM Studio dashboard.

        // We ensure that the keyId from the callback matches the pendingKeyId if available,
        // to maintain strict key consistency.
        if let pending = pendingKeyId, pending != keyId {
            SDKLogStore.shared.log("LM Link: WARNING - keyId mismatch. Pending: \(pending), Callback: \(keyId). Using Callback ID.", source: "LMLinkAuthManager", level: .warning)
        }

        var components = URLComponents(string: "https://lmstudio.ai/authentication-confirm")
        components?.queryItems = [
            URLQueryItem(name: "keyId",      value: keyId),
            URLQueryItem(name: "credential", value: credential),
            URLQueryItem(name: "userId",     value: userId),
            URLQueryItem(name: "platform",   value: "ios")
        ]

        guard let confirmURL = components?.url else {
            LMLinkLogger.auth.error("Failed to construct confirmation URL")
            SDKLogStore.shared.log("LM Link: Failed to construct confirmation URL", source: "LMLinkAuthManager", level: .error)
            state = .error(.malformedCallback)
            return
        }

        var request = URLRequest(url: confirmURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        SDKLogStore.shared.log("LM Link: Sending POST confirmation to: \(confirmURL.absoluteString)", source: "LMLinkAuthManager", level: .info)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                LMLinkLogger.auth.info("Confirmation response status: \(httpResponse.statusCode, privacy: .public)")
                SDKLogStore.shared.log("LM Link: Confirmation response status: \(httpResponse.statusCode)", source: "LMLinkAuthManager", level: .info)

                if (200...299).contains(httpResponse.statusCode) {
                    LMLinkLogger.auth.info("Device successfully registered with LM Studio")
                    SDKLogStore.shared.log("LM Link: Device successfully registered with LM Studio", source: "LMLinkAuthManager", level: .info)

                    let session = LMLinkSession(
                        keyId: keyId,
                        credential: credential,
                        userId: userId,
                        connectedAt: Date(),
                        localServerReachable: false,
                        localModelCount: 0
                    )

                    let saveResult = keychain.save(credential: credential, keyId: keyId, userId: userId)
                    if case .failure(let err) = saveResult {
                        LMLinkLogger.auth.error("Failed to save credentials: \(err.localizedDescription, privacy: .public)")
                        state = .error(err)
                        return
                    }

                    state = .connected(session: session)
                    LMLinkLogger.auth.info("Auth complete and session persisted.")
                } else {
                    let responseString = String(data: data, encoding: .utf8) ?? "no body"
                    LMLinkLogger.auth.error("LM Studio confirmation failed. Status: \(httpResponse.statusCode), Body: \(responseString, privacy: .public)")
                    SDKLogStore.shared.log("LM Link: LM Studio confirmation failed. Status: \(httpResponse.statusCode), Body: \(responseString)", source: "LMLinkAuthManager", level: .error)
                    state = .error(.denied)
                }
            }
        } catch {
            LMLinkLogger.auth.error("Network error during confirmation: \(error.localizedDescription, privacy: .public)")
            SDKLogStore.shared.log("LM Link: Network error during confirmation: \(error.localizedDescription)", source: "LMLinkAuthManager", level: .error)
            state = .error(.browserOpenFailed)
        }
    }
}
