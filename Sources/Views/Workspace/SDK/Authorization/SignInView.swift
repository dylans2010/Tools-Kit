import SwiftUI
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authorizationManager = AuthorizationManager.shared

    @State private var userId = "workspace-user"
    @State private var scopesText = "workspace.files.read,external.api.unrestricted"
    @State private var durationHours: Double = 1
    @State private var refreshToken = ""

    var body: some View {
        Form {
            Section("Identity") {
                TextField("User ID", text: $userId)
                TextField("Refresh Token (optional)", text: $refreshToken)
            }

            Section("Scopes") {
                TextField("Comma-separated scopes", text: $scopesText, axis: .vertical)
                    .lineLimit(2...5)
                Stepper("Session Hours: \(Int(durationHours))", value: $durationHours, in: 1...24)
            }

            Section {
                Button("Authenticate") {
                    authorizationManager.beginAuthentication()

                    let rawId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let hashedId: String?
                    if rawId.isEmpty {
                        hashedId = nil
                    } else {
                        let data = Data(rawId.utf8)
                        let hash = SHA256.hash(data: data)
                        hashedId = hash.compactMap { String(format: "%02x", $0) }.joined()
                    }

                    _ = authorizationManager.authenticate(
                        userId: hashedId,
                        scopes: parseScopes(scopesText),
                        sessionDuration: durationHours * 3600,
                        refreshToken: refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : refreshToken
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func parseScopes(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
