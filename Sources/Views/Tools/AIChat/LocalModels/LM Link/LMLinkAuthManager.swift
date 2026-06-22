import Foundation
import UIKit

@MainActor
final class LMLinkAuthManager: ObservableObject {
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

    private init() {}

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

            LMLinkLogger.auth.info("Opening auth URL for keyId: \(keyId, privacy: .private(mask: .hash))")

            let opened = await UIApplication.shared.open(authURL)
            if opened {
                state = .awaitingCallback
                startTimeoutTimer()
            } else {
                state = .error(.browserOpenFailed)
                LMLinkLogger.auth.error("Failed to open auth URL — browser returned false")
            }
        } catch {
            LMLinkLogger.auth.error("Key pair generation failed: \(error.localizedDescription, privacy: .public)")
            state = .error(.keyPairGenerationFailed)
        }
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
            let ping = await validator.ping()

            let isReachable: Bool
            let modelCount: Int

            switch ping {
            case .reachable(let count):
                isReachable = true
                modelCount = count
            case .unreachable:
                isReachable = false
                modelCount = 0
            }

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
            let ping = await validator.ping()
            let isReachable: Bool
            let modelCount: Int

            switch ping {
            case .reachable(let count):
                isReachable = true
                modelCount = count
            case .unreachable:
                isReachable = false
                modelCount = 0
            }

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
