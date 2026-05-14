import SwiftUI
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authorizationManager = AuthorizationManager.shared

    @State private var developerId = "workspace-dev"
    @State private var selectedScopes: Set<SDKScope> = [.workspaceRead, .sdkProjectCreate]
    @State private var durationHours: Double = 1
    @State private var refreshToken = ""
    @State private var showingScopeSelection = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Developer Identity")
                        .font(.headline)
                    Text("Your Developer ID is used to sign all SDK operations and bound to your local device fingerprint.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                TextField("Developer ID", text: $developerId)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("Refresh Token (optional)", text: $refreshToken)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Identity")
            }

            Section {
                Button {
                    showingScopeSelection = true
                } label: {
                    HStack {
                        Label("\(selectedScopes.count) Scopes Selected", systemImage: "shield.lefthalf.filled")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper("Session Duration: \(Int(durationHours))h", value: $durationHours, in: 1...24)
            } header: {
                Text("Security Scopes")
            }

            Section {
                Button {
                    performAuthentication()
                } label: {
                    Text("Create Developer ID & Authenticate")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(developerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("SDK Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingScopeSelection) {
            NavigationStack {
                ScopeSelectionSheet(selectedScopes: $selectedScopes)
            }
        }
    }

    private func performAuthentication() {
        let trimmedDevId = developerId.trimmingCharacters(in: .whitespacesAndNewlines)
        let hashedId = hashDeveloperId(trimmedDevId)

        try? SDKStorageManager.shared.setSecureValue(key: "last_developer_id_hash", value: hashedId)

        authorizationManager.beginAuthentication()
        _ = authorizationManager.authenticate(
            developerId: hashedId,
            scopes: selectedScopes.map(\.rawValue),
            sessionDuration: durationHours * 3600,
            refreshToken: refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : refreshToken
        )
        dismiss()
    }

    private func hashDeveloperId(_ id: String) -> String {
        let inputData = Data(id.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

}

struct ScopeSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedScopes: Set<SDKScope>

    var body: some View {
        List {
            Section {
                Text("Select the security scopes required for your development session. These will be encoded into your deterministic token.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(SDKScope.allCases) { scope in
                Toggle(isOn: Binding(
                    get: { selectedScopes.contains(scope) },
                    set: { if $0 { selectedScopes.insert(scope) } else { selectedScopes.remove(scope) } }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scope.displayName)
                            .font(.subheadline.bold())
                        Text(scope.rawValue)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Select Scopes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Clear All") { selectedScopes.removeAll() }
            }
        }
    }
}
