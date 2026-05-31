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
    @State private var revocationDescription = ""

    @State private var selectedKeyForPolicy: APIKey?
    @State private var showingPolicyEditor = false

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

                securityPolicySection
                webhooksSummarySection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Auth & Identity")
        .sheet(isPresented: $showingAddKey) {
            addKeySheet
        }
        .sheet(item: Binding(get: { rotatingKeyID.map { IdentifiableUUID(id: $0) } }, set: { rotatingKeyID = $0?.id })) { item in
            rotateKeySheet(id: item.id)
        }
        .sheet(item: Binding(get: { revokingKeyID.map { IdentifiableUUID(id: $0) } }, set: { revokingKeyID = $0?.id })) { item in
            revokeKeySheet(id: item.id)
        }
        .sheet(isPresented: $showingPolicyEditor) {
            if let key = selectedKeyForPolicy {
                KeyPolicyEditorView(key: key)
            }
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

    private var tokenHealthPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Credential Status").font(.headline)
                    Text("Last audit: \(Date().formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lock.shield.fill").font(.title2).foregroundStyle(.green)
            }

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
                            .background(Color.accentColor.opacity(0.1), in: Capsule()).foregroundStyle(.accentColor)
                        Text(key.environment.rawValue).font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(key.environment == .live ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            .foregroundStyle(key.environment == .live ? .green : .orange).clipShape(Capsule())
                    }
                }
                Spacer()
                if !key.isRevoked {
                    Menu {
                        Button {
                            selectedKeyForPolicy = key
                            showingPolicyEditor = true
                        } label: { Label("Edit Policies", systemImage: "shield.righthalf.filled") }
                        Button { rotatingKeyID = key.id } label: { Label("Rotate Key", systemImage: "arrow.triangle.2.circlepath") }
                        Divider()
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

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(key.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                    Spacer()
                    if let expiry = key.expiresAt {
                        Text("Expires: \(expiry.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 9))
                            .foregroundStyle(expiry.timeIntervalSinceNow < 7*24*3600 ? .red : .secondary)
                    } else {
                        Text("Never expires").font(.system(size: 9)).foregroundStyle(.tertiary)
                    }
                }

                if let app = appService.apps.first(where: { $0.id == key.appID }) {
                    Text("Attached to \(app.name)").font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var securityPolicySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auth Policies").font(.headline)

            VStack(spacing: 1) {
                policyRow(title: "Multi-Factor Auth", description: "Require MFA for all API key rotations.", isOn: true)
                policyRow(title: "IP Whitelisting", description: "Restrict key usage to known IP ranges.", isOn: false)
                policyRow(title: "Automatic Rotation", description: "Enforce 90-day rotation for production keys.", isOn: true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func policyRow(title: String, description: String, isOn: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: .constant(isOn)).labelsHidden()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var webhooksSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Webhooks Status").font(.headline)
                Spacer()
                NavigationLink(destination: DeveloperWebhookManagerView()) {
                    Text("Manage").font(.caption.bold())
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("\(webhookService.endpoints.count) Endpoints").font(.subheadline.bold())
                    Text("Total events sent: 12.4k").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("All systems operational").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var addKeySheet: some View {
        NavigationStack {
            Form {
                Section("Key Configuration") {
                    TextField("Key Label (e.g. CI/CD Runner)", text: $newKeyName)
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
                        Text("Account Level (Global Access)").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Expiration") {
                    Text("Production keys should ideally have an expiration date to ensure regular rotation.")
                        .font(.caption).foregroundStyle(.secondary)
                    // Simplified TTL - real impl would have a DatePicker
                }
            }
            .navigationTitle("Generate Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddKey = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        Task {
                            if let key = try? await keyService.createKey(label: newKeyName, type: selectedKeyType, environment: selectedEnvironment, appID: selectedAppID) {
                                await MainActor.run {
                                    generatedKey = key
                                    newKeyName = ""
                                    showingAddKey = false
                                    showingKeyAlert = true
                                }
                            }
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
                Text("Rotating this key will immediately invalidate the old one. Update your applications immediately after.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type key label to confirm:").font(.caption.bold())
                    Text(key?.label ?? "").font(.caption.monospaced()).foregroundStyle(.secondary)
                    TextField("Confirm Label", text: $rotationMatchLabel)
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
                    Text("Confirm Rotation")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(rotationMatchLabel == key?.label ? Color.orange : Color.secondary)
                        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(rotationMatchLabel != key?.label)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { rotatingKeyID = nil; rotationMatchLabel = "" } }
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

                    VStack(alignment: .leading) {
                        Text("Discovery details").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $revocationDescription)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    Text("Warning: This action is permanent. Any services currently using this key will immediately fail.")
                        .foregroundStyle(.red).font(.caption.bold())
                }
            }
            .navigationTitle("Revoke Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") {
                    revokingKeyID = nil
                    revocationDescription = ""
                } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Revoke", role: .destructive) {
                        Task {
                            try? await keyService.revokeKey(id: id, reason: revocationReason, description: revocationDescription)
                            await MainActor.run {
                                revokingKeyID = nil
                                revocationDescription = ""
                            }
                        }
                    }
                    .disabled(revocationReason == .compromised && revocationDescription.count < 10)
                }
            }
        }
    }
}

struct IdentifiableUUID: Identifiable {
    let id: UUID
}

struct KeyPolicyEditorView: View {
    let key: APIKey
    @Environment(\.dismiss) var dismiss
    @State private var allowedIPs = ""
    @State private var rateLimit = 1000

    var body: some View {
        NavigationStack {
            Form {
                Section("Access Control") {
                    VStack(alignment: .leading) {
                        Text("IP Whitelist (Comma separated)").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. 192.168.1.1, 10.0.0.0/24", text: $allowedIPs)
                    }

                    Stepper("Rate Limit: \(rateLimit) req/min", value: $rateLimit, in: 10...10000, step: 100)
                }

                Section("Regional Restrictions") {
                    Toggle("Allow US Access", isOn: .constant(true))
                    Toggle("Allow EU Access", isOn: .constant(true))
                    Toggle("Allow Asia Access", isOn: .constant(false))
                }
            }
            .navigationTitle("Key Policies")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save") { dismiss() } }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
