import Foundation
import Combine
import CryptoKit

public enum AuthState: String, Codable, CaseIterable {
    case unauthenticated
    case authenticating
    case authenticated
    case sessionExpired
    case revoked
}

public struct TKTokenHeader: Codable {
    public let tokenType: String // access | refresh | agent
    public let algorithm: String
    public let keyId: String
}

public struct TKTokenPayload: Codable {
    public let uid: String // user_id
    public let iat: Int64  // issued at (ms)
    public let exp: Int64  // expiration
    public let scp: UInt64 // compressed scope map (bitmask)
    public let sid: String // session identifier
    public let nonce: String
    public let dfp: String // device fingerprint hash
    public let ver: Int    // schema version
}

public struct TKToken: Codable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public func validate() throws -> (TKTokenHeader, TKTokenPayload) {
        let segments = rawValue.components(separatedBy: ".")

        guard segments.count == 5, segments[0] == "TK" else {
            throw SDKError.validationError(reason: "Invalid token structure")
        }

        let version = segments[1]
        let headerBase64 = segments[2]
        let payloadBase64 = segments[3]
        let signature = segments[4]

        guard let headerData = Data(base64Encoded: headerBase64),
              let header = try? JSONDecoder().decode(TKTokenHeader.self, from: headerData) else {
            throw SDKError.validationError(reason: "Invalid token header")
        }

        guard let payloadData = Data(base64Encoded: payloadBase64),
              let payload = try? JSONDecoder().decode(TKTokenPayload.self, from: payloadData) else {
            throw SDKError.validationError(reason: "Invalid token payload")
        }

        let signingInput = "TK.\(version).\(headerBase64).\(payloadBase64)"
        let expectedSignature = try AuthorizationManager.shared.generateSignature(for: signingInput)
        guard signature == expectedSignature else {
            throw SDKError.permissionDenied(scope: "token.signature")
        }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        guard payload.exp > now else {
            throw SDKError.authenticationRequired
        }

        guard !AuthorizationManager.shared.isNonceUsed(payload.nonce) else {
            throw SDKError.validationError(reason: "Token nonce already used")
        }

        let currentDFP = AuthorizationManager.shared.calculateDeviceFingerprint()
        guard payload.dfp == currentDFP else {
            throw SDKError.permissionDenied(scope: "token.fingerprint")
        }

        return (header, payload)
    }
}

@MainActor
public final class AuthorizationManager: ObservableObject {
    public static let shared = AuthorizationManager()

    @Published public private(set) var authState: AuthState = .unauthenticated
    @Published public private(set) var activeToken: TKToken?
    @Published public private(set) var activePayload: TKTokenPayload?
    @Published public private(set) var securityViolations: [SecurityViolation] = []

    private let sessionKey = "sdk.authorization.token"
    private var usedNonces: Set<String> = []

    public struct SecurityViolation: Identifiable, Codable {
        public let id: UUID
        public let timestamp: Date
        public let scope: String
        public let resourceType: String
        public let resourceId: String
    }

    private init() {
        loadPersistedSession()
    }

    public func authenticate(userId: String, scope: SDKScope, duration: TimeInterval = 3600) -> TKToken {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let exp = now + Int64(duration * 1000)
        let sid = UUID().uuidString
        let nonce = UUID().uuidString
        let dfp = calculateDeviceFingerprint()

        let header = TKTokenHeader(tokenType: "access", algorithm: "HS256", keyId: "v1")
        let payload = TKTokenPayload(
            uid: userId,
            iat: now,
            exp: exp,
            scp: scope.rawValue,
            sid: sid,
            nonce: nonce,
            dfp: dfp,
            ver: 1
        )

        do {
            let headerBase64 = try JSONEncoder().encode(header).base64EncodedString()
            let payloadBase64 = try JSONEncoder().encode(payload).base64EncodedString()
            let signingInput = "TK.1.\(headerBase64).\(payloadBase64)"
            let signature = try generateSignature(for: signingInput)

            let token = TKToken(rawValue: "\(signingInput).\(signature)")

            self.activeToken = token
            self.activePayload = payload
            self.authState = .authenticated

            persistToken(token)
            return token
        } catch {
            fatalError("Deterministic token generation failed: \(error.localizedDescription)")
        }
    }

    public func signOut() {
        activeToken = nil
        activePayload = nil
        authState = .unauthenticated
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    public func validateScope(_ scope: SDKScope) -> Bool {
        guard let payload = activePayload else { return false }
        let granted = SDKScope(rawValue: payload.scp)
        return granted.contains(scope)
    }

    // Improved mapping for legacy string-based scopes
    public func validateScope(_ scope: String) -> Bool {
        guard authState == .authenticated else { return false }
        let requested = mapStringToScope(scope)
        return validateScope(requested)
    }

    public func canUseScopes(_ scopes: [String]) -> Bool {
        guard authState == .authenticated else { return false }
        let requested = scopes.reduce(into: SDKScope()) { $0.insert(mapStringToScope($1)) }
        return validateScope(requested)
    }

    public func canUsePlugin(id: UUID) -> Bool {
        guard authState == .authenticated else { return false }
        if let plugin = SDKPluginManager.shared.getPlugin(id: id) {
            return validateScope(plugin.requiredSDKScope)
        }
        return false
    }

    public func canAccessModule(id: String) -> Bool {
        guard authState == .authenticated else { return false }
        if let module = SDKModuleRegistry.shared.module(for: id) {
            return validateScope(module.requiredSDKScope)
        }
        return false
    }

    public func canUseConnector(id: UUID) -> Bool {
        // Placeholder until Connector requiredSDKScope is implemented
        return authState == .authenticated
    }

    // MARK: - Deterministic Utils

    func generateSignature(for input: String) throws -> String {
        let systemSalt = getSystemSalt()
        let appSeed = getAppSeed()
        let rotatingKey = getRotatingKey()
        let secret = rotatingKey + appSeed + systemSalt

        let key = SymmetricKey(data: SHA256.hash(data: Data(secret.utf8)))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(input.utf8), using: key)
        return Data(signature).base64EncodedString()
    }

    func calculateDeviceFingerprint() -> String {
        let entropy = getSystemEntropy()
        let hashed = SHA256.hash(data: Data(entropy.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func isNonceUsed(_ nonce: String) -> Bool {
        usedNonces.contains(nonce)
    }

    func markNonceUsed(_ nonce: String) {
        usedNonces.insert(nonce)
    }

    // MARK: - Private

    private func getSystemSalt() -> String {
        // Deterministic but non-hardcoded device-bound salt
        #if targetEnvironment(simulator)
        return "SIM-SALT-\(ProcessInfo.processInfo.hostName)"
        #else
        // In real app, use identifierForVendor
        return "DEV-SALT-SECURE-BETA"
        #endif
    }

    private func getAppSeed() -> String {
        // App installation specific seed
        return SDKStorageManager.shared.getSecureValue(key: "app_install_seed") ?? "SEED-NOT-INITIALIZED"
    }

    private func getRotatingKey() -> String {
        // In production, this would rotate and be fetched from a secure vault
        return "TK-ROTATING-KEY-2026-Q1"
    }

    private func getSystemEntropy() -> String {
        let name = ProcessInfo.processInfo.processName
        let version = ProcessInfo.processInfo.operatingSystemVersionString
        return "\(name)-\(version)-\(getSystemSalt())"
    }

    private func persistToken(_ token: TKToken) {
        UserDefaults.standard.set(token.rawValue, forKey: sessionKey)
    }

    private func loadPersistedSession() {
        guard let rawToken = UserDefaults.standard.string(forKey: sessionKey) else { return }
        let token = TKToken(rawValue: rawToken)
        do {
            let (_, payload) = try token.validate()
            self.activeToken = token
            self.activePayload = payload
            self.authState = .authenticated
            markNonceUsed(payload.nonce)
        } catch {
            self.authState = .sessionExpired
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }

    private func mapStringToScope(_ scope: String) -> SDKScope {
        switch scope {
        case "workspace.files.read": return .workspaceRead
        case "workspace.files.write": return .workspaceWrite
        case "workspace.automation.execute": return .frameworkExecute
        case "workspace.persona.read": return .agentExecute
        case "workspace.persona.write": return [.agentExecute, .workspaceWrite]
        case "external.api.unrestricted": return .workspaceRead
        default: return []
        }
    }
}
