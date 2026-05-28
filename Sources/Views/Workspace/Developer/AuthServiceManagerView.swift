import SwiftUI
import Core

struct AuthServiceManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddKey = false
    @State private var newKeyName = ""
    @State private var selectedTier: KeyTier = .dev
    @State private var generatedKey: String?
    @State private var showingKeyAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                tokenHealthPanel

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Developer API Keys").font(.headline)
                        Spacer()
                        Button {
                            showingAddKey = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }

                    if store.keys.isEmpty {
                        Text("No API keys generated yet. Use keys to authenticate your apps and services.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(store.keys) { key in
                            developerKeyCard(key)
                        }
                    }
                }

                credentialVaultSummary
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Auth Services")
        .sheet(isPresented: $showingAddKey) {
            addKeySheet
        }
        .alert("New Key Generated", isPresented: $showingKeyAlert) {
            Button("Done") {
                generatedKey = nil
            }
        } message: {
            if let key = generatedKey {
                Text("Please copy your new API key now. You won't be able to see it again.\n\n\(key)")
            }
        }
    }

    private var tokenHealthPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Summary").font(.headline)

            HStack(spacing: 12) {
                healthMetric(label: "Active", value: "\(store.keys.count)", color: .green)
                healthMetric(label: "Expiring", value: "0", color: .orange)
                healthMetric(label: "Revoked", value: "0", color: .secondary)
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

    private func developerKeyCard(_ key: DeveloperKey) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(key.name).font(.subheadline.bold())
                    Text(key.tier).font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }
                Spacer()
                Button(role: .destructive) {
                    revokeKey(key)
                } label: {
                    Text("Revoke").font(.caption.bold())
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Key ID: \(key.key.prefix(12))...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("Created: \(key.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if let lastUsed = key.lastUsed {
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
        NavigationView {
            Form {
                Section("Key Details") {
                    TextField("Key Name", text: $newKeyName)
                    Picker("Tier", selection: $selectedTier) {
                        ForEach(KeyTier.allCases, id: \.self) { tier in
                            Text(tier.rawValue).tag(tier)
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
                        generateNewKey()
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

    private func generateNewKey() {
        do {
            let keyString = try DeveloperIDManager.shared.generateKey(tier: selectedTier)
            let newKey = DeveloperKey(
                key: keyString,
                name: newKeyName,
                tier: selectedTier.rawValue
            )
            var currentKeys = store.keys
            currentKeys.append(newKey)
            store.saveKeys(currentKeys)

            generatedKey = keyString
            newKeyName = ""
            showingAddKey = false
            showingKeyAlert = true
        } catch {
            print("Failed to generate key: \(error)")
        }
    }

    private func revokeKey(_ key: DeveloperKey) {
        var currentKeys = store.keys
        currentKeys.removeAll { $0.id == key.id }
        store.saveKeys(currentKeys)
    }
}
