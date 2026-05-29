import SwiftUI

struct AuthServiceManagerView: View {
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var webhookService = WebhookService.shared
    @State private var showingAddKey = false
    @State private var newKeyName = ""
    @State private var selectedKeyType: APIKeyType = .developerAPI
    @State private var selectedEnvironment: KeyEnvironment = .live
    @State private var generatedKey: String?
    @State private var showingKeyAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                tokenHealthPanel

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("API Keys").font(.headline)
                        Spacer()
                        Button { showingAddKey = true } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }

                    if keyService.keys.isEmpty {
                        emptyStateCard(text: "No API keys yet — create one to authenticate your integrations.")
                    } else {
                        ForEach(keyService.keys) { key in
                            developerKeyCard(key)
                        }
                    }
                }

                webhooksSection
                environmentSection
                credentialVaultSummary
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Auth & Webhooks")
        .sheet(isPresented: $showingAddKey) {
            addKeySheet
        }
        .alert("Key Generated", isPresented: $showingKeyAlert) {
            Button("I have saved this key", role: .cancel) {
                generatedKey = nil
            }
        } message: {
            if let key = generatedKey {
                Text("Your new API key is:\n\n\(key)\n\nCopy it now. It will not be shown again.")
            }
        }
    }

    private var webhooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Webhooks").font(.headline)
                Spacer()
                NavigationLink(destination: DeveloperWebhookManagerView()) {
                    Image(systemName: "plus.circle.fill")
                }
            }

            if webhookService.endpoints.isEmpty {
                emptyStateCard(text: "No webhooks configured. Receive real-time event notifications at your service endpoints.")
            } else {
                ForEach(webhookService.endpoints) { webhook in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(webhook.url).font(.subheadline.bold()).lineLimit(1)
                            Text("\(webhook.subscribedEvents.count) events").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(webhook.isActive)).labelsHidden()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Service Environments").font(.headline)
                Spacer()
                NavigationLink(destination: DeveloperSandboxEnvironmentView()) {
                    Image(systemName: "plus.circle.fill")
                }
            }

            Text("Manage your live and test environments to isolate data.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func emptyStateCard(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tokenHealthPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Summary").font(.headline)

            HStack(spacing: 12) {
                healthMetric(label: "Active", value: "\(keyService.keys.filter { !$0.isRevoked }.count)", color: .green)
                healthMetric(label: "Expiring", value: "0", color: .orange)
                healthMetric(label: "Revoked", value: "\(keyService.keys.filter { $0.isRevoked }.count)", color: .secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func healthMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func developerKeyCard(_ key: APIKey) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(key.label).font(.subheadline.bold())
                    Text(key.type.rawValue).font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }
                Spacer()
                if !key.isRevoked {
                    Button(role: .destructive) {
                        Task { try? await keyService.revokeKey(id: key.id, reason: .noLongerNeeded) }
                    } label: {
                        Text("Revoke").font(.caption.bold())
                    }
                } else {
                    Text("Revoked").font(.caption2.bold()).foregroundStyle(.red)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Key ID: \(key.maskedValue)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("Created: \(key.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if let lastUsed = key.lastUsedAt {
                    Text("Last used: \(lastUsed.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Never used").font(.system(size: 8)).foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var addKeySheet: some View {
        NavigationStack {
            Form {
                Section("Key Details") {
                    TextField("Key Label", text: $newKeyName)
                    Picker("Type", selection: $selectedKeyType) {
                        ForEach(APIKeyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Picker("Environment", selection: $selectedEnvironment) {
                        ForEach(KeyEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                }

                Section {
                    Text("Generating a new key will follow our strict token pattern for secure authentication.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Generate New Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddKey = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        Task {
                            let key = try? await keyService.createKey(label: newKeyName, type: selectedKeyType, environment: selectedEnvironment)
                            await MainActor.run {
                                generatedKey = key
                                newKeyName = ""
                                showingAddKey = false
                                showingKeyAlert = true
                            }
                        }
                    }
                    .disabled(newKeyName.isEmpty)
                }
            }
        }
    }

    private var credentialVaultSummary: some View {
        HStack {
            Image(systemName: "lock.shield.fill").foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text("Security Notice").font(.subheadline.bold())
                Text("API keys provide full developer access. Never share them.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
