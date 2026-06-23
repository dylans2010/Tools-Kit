import Foundation
import UIKit
import os

@MainActor
final class LMLinkAuthManager: NSObject, ObservableObject {
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
    private var pendingPublicKey: String?
    private var timeoutTask: Task<Void, Never>?

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
            SDKLogStore.shared.log("LM Link: [INIT] Starting authorization flow", source: "LMLinkAuthManager", level: .info)
            let (keyId, publicKeyBase64) = try LMLinkKeyPairService.generateKeyPair()
            pendingKeyId = keyId
            pendingPublicKey = publicKeyBase64
            SDKLogStore.shared.log("LM Link: [KEYGEN] Key pair generated. keyId: \(keyId), publicKey: \(publicKeyBase64)", source: "LMLinkAuthManager", level: .info)

            var components = URLComponents(string: "https://lmstudio.ai/authentication-request")
            components?.queryItems = [
                URLQueryItem(name: "keyId",         value: keyId),
                URLQueryItem(name: "publicKey",     value: publicKeyBase64),
                URLQueryItem(name: "returnTo",      value: "toolskit://lm-callback"),
                URLQueryItem(name: "clientKind",    value: "ios"),
                URLQueryItem(name: "clientVersion", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            ]

            guard let authURL = components?.url else {
                LMLinkLogger.auth.error("Failed to construct authentication URL")
                SDKLogStore.shared.log("LM Link: [ERROR] Failed to construct authentication URL", source: "LMLinkAuthManager", level: .error)
                state = .error(.browserOpenFailed)
                return
            }

            LMLinkLogger.auth.info("Opening external Safari. URL: \(authURL.absoluteString, privacy: .private(mask: .hash))")
            SDKLogStore.shared.log("LM Link: [REDIRECT] Opening external Safari for URL: \(authURL.absoluteString)", source: "LMLinkAuthManager", level: .info)

            // MANDATORY: Use UIApplication.shared.open to launch external Safari
            // Using withCheckedContinuation to bridge the completion-handler-based API to async/await
            let success = await withCheckedContinuation { continuation in
                UIApplication.shared.open(authURL, options: [:]) { success in
                    continuation.resume(returning: success)
                }
            }

            if success {
                LMLinkLogger.auth.info("External Safari opened successfully")
                SDKLogStore.shared.log("LM Link: [SUCCESS] External Safari opened successfully", source: "LMLinkAuthManager", level: .info)
                state = .awaitingCallback
                startTimeoutTimer()
            } else {
                state = .error(.browserOpenFailed)
                LMLinkLogger.auth.error("Failed to open external Safari")
                SDKLogStore.shared.log("LM Link: [ERROR] Failed to open external Safari", source: "LMLinkAuthManager", level: .error)
            }
        } catch {
            LMLinkLogger.auth.error("Key pair generation failed: \(error.localizedDescription, privacy: .public)")
            state = .error(.keyPairGenerationFailed)
        }
    }

    func handleCallback(url: URL) async {
        SDKLogStore.shared.log("LM Link: [RECEPTION] Deep Link Callback URL: \(url.absoluteString)", source: "LMLinkAuthManager", level: .info)
        LMLinkLogger.deeplink.info("LM Link: [RECEPTION] Handling callback URL: \(url.absoluteString, privacy: .private(mask: .hash))")

        let result = LMLinkCallbackParser.parse(url: url)

        // Handle Cold-start or unexpected state transitions
        if case .awaitingCallback = state {
            // Normal flow
        } else if case .authorizing = state {
            // Also normal if Safari opens and redirects very quickly
        } else {
            // Check if this is a valid callback for a key we generated
            if case .success(_, let keyId, _, _) = result {
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
        case .success(let credential, let keyId, let publicKey, let userId):
            SDKLogStore.shared.log("LM Link: [PARSED] keyId: \(keyId), userId: \(userId)", source: "LMLinkAuthManager", level: .info)
            await finalizeLink(credential: credential, keyId: keyId, publicKey: publicKey, userId: userId)

        case .cancelled:
            SDKLogStore.shared.log("LM Link: [CANCELLED] User cancelled authentication", source: "LMLinkAuthManager", level: .info)
            state = .error(.cancelled)
        case .denied:
            SDKLogStore.shared.log("LM Link: [DENIED] LM Studio denied access", source: "LMLinkAuthManager", level: .info)
            state = .error(.denied)
        case .error(let reason):
            LMLinkLogger.deeplink.error("Callback error param: \(reason, privacy: .public)")
            SDKLogStore.shared.log("LM Link: [ERROR] Callback returned error: \(reason)", source: "LMLinkAuthManager", level: .error)
            state = .error(.malformedCallback)
        case .malformed:
            SDKLogStore.shared.log("LM Link: [MALFORMED] Callback URL was malformed", source: "LMLinkAuthManager", level: .error)
            state = .error(.malformedCallback)
        }
    }

    func restoreSession() async {
        switch keychain.load() {
        case .success(let (credential, keyId, publicKey, userId)):
            // Skip ping during restore on iOS.
            let isReachable = false
            let modelCount = 0

            let session = LMLinkSession(
                keyId: keyId,
                publicKey: publicKey,
                credential: credential,
                userId: userId,
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
                    self?.pendingPublicKey = nil
                    LMLinkLogger.auth.error("Auth timed out after 120 seconds")
                }
            }
        }
    }

    private func cancelTimeoutTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    private func finalizeLink(credential: String, keyId: String, publicKey: String, userId: String) async {
        LMLinkLogger.auth.info("Finalizing link for keyId: \(keyId, privacy: .private(mask: .hash))")
        SDKLogStore.shared.log("LM Link: [CONFIRMATION] Starting registration for keyId: \(keyId), publicKey length: \(publicKey.count)", source: "LMLinkAuthManager", level: .info)

        // Ensure consistency between generated and received keys
        if let pending = pendingKeyId, pending != keyId {
            SDKLogStore.shared.log("LM Link: [WARNING] keyId mismatch. Pending: \(pending), Callback: \(keyId). Using Callback ID.", source: "LMLinkAuthManager", level: .warning)
        }

        let finalPublicKey = publicKey.isEmpty ? (pendingPublicKey ?? "") : publicKey
        if finalPublicKey.isEmpty {
            LMLinkLogger.auth.error("No public key available for session")
            SDKLogStore.shared.log("LM Link: [FAILURE] No public key available for session. pendingPublicKey exists: \(pendingPublicKey != nil)", source: "LMLinkAuthManager", level: .error)
            state = .error(.malformedCallback)
            return
        }

        guard let confirmURL = URL(string: "https://lmstudio.ai/authentication-confirm") else {
            LMLinkLogger.auth.error("Failed to construct confirmation URL")
            SDKLogStore.shared.log("LM Link: [ERROR] Failed to construct confirmation URL", source: "LMLinkAuthManager", level: .error)
            state = .error(.malformedCallback)
            return
        }

        var request = URLRequest(url: confirmURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "keyId": keyId,
            "publicKey": finalPublicKey,
            "credential": credential,
            "userId": userId,
            "platform": "ios"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            LMLinkLogger.auth.error("Failed to encode confirmation body")
            state = .error(.malformedCallback)
            return
        }

        SDKLogStore.shared.log("LM Link: [CONFIRMATION] Sending POST to: \(confirmURL.absoluteString) with keyId: \(keyId)", source: "LMLinkAuthManager", level: .info)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                LMLinkLogger.auth.info("Confirmation response status: \(httpResponse.statusCode, privacy: .public)")
                let responseBody = String(data: data, encoding: .utf8) ?? "no body"
                SDKLogStore.shared.log("LM Link: [CONFIRMATION] Response status: \(httpResponse.statusCode), body: \(responseBody)", source: "LMLinkAuthManager", level: .info)

                if (200...299).contains(httpResponse.statusCode) {
                    LMLinkLogger.auth.info("Device successfully registered with LM Studio")
                    SDKLogStore.shared.log("LM Link: [SUCCESS] Device successfully registered with LM Studio. Device should now appear in LM Link Devices list.", source: "LMLinkAuthManager", level: .info)

                    let session = LMLinkSession(
                        keyId: keyId,
                        publicKey: finalPublicKey,
                        credential: credential,
                        userId: userId,
                        connectedAt: Date(),
                        localServerReachable: false,
                        localModelCount: 0
                    )

                    let saveResult = keychain.save(credential: credential, keyId: keyId, publicKey: finalPublicKey, userId: userId)
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
                    SDKLogStore.shared.log("LM Link: [FAILURE] LM Studio confirmation failed. Status: \(httpResponse.statusCode), Body: \(responseString)", source: "LMLinkAuthManager", level: .error)
                    state = .error(.denied)
                }
            }
        } catch {
            LMLinkLogger.auth.error("Network error during confirmation: \(error.localizedDescription, privacy: .public)")
            SDKLogStore.shared.log("LM Link: [FAILURE] Network error during confirmation: \(error.localizedDescription)", source: "LMLinkAuthManager", level: .error)
            state = .error(.browserOpenFailed)
        }
    }
}
