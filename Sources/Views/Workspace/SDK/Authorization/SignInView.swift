import SwiftUI
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authorizationManager = AuthorizationManager.shared

    @State private var userId = "workspace-user"
    @State private var scopesText = "workspace.read,workspace.write,sdk.project.create,sdk.manage.libraries,sdk.manage.frameworks,sdk.manage.packages,framework.execute,library.invoke,agent.execute,agent.takeover"
    @State private var durationHours: Double = 1
    @State private var refreshToken = ""
    @State private var tokenString = ""
    @State private var useTokenOnly = false

    var body: some View {
        Form {
            Section("Authentication Mode") {
                Toggle("Use Token-Only Authentication", isOn: $useTokenOnly)
            }

            if useTokenOnly {
                Section("Token Authentication") {
                    TextField("Enter Identity Token", text: $tokenString, axis: .vertical)
                        .lineLimit(3...10)
                        .font(.caption.monospaced())

                    TextField("Verify Scopes (optional)", text: $scopesText, axis: .vertical)
                        .lineLimit(2...4)

                    Button("Authenticate with Token") {
                        if authorizationManager.authenticateWithToken(tokenString, scopes: parseScopes(scopesText)) {
                            dismiss()
                        }
                    }
                    .disabled(tokenString.isEmpty)
                }
            } else {
                Section("Developer Identity") {
                    TextField("User ID", text: $userId)
                    TextField("Refresh Token (optional)", text: $refreshToken)
                }

                Section("Scopes") {
                    TextField("Comma-separated scopes", text: $scopesText, axis: .vertical)
                        .lineLimit(2...5)
                    Stepper("Session Hours: \(Int(durationHours))", value: $durationHours, in: 1...24)
                }

                Section {
                    Button("Generate Token & Authenticate") {
                        let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalUserId: String? = trimmedUserId.isEmpty ? nil : hashUserId(trimmedUserId)

                        if let finalUserId {
                            try? SDKStorageManager.shared.setSecureValue(key: "last_user_id_hash", value: finalUserId)
                        }

                        authorizationManager.beginAuthentication()
                        _ = authorizationManager.authenticate(
                            userId: finalUserId,
                            scopes: parseScopes(scopesText),
                            sessionDuration: durationHours * 3600,
                            refreshToken: refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : refreshToken
                        )
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func hashUserId(_ id: String) -> String {
        let inputData = Data(id.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func parseScopes(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
