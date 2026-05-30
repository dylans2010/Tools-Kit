import SwiftUI

struct DeveloperSecretsManagerView: View {
    @ObservedObject var secretService = SecretService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddSecret = false
    @State private var secretKey = ""
    @State private var secretValue = ""

    var filteredSecrets: [Secret] {
        secretService.secrets.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Account Level").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Secure Secrets") {
                if filteredSecrets.isEmpty {
                    EmptyStateView(icon: "lock.rectangle", title: "No Secrets Found", message: "Store encrypted environment variables and credentials securely.")
                } else {
                    ForEach(filteredSecrets) { secret in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(secret.key).font(.subheadline.bold()).monospaced()
                                Text("Added \(secret.createdAt.formatted(date: .abbreviated, time: .omitted))").font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(secret.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Secrets Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSecret = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddSecret) {
            addSecretSheet
        }
    }

    private var addSecretSheet: some View {
        NavigationStack {
            Form {
                Section("Secret Definition") {
                    TextField("Secret Key (e.g. STRIPE_API_KEY)", text: $secretKey).monospaced()
                    SecureField("Secret Value", text: $secretValue)
                }
            }
            .navigationTitle("Add Secret")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddSecret = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Encrypt & Store") {
                        let masked = "••••" + String(secretValue.suffix(4))
                        let secret = Secret(appID: selectedAppID, key: secretKey, maskedValue: masked)
                        Task {
                            try? await secretService.saveSecret(secret)
                            await MainActor.run {
                                showingAddSecret = false
                                secretKey = ""
                                secretValue = ""
                            }
                        }
                    }
                    .disabled(secretKey.isEmpty || secretValue.isEmpty)
                }
            }
        }
    }
}
