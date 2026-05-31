import SwiftUI

struct DeveloperSecretsManagerView: View {
    @ObservedObject var secretService = SecretService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var showingAddSecret = false
    @State private var secretKey = ""
    @State private var secretValue = ""
    @State private var selectedAppID: UUID?

    var body: some View {
        List {
            Section("Security Policy") {
                HStack {
                    Image(systemName: "shield.lefthalf.filled").foregroundStyle(.blue)
                    Text("Secrets are encrypted at rest and only exposed during runtime execution environment injection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { showingAddSecret = true } label: {
                    Label("Add Secure Secret", systemImage: "lock.plus.fill").font(.subheadline.bold())
                }
            }

            Section("Application Secrets") {
                if secretService.secrets.isEmpty {
                    EmptyStateView(icon: "lock.shield", title: "No Secrets", message: "Register sensitive environment variables like API credentials or private keys.")
                } else {
                    ForEach(secretService.secrets) { secret in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(secret.key).font(.subheadline.bold()).monospaced()
                                Spacer()
                                if let app = appService.apps.first(where: { $0.id == secret.appID }) {
                                    Text(app.name).font(.system(size: 8, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.primary.opacity(0.05), in: Capsule())
                                }
                            }
                            Text("Last updated \(secret.updatedAt.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 8)).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Secrets Manager")
        .sheet(isPresented: $showingAddSecret) { addSecretSheet }
    }

    private var addSecretSheet: some View {
        NavigationStack {
            Form {
                Section("Scope") {
                    Picker("App", selection: $selectedAppID) {
                        Text("Select App").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Data") {
                    TextField("Secret Key", text: $secretKey, prompt: Text("e.g. STRIPE_API_KEY"))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    SecureField("Secret Value", text: $secretValue)
                }
            }
            .navigationTitle("New Secret")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddSecret = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSecret()
                    }
                    .disabled(secretKey.isEmpty || secretValue.isEmpty || selectedAppID == nil)
                }
            }
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
