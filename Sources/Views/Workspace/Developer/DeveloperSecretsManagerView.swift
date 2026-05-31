import SwiftUI

struct DeveloperSecretsManagerView: View {
    @ObservedObject var secretService = SecretService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var showingAddSecret = false
    @State private var secretKey = ""
    @State private var secretValue = ""
    @State private var selectedAppID: UUID?

    private var apps: [DeveloperApp] { appService.apps }
    private var secrets: [Secret] { secretService.secrets }

    var body: some View {
        List {
            securityPolicySection
            addSecretButtonSection
            applicationSecretsSection
        }
        .navigationTitle("Secrets Manager")
        .sheet(isPresented: $showingAddSecret) { addSecretSheet }
    }

    private var securityPolicySection: some View {
        Section("Security Policy") {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(.blue)
                Text("Secrets are encrypted at rest and only exposed during runtime execution environment injection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var addSecretButtonSection: some View {
        Section {
            Button { showingAddSecret = true } label: {
                Label("Add Secure Secret", systemImage: "lock.plus.fill")
                    .font(.subheadline.bold())
            }
        }
    }

    @ViewBuilder
    private var applicationSecretsSection: some View {
        Section("Application Secrets") {
            if secrets.isEmpty {
                secretsEmptyState
            } else {
                secretRows
            }
        }
    }

    private var secretsEmptyState: some View {
        EmptyStateView(
            icon: "lock.shield",
            title: "No Secrets",
            message: "Register sensitive environment variables like API credentials or private keys."
        )
    }

    private var secretRows: some View {
        ForEach(secrets) { secret in
            secretRow(secret)
        }
    }

    private func secretRow(_ secret: Secret) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            secretHeader(secret)
            secretUpdatedAtText(secret)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func secretHeader(_ secret: Secret) -> some View {
        HStack {
            Text(secret.key)
                .font(.subheadline.bold())
                .monospaced()
            Spacer()
            if let app = app(for: secret) {
                appBadge(app)
            }
        }
    }

    private func secretUpdatedAtText(_ secret: Secret) -> some View {
        Text("Last updated \(secret.updatedAt.formatted(date: .abbreviated, time: .shortened))")
            .font(.system(size: 8))
            .foregroundStyle(.tertiary)
    }

    private func appBadge(_ app: DeveloperApp) -> some View {
        Text(app.name)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.05), in: Capsule())
    }

    private var addSecretSheet: some View {
        NavigationStack {
            Form {
                appScopeSection
                secretDataSection
            }
            .navigationTitle("New Secret")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { cancelButton }
                ToolbarItem(placement: .confirmationAction) { saveButton }
            }
        }
    }

    private var appScopeSection: some View {
        Section("Scope") {
            Picker("App", selection: $selectedAppID) {
                Text("Select App").tag(Optional<UUID>.none)
                ForEach(apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
        }
    }

    private var secretDataSection: some View {
        Section("Data") {
            TextField("Secret Key", text: $secretKey, prompt: Text("e.g. STRIPE_API_KEY"))
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
            SecureField("Secret Value", text: $secretValue)
        }
    }

    private var cancelButton: some View {
        Button("Cancel") { showingAddSecret = false }
    }

    private var saveButton: some View {
        Button("Save") {
            saveSecret()
        }
        .disabled(secretKey.isEmpty || secretValue.isEmpty || selectedAppID == nil)
    }

    private func app(for secret: Secret) -> DeveloperApp? {
        apps.first { app in
            app.id == secret.appID
        }
    }

    private func saveSecret() {
        guard let appID = selectedAppID else { return }
        let secret = Secret(appID: appID, key: secretKey, maskedValue: String(repeating: "*", count: 8))
        Task {
            try? await secretService.saveSecret(secret)
            await MainActor.run {
                showingAddSecret = false
                secretKey = ""
                secretValue = ""
            }
        }
    }
}
