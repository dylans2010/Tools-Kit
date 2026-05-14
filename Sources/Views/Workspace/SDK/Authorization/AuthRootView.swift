import SwiftUI
import CryptoKit

// MARK: - ========================
// MARK:   DETERMINISTIC IDENTITY CORE
// MARK: - ========================

// MARK: - Token Format: TK.<version>.<header>.<payload>.<signature>

enum TokenVersion: String, Codable {
    case v1 = "1"
}

struct TokenHeader: Codable {
    let tokenType: String
    let algorithm: String
    let keyId: String
}

struct TokenPayload: Codable {
    let devId: String
    let iat: TimeInterval
    let exp: TimeInterval
    let scp: String
    let sid: String
    let nonce: String
    let dfp: String
    let ver: String
}

struct DeterministicToken: Codable {
    let version: TokenVersion
    let header: TokenHeader
    let payload: TokenPayload
    let signature: String

    var serialized: String {
        "TK.\(version.rawValue).\(encodeComponent(header)).\(encodeComponent(payload)).\(signature)"
    }

    var isExpired: Bool {
        Date().timeIntervalSince1970 >= payload.exp
    }

    private func encodeComponent<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return data.base64EncodedString()
    }
}

// MARK: - Deterministic Token Engine (7-Step Validation Pipeline)

@MainActor
final class DeterministicTokenEngine: ObservableObject {
    static let shared = DeterministicTokenEngine()

    @Published private(set) var currentToken: DeterministicToken?
    @Published private(set) var validationStatus: TokenValidationResult = .none
    @Published private(set) var sessionTimeline: [TokenSessionEvent] = []

    private var usedNonces: Set<String> = []
    private var rotatingKeyIndex: Int = 0
    private let keySeedBase = "TK-DETERMINISTIC-SEED"

    struct TokenSessionEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let event: String
        let detail: String
    }

    enum TokenValidationResult: Equatable {
        case none
        case valid
        case invalid(reason: String)
    }

    private init() {}

    // MARK: - Token Generation (device-bound, deterministic)

    func generateToken(
        developerId: String,
        scopes: Set<SDKScope>,
        sessionDuration: TimeInterval = 3600,
        deviceFingerprint: String
    ) -> DeterministicToken {
        let now = Date()
        let nonce = UUID().uuidString
        let sid = UUID().uuidString
        let keyId = "key-\(rotatingKeyIndex)"

        let header = TokenHeader(tokenType: "deterministic", algorithm: "HMAC-SHA256", keyId: keyId)
        let payload = TokenPayload(
            devId: developerId,
            iat: now.timeIntervalSince1970,
            exp: now.addingTimeInterval(max(1, sessionDuration)).timeIntervalSince1970,
            scp: SDKScope.encode(scopes),
            sid: sid,
            nonce: nonce,
            dfp: deviceFingerprint,
            ver: TokenVersion.v1.rawValue
        )

        let signature = computeSignature(header: header, payload: payload, deviceFingerprint: deviceFingerprint)
        let token = DeterministicToken(version: .v1, header: header, payload: payload, signature: signature)

        usedNonces.insert(nonce)
        currentToken = token
        rotatingKeyIndex += 1

        logEvent("Token Generated", detail: "devId=\(developerId) scopes=\(scopes.count) expires=\(Int(sessionDuration))s")
        return token
    }

    // MARK: - 7-Step Validation Pipeline

    func validate(token: DeterministicToken, expectedFingerprint: String) -> TokenValidationResult {
        // 1. Structural validation
        guard !token.signature.isEmpty else { return fail("Missing signature") }
        // 2. Schema validation
        guard !token.payload.devId.isEmpty, !token.payload.sid.isEmpty,
              !token.payload.nonce.isEmpty, !token.payload.dfp.isEmpty else {
            return fail("Schema validation failed")
        }
        // 3. Signature verification
        let expectedSig = computeSignature(header: token.header, payload: token.payload, deviceFingerprint: expectedFingerprint)
        guard token.signature == expectedSig else { return fail("Signature mismatch") }
        // 4. Expiration check
        guard !token.isExpired else { return fail("Token expired") }
        // 5. Nonce replay prevention
        if usedNonces.contains(token.payload.nonce) && currentToken?.payload.nonce != token.payload.nonce {
            return fail("Nonce replay detected")
        }
        // 6. Device fingerprint match
        guard token.payload.dfp == expectedFingerprint else { return fail("Device fingerprint mismatch") }
        // 7. Scope integrity validation
        let decodedScopes = SDKScope.decode(token.payload.scp)
        guard !decodedScopes.isEmpty else { return fail("No valid scopes") }

        // 8. Contextual Integrity Validation
        guard validateContext(token: token, expectedFingerprint: expectedFingerprint) else {
            return fail("Contextual integrity validation failed")
        }

        validationStatus = .valid
        logEvent("Validation Passed", detail: "All 8 checks passed")
        return .valid
    }

    private func validateContext(token: DeterministicToken, expectedFingerprint: String) -> Bool {
        // In a real implementation, this would check against active SDK project state
        // For now, we ensure the device fingerprint and session ID follow expected patterns
        return token.payload.dfp == expectedFingerprint && !token.payload.sid.isEmpty
    }

    // MARK: - Enforcement (No token = no access, Invalid = rejection, Scope mismatch = blocked)

    func revokeToken() {
        currentToken = nil
        validationStatus = .none
        logEvent("Token Revoked", detail: "Current token invalidated")
    }

    func hasScope(_ scope: SDKScope) -> Bool {
        guard let token = currentToken, !token.isExpired else { return false }
        return SDKScope.decode(token.payload.scp).contains(scope)
    }

    func requireScope(_ scope: SDKScope) -> Bool {
        guard hasScope(scope) else {
            logEvent("Scope Denied", detail: scope.rawValue)
            return false
        }
        return true
    }

    // MARK: - Private

    private func fail(_ reason: String) -> TokenValidationResult {
        let result = TokenValidationResult.invalid(reason: reason)
        validationStatus = result
        logEvent("Validation Failed", detail: reason)
        return result
    }

    private func computeSignature(header: TokenHeader, payload: TokenPayload, deviceFingerprint: String) -> String {
        let material = "\(keySeedBase)-\(deviceFingerprint)-\(payload.sid)-\(header.keyId)"
        let key = SymmetricKey(data: Data(material.utf8))
        let headerData = (try? JSONEncoder().encode(header)) ?? Data()
        let payloadData = (try? JSONEncoder().encode(payload)) ?? Data()
        var message = Data()
        message.append(headerData)
        message.append(payloadData)
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return Data(mac).base64EncodedString()
    }

    private func logEvent(_ event: String, detail: String) {
        sessionTimeline.append(TokenSessionEvent(timestamp: Date(), event: event, detail: detail))
    }
}

// MARK: - Shared Result Type

enum UIAgentToolResult {
    case success(String)
    case failure(String)
    case dryRun(String)
}

// MARK: - ========================
// MARK:   AUTH ROOT VIEW
// MARK: - ========================

struct AuthRootView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var showingSignInSheet = false
    @State private var showingScopeInspector = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusHeader

                    switch authorizationManager.authState {
                    case .unauthenticated, .revoked, .sessionExpired:
                        unauthenticatedView
                    case .authenticating:
                        authenticatingView
                    case .authenticated:
                        authenticatedView
                    }
                }
                .padding()
            }
            .navigationTitle("SDK Authorization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if authorizationManager.authState == .authenticated {
                        Button("Sign Out", role: .destructive) {
                            authorizationManager.signOut()
                        }
                    } else {
                        Button("Sign In") {
                            showingSignInSheet = true
                        }
                    }
                }
            }
        }
        .aiAnimationLoading(authorizationManager.authState == .authenticating)
        .sheet(isPresented: $showingSignInSheet) {
            NavigationStack { SignInView() }
        }
        .fullScreenCover(isPresented: $showingScopeInspector) {
            NavigationStack {
                ScopeInspectorView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingScopeInspector = false }
                        }
                    }
            }
        }
        .onAppear {
            showingSignInSheet = authorizationManager.authState == .unauthenticated || authorizationManager.authState == .sessionExpired || authorizationManager.authState == .revoked
        }
    }

    private var securityAuditSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Security Audit", systemImage: "shield.text.check")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(DeterministicTokenEngine.shared.sessionTimeline.suffix(5).reversed()) { event in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(event.event).font(.caption.bold())
                                    Spacer()
                                    Text(event.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                                }
                                Text(event.detail).font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(6)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: authorizationManager.authState == .authenticated ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(authorizationManager.authState == .authenticated ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("SDK Authorization Center")
                    .font(.headline)
                Text("Live state, scope controls, and session lifecycle management.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var authenticatedView: some View {
        VStack(spacing: 16) {
            if let session = authorizationManager.authSession {
                SessionStatusView(session: session) {
                    showingScopeInspector = true
                }
                .frame(minHeight: 400)
            }

            securityAuditSection

            NavigationLink(destination: AccessControlOverviewView()) {
                Label("Access Control Overview", systemImage: "checklist.checked")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var authenticatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Verifying Developer Identity...")
                .font(.headline)
            Text("Generating deterministic tokens and validating hardware fingerprint.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }

    private var unauthenticatedView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text(authorizationManager.authState == .revoked ? "Access Revoked" : (authorizationManager.authState == .sessionExpired ? "Session Expired" : "Authentication Required"))
                    .font(.title2.bold())

                Text("To access the Workspace SDK and management systems, you must create or sign in with a valid Developer ID.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 40)

            Button {
                showingSignInSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.key.fill")
                    Text("Sign In with Developer ID")
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)

            NavigationLink(destination: AccessControlOverviewView()) {
                Text("View Public Access Policies")
                    .font(.caption)
            }
        }
    }
}
