import SwiftUI

enum APIKeyEnvironment: String, CaseIterable, Hashable {
    case development, staging, production, sandbox, live
}

struct AuthServiceManagerView: View {
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var showingCreateKey = false
    @State private var keyLabel = ""
    @State private var selectedAppID: UUID?
    @State private var selectedEnvironment: APIKeyEnvironment = .development
    @State private var selectedScopes: Set<String> = []

    @State private var newlyCreatedKey: APIKey?
    @State private var showingKeyModal = false

    var body: some View {
        List {
            Section("Security Overview") {
                HStack(spacing: 20) {
                    metricItem(label: "Active Keys", value: "\(keyService.keys.filter { !$0.isRevoked }.count)", icon: "key.fill")
                    metricItem(label: "Total Requests", value: "84.2k", icon: "arrow.up.right.circle.fill")
                }
                .padding(.vertical, 8)
            }

            Section {
                Button {
                    showingCreateKey = true
                } label: {
                    Label("Create New API Key", systemImage: "plus.key.fill")
                        .font(.subheadline.bold())
                }
            }

            Section("Managed Keys") {
                if keyService.keys.isEmpty {
                    EmptyStateView(icon: "key.slash", title: "No API Keys", message: "Generate an API key to allow your application to authenticate with our services.")
                } else {
                    ForEach(keyService.keys) { key in
                        keyRow(key)
                    }
                }
            }
        }
        .navigationTitle("Authentication")
        .sheet(isPresented: $showingCreateKey) { createKeySheet }
        .sheet(isPresented: $showingKeyModal) { keyDisplayModal }
    }

    private func metricItem(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func keyRow(_ key: APIKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(key.label).font(.subheadline.bold())
                    Text(key.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(key)
            }

            HStack {
                if let app = appService.apps.first(where: { $0.id == key.appID }) {
                    Label(app.name, systemImage: "app").font(.system(size: 9)).foregroundStyle(.tertiary)
                }
                Spacer()
                Text("Created \(key.createdAt.formatted(date: .abbreviated, time: .omitted))").font(.system(size: 8)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .swipeActions {
            if !key.isRevoked {
                Button(role: .destructive) {
                    Task { try? await keyService.revokeKey(id: key.id, reason: .other) }
                } label: {
                    Label("Revoke", systemImage: "xmark.circle")
                }
            }
        }
    }

    private func statusBadge(_ key: APIKey) -> some View {
        Text(key.isRevoked ? "REVOKED" : key.environment.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(key.isRevoked ? Color.red.opacity(0.1) : (key.environment == .live ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)))
            .foregroundStyle(key.isRevoked ? .red : (key.environment == .live ? .green : .orange))
            .clipShape(Capsule())
    }

    private var createKeySheet: some View {
        NavigationStack {
            Form {
                Section("Key Identification") {
                    TextField("Label", text: $keyLabel, prompt: Text("e.g. Production Web"))
                    Picker("Application", selection: $selectedAppID) {
                        Text("Select App").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Environment") {
                    Picker("Environment", selection: $selectedEnvironment) {
                        ForEach(APIKeyEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Expiration") {
                    Text("This key will expire in 90 days by default for security compliance.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreateKey = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createKey()
                    }
                    .disabled(keyLabel.isEmpty || selectedAppID == nil)
                }
            }
        }
    }

    private var keyDisplayModal: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "key.fill").font(.system(size: 48)).foregroundStyle(.yellow)

                VStack(spacing: 8) {
                    Text("API Key Created").font(.headline)
                    Text("Copy this key now. For security reasons, you will not be able to see it again.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                if let key = newlyCreatedKey {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(key.value)
                            .font(.system(size: 14, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            UIPasteboard.general.string = key.value
                        } label: {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc").font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()

                Button("I've saved it securely") {
                    showingKeyModal = false
                    newlyCreatedKey = nil
                }
                .font(.subheadline.bold())
            }
            .padding(32)
            .navigationTitle("Your API Key")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func createKey() {
        guard let appID = selectedAppID else { return }
        let expiresAt = Date().addingTimeInterval(90 * 24 * 3600)

        Task {
            let env: KeyEnvironment = (selectedEnvironment == APIKeyEnvironment.live ? .live : .test)
            let keyString = try? await keyService.createKey(
                label: keyLabel,
                type: .developerAPI,
                environment: env,
                scopeIdentifiers: ["*"],
                appID: appID,
                expiresAt: expiresAt
            )

            await MainActor.run {
                if let keyString = keyString {
                    var createdKey = APIKey(maskedValue: "...", label: keyLabel, type: .developerAPI, environment: env)
                    createdKey.value = keyString
                    newlyCreatedKey = createdKey
                }
                showingCreateKey = false
                showingKeyModal = true
                keyLabel = ""
            }
        }
    }
}
