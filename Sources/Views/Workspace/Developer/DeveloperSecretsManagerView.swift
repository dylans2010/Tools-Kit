import SwiftUI

struct DeveloperSecretsManagerView: View {
    @ObservedObject var secretService = SecretService.shared
    @State private var showingAddSecret = false
    @State private var selectedEnvironment: KeyEnvironment = .live
    @State private var revealedSecrets: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                secretsSecurityHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Secrets").font(.headline)
                        Spacer()
                        Button { showingAddSecret = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    Picker("Environment", selection: $selectedEnvironment) {
                        ForEach(KeyEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.segmented)

                    if secretService.secrets.isEmpty {
                        EmptyStateView(icon: "lock.rectangle", title: "No Secrets", message: "Securely store environment variables and sensitive credentials.")
                    } else {
                        ForEach(secretService.secrets.filter { $0.environment == selectedEnvironment }) { secret in
                            secretCard(secret)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Secrets Manager")
        .sheet(isPresented: $showingAddSecret) {
            AddSecretSheet(environment: selectedEnvironment)
        }
    }

    private var secretsSecurityHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vault Status").font(.headline)
                    Text("Encrypted at rest (AES-GCM)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lock.shield.fill").foregroundStyle(.blue).font(.title2)
            }

            Text("Secrets are encrypted and never stored in plain text. Access is logged for security audits.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private func secretCard(_ secret: Secret) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(secret.key).font(.subheadline.monospaced()).bold()
                Spacer()
                Button {
                    if revealedSecrets.contains(secret.id) {
                        revealedSecrets.remove(secret.id)
                    } else {
                        revealedSecrets.insert(secret.id)
                    }
                } label: {
                    Image(systemName: revealedSecrets.contains(secret.id) ? "eye.slash" : "eye")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Value").font(.caption2.bold()).foregroundStyle(.secondary)
                if revealedSecrets.contains(secret.id) {
                    Text(secret.value).font(.subheadline.monospaced())
                } else {
                    Text("••••••••••••••••").font(.subheadline.monospaced()).foregroundStyle(.tertiary)
                }
            }

            HStack {
                Text("Created \(secret.createdAt.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Button(role: .destructive) {
                    secretService.deleteSecret(id: secret.id)
                } label: {
                    Image(systemName: "trash").font(.caption)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

struct AddSecretSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var secretService = SecretService.shared
    let environment: KeyEnvironment

    @State private var key = ""
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Secret") {
                    TextField("Key (e.g. STRIPE_API_KEY)", text: $key)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    VStack(alignment: .leading) {
                        Text("Value").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $value).frame(height: 100).font(.system(.subheadline, design: .monospaced))
                    }
                }

                Section {
                    Text("This secret will be stored in the \(environment.rawValue) vault.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Secret")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newSecret = Secret(id: UUID(), key: key, value: value, environment: environment, createdAt: Date())
                        secretService.addSecret(newSecret)
                        dismiss()
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
        }
    }
}
