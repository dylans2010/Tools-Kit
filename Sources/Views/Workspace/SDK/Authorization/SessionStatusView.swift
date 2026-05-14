import SwiftUI

struct SessionStatusView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared

    let session: AuthSession
    let onInspectScopes: () -> Void

    var body: some View {
        List {
            Section("Session") {
                LabeledContent("State", value: authorizationManager.authState.rawValue)
                LabeledContent("Session ID", value: session.sessionId)
                LabeledContent("Developer ID", value: session.developerId ?? "n/a")
                LabeledContent("Issued", value: session.issuedAt.formatted(date: .abbreviated, time: .standard))
                LabeledContent("Expires", value: session.expiresAt.formatted(date: .abbreviated, time: .standard))
                LabeledContent("Valid", value: session.isExpired ? "No" : "Yes")
                LabeledContent("Refresh Token", value: session.refreshToken == nil ? "Not Set" : "Set")
                LabeledContent("Scope Count", value: "\(session.scopes.count)")
            }

            Section("Actions") {
                Button("Inspect Scopes") { onInspectScopes() }
                Button("Expire Session") { authorizationManager.expireSession() }
                Button("Revoke Session", role: .destructive) { authorizationManager.revokeSession() }
                Button("Sign Out") { authorizationManager.signOut() }
            }
        }
        .listStyle(.insetGrouped)
    }
}
