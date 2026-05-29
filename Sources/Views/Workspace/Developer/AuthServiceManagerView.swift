import SwiftUI

struct AuthServiceManagerView: View {
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var webhookService = WebhookService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddKey = false
    @State private var newKeyName = ""
    @State private var selectedKeyType: APIKeyType = .developerAPI
    @State private var selectedEnvironment: KeyEnvironment = .live
    @State private var selectedAppID: UUID?
    @State private var generatedKey: String?
    @State private var showingKeyAlert = false
    @State private var rotatingKeyID: UUID?
    @State private var rotationMatchLabel = ""
    @State private var revokingKeyID: UUID?
    @State private var revocationReason: DeveloperKeyRevocationReason = .noLongerNeeded

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                tokenHealthPanel

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("API Keys").font(.headline)
                        Spacer()
                        Button {
                            selectedAppID = nil
                            showingAddKey = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
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
        .sheet(item: Binding(get: { rotatingKeyID.map { IdentifiableUUID(id: $0) } }, set: { rotatingKeyID = $0?.id })) { item in
            rotateKeySheet(id: item.id)
        }
        .sheet(item: Binding(get: { revokingKeyID.map { IdentifiableUUID(id: $0) } }, set: { revokingKeyID = $0?.id })) { item in
            revokeKeySheet(id: item.id)
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
                NavigationLink(destination: WebhookManagerView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
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
                        .font(.title3)
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
                healthMetric(label: "Expiring", value: "\(keyService.keys.filter { !$0.isRevoked && $0.expiresAt != nil && $0.expiresAt!.timeIntervalSinceNow < 30 * 24 * 3600 }.count)", color: .orange)
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
                    HStack(spacing: 4) {
                        Text(key.type.rawValue).font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1), in: Capsule()).foregroundStyle(.blue)
                        Text(key.environment.rawValue).font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(key.environment == .live ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            .foregroundStyle(key.environment == .live ? .green : .orange).clipShape(Capsule())
                    }
                }
                Spacer()
                if !key.isRevoked {
                    Menu {
                        Button { rotatingKeyID = key.id } label: { Label("Rotate Key", systemImage: "arrow.triangle.2.circlepath") }
                        Button(role: .destructive) { revokingKeyID = key.id } label: { Label("Revoke Key", systemImage: "xmark.circle") }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title3)
                    }
                } else {
                    Text("Revoked").font(.caption2.bold()).foregroundStyle(.red)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.red.opacity(0.1), in: Capsule())
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Masked:").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Text(key.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }

                if let app = appService.apps.first(where: { $0.id == key.appID }) {
                    HStack {
                        Text("Project:").font(.system(size: 10)).foregroundStyle(.tertiary)
                        Text(app.name).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Account-level access").font(.system(size: 10)).foregroundStyle(.tertiary)
                }

                HStack {
                    Text("Created:").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Text(key.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(key.isRevoked ? Color.red.opacity(0.1) : Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var addKeySheet: some View {
        NavigationStack {
            Form {
                Section("Key Configuration") {
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
                    Picker("Project Assignment", selection: $selectedAppID) {
                        Text("Account Level (No Project)").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section {
                    Text("Your new key will be generated using a secure cryptographically random payload and a deterministic checksum.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Generate API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddKey = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        Task {
                            do {
                                let key = try await keyService.createKey(
                                    label: newKeyName,
                                    type: selectedKeyType,
                                    environment: selectedEnvironment,
                                    appID: selectedAppID
                                )
                                await MainActor.run {
                                    generatedKey = key
                                    newKeyName = ""
                                    showingAddKey = false
                                    showingKeyAlert = true
                                }
                            } catch {}
                        }
                    }
                    .disabled(newKeyName.count < 3)
                }
            }
        }
    }

    private func rotateKeySheet(id: UUID) -> some View {
        let key = keyService.keys.first { $0.id == id }
        return NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 48)).foregroundStyle(.orange)
                Text("Rotate API Key").font(.headline)
                Text("Rotating this key will immediately revoke the old one. This cannot be undone.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Text("To confirm, type the key label exactly:").font(.caption.bold())
                    Text(key?.label ?? "").font(.caption.monospaced()).foregroundStyle(.secondary)
                    TextField("Key Label", text: $rotationMatchLabel)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button {
                    Task {
                        if let key = try? await keyService.rotateKey(id: id) {
                            await MainActor.run {
                                generatedKey = key
                                rotatingKeyID = nil
                                rotationMatchLabel = ""
                                showingKeyAlert = true
                            }
                        }
                    }
                } label: {
                    Text("Revoke and Re-generate")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(rotationMatchLabel == key?.label ? Color.orange : Color.secondary)
                        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(rotationMatchLabel != key?.label)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        rotatingKeyID = nil
                        rotationMatchLabel = ""
                    }
                }
            }
        }
    }

    private func revokeKeySheet(id: UUID) -> some View {
        let key = keyService.keys.first { $0.id == id }
        return NavigationStack {
            Form {
                Section("Revoke Key: \(key?.label ?? "")") {
                    Picker("Reason", selection: $revocationReason) {
                        ForEach(DeveloperKeyRevocationReason.allCases, id: \.self) { reason in
                            Text(reason.rawValue).tag(reason)
                        }
                    }

                    if revocationReason == .compromised {
                        VStack(alignment: .leading) {
                            Text("Discovery details (min 20 chars)").font(.caption).foregroundStyle(.secondary)
                            TextEditor(text: $newKeyName) // Re-using newKeyName as temp storage
                                .frame(minHeight: 100)
                        }
                    }
                }

                Section {
                    Text("Revoking this key is permanent. Any application using this key will immediately lose access.")
                        .foregroundStyle(.red).font(.caption.bold())
                }
            }
            .navigationTitle("Revoke API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { revokingKeyID = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Revoke", role: .destructive) {
                        Task {
                            try? await keyService.revokeKey(id: id, reason: revocationReason, description: revocationReason == .compromised ? newKeyName : "")
                            await MainActor.run {
                                revokingKeyID = nil
                                newKeyName = ""
                            }
                        }
                    }
                    .disabled(revocationReason == .compromised && newKeyName.count < 20)
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

struct IdentifiableUUID: Identifiable {
    let id: UUID
}
