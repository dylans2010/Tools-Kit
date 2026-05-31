import SwiftUI

struct CLITokenView: View {
    @ObservedObject var keyService = APIKeyService.shared
    @State private var showingAddToken = false
    @State private var tokenLabel = ""
    @State private var selectedTTL: TimeInterval = 3600 // 1 hour
    @State private var newlyCreatedToken: APIKey?
    @State private var showingTokenModal = false

    var cliTokens: [APIKey] {
        keyService.keys.filter { $0.type == .cli }
    }

    var body: some View {
        List {
            Section("Command Line Interface") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "terminal.fill").foregroundStyle(.secondary)
                        Text("Personal Access Tokens").font(.subheadline.bold())
                    }
                    Text("Use these tokens to authenticate the Tools-Kit CLI and other automated scripts. Treat them like passwords.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section {
                Button { showingAddToken = true } label: {
                    Label("Generate CLI Token", systemImage: "plus.square.fill")
                        .font(.subheadline.bold())
                }
            }

            Section("Your Tokens") {
                if cliTokens.isEmpty {
                    EmptyStateView(icon: "terminal", title: "No Tokens", message: "You haven't generated any CLI tokens yet.")
                } else {
                    ForEach(cliTokens) { token in
                        tokenRow(token)
                    }
                    .onDelete(perform: revokeTokens)
                }
            }
        }
        .navigationTitle("CLI Tokens")
        .sheet(isPresented: $showingAddToken) { addTokenSheet }
        .sheet(isPresented: $showingTokenModal) { tokenDisplayModal }
    }

    private func tokenRow(_ token: APIKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(token.label).font(.subheadline.bold())
                Spacer()
                statusBadge(token)
            }

            Text(token.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)

            if let expiry = token.expiresAt {
                Text("Expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ token: APIKey) -> some View {
        let isExpired = token.expiresAt != nil && token.expiresAt! < Date()
        return Text(isExpired ? "EXPIRED" : (token.isRevoked ? "REVOKED" : "ACTIVE"))
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background((isExpired || token.isRevoked) ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
            .foregroundStyle((isExpired || token.isRevoked) ? .red : .green)
            .clipShape(Capsule())
    }

    private var addTokenSheet: some View {
        NavigationStack {
            Form {
                Section("Token Identification") {
                    TextField("Label (e.g. MacBook Pro CLI)", text: $tokenLabel)
                }

                Section("Lifespan") {
                    Picker("Expires In", selection: $selectedTTL) {
                        Text("1 Hour").tag(TimeInterval(3600))
                        Text("24 Hours").tag(TimeInterval(86400))
                        Text("7 Days").tag(TimeInterval(604800))
                        Text("30 Days").tag(TimeInterval(2592000))
                        Text("90 Days").tag(TimeInterval(7776000))
                    }
                }
            }
            .navigationTitle("Generate Token")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddToken = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") { generate() }
                        .disabled(tokenLabel.isEmpty)
                }
            }
        }
    }

    private var tokenDisplayModal: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "terminal.fill").font(.system(size: 48)).foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("Token Generated").font(.headline)
                    Text("Copy this token now. It will never be shown again for security reasons.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                if let token = newlyCreatedToken {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(token.value)
                            .font(.system(size: 13, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            UIPasteboard.general.string = token.value
                        } label: {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc").font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()

                Button("I've securely stored this token") {
                    showingTokenModal = false
                    newlyCreatedToken = nil
                }
                .font(.subheadline.bold())
            }
            .padding(32)
        }
    }

    private func generate() {
        Task {
            let expiry = Date().addingTimeInterval(selectedTTL)
            let token = try? await keyService.createKey(
                label: tokenLabel,
                appID: UUID(), // Global CLI token
                type: .cli,
                environment: .live,
                expiresAt: expiry
            )
            await MainActor.run {
                newlyCreatedToken = token
                tokenLabel = ""
                showingAddToken = false
                showingTokenModal = true
            }
        }
    }

    private func revokeTokens(at offsets: IndexSet) {
        for index in offsets {
            let token = cliTokens[index]
            Task { try? await keyService.revokeKey(id: token.id) }
        }
    }
}
