import SwiftUI

struct EncryptedVaultTool: Tool {
    let name = "Encrypted Vault"
    let icon = "key.viewfinder"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.advanced
    let description = "Securely store secrets in the iOS Keychain with categories"
    let requiresAPI = false
    var view: AnyView { AnyView(EncryptedVaultView()) }
}

struct EncryptedVaultView: View {
    @StateObject private var backend = EncryptedVaultBackend()
    @State private var showAdd = false
    @State private var revealedEntry: String?

    var body: some View {
        ToolDetailView(tool: EncryptedVaultTool()) {
            VStack(spacing: 16) {
                addButton
                if backend.entries.isEmpty {
                    emptyState
                } else {
                    entriesSection
                }
            }
        }
        .navigationTitle("Encrypted Vault")
        .sheet(isPresented: $showAdd) {
            AddVaultEntrySheet(backend: backend)
        }
    }

    private var addButton: some View {
        Button {
            showAdd = true
        } label: {
            Label("Add Secret", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.viewfinder")
                .font(.system(size: 48)).foregroundColor(.secondary)
            Text("No secrets stored yet").font(.headline)
            Text("Add passwords, tokens, or notes to your encrypted vault.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var entriesSection: some View {
        ToolInputSection("Vault Entries (\(backend.entries.count))") {
            ForEach(backend.entries) { entry in
                VaultEntryRow(
                    entry: entry,
                    backend: backend,
                    isRevealed: revealedEntry == entry.id,
                    onReveal: {
                        revealedEntry = revealedEntry == entry.id ? nil : entry.id
                    }
                )
                if entry.id != backend.entries.last?.id { Divider().padding(.leading, 44) }
            }
        }
    }
}

struct VaultEntryRow: View {
    let entry: VaultEntry
    let backend: EncryptedVaultBackend
    let isRevealed: Bool
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.category.icon)
                .frame(width: 24).foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.label).font(.subheadline.weight(.medium))
                Text(entry.category.rawValue)
                    .font(.caption).foregroundColor(.secondary)
                if isRevealed, let secret = backend.secret(for: entry) {
                    Text(secret)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .lineLimit(2)
                        .transition(.opacity)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    withAnimation { onReveal() }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundColor(.blue)
                }

                Button {
                    if let secret = backend.secret(for: entry) {
                        UIPasteboard.general.string = secret
                    }
                } label: {
                    Image(systemName: "doc.on.doc").foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    backend.deleteEntry(entry)
                } label: {
                    Image(systemName: "trash").foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal).padding(.vertical, 10)
    }
}

struct AddVaultEntrySheet: View {
    let backend: EncryptedVaultBackend
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var secret = ""
    @State private var category: VaultEntry.VaultCategory = .password
    @State private var showSecret = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Label (e.g. GitHub Token)", text: $label)
                    Picker("Category", selection: $category) {
                        ForEach(VaultEntry.VaultCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                } header: {
                    Text("Details")
                }
                Section {
                    HStack {
                        if showSecret {
                            TextField("Secret Value", text: $secret)
                        } else {
                            SecureField("Secret Value", text: $secret)
                        }
                        Button {
                            showSecret.toggle()
                        } label: {
                            Image(systemName: showSecret ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Secret")
                }
            }
            .navigationTitle("New Secret")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        backend.addEntry(label: label, secret: secret, category: category)
                        dismiss()
                    }
                    .disabled(label.isEmpty || secret.isEmpty)
                }
            }
        }
    }
}
