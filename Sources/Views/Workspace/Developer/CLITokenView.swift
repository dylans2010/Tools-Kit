import SwiftUI

struct CLITokenView: View {
    @ObservedObject var keyService = APIKeyService.shared
    @State private var showingAddToken = false
    @State private var tokenLabel = ""
    @State private var selectedTTL: TimeInterval = 3600 // 1 hour
    @State private var generatedToken: String?
    @State private var showingAlert = false

    var cliTokens: [APIKey] {
        keyService.keys.filter { $0.type == .cli }
    }

    var body: some View {
        List {
            Section("Command Line Interface Tokens") {
                if cliTokens.isEmpty {
                    Text("No CLI tokens generated. Create a token to authenticate from the Tools-Kit CLI.").foregroundStyle(.secondary)
                } else {
                    ForEach(cliTokens) { token in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(token.label).font(.headline)
                                Spacer()
                                if let expiry = token.expiresAt, expiry < Date() {
                                    Text("Expired").font(.caption2.bold()).foregroundStyle(.red)
                                } else {
                                    Text("Active").font(.caption2.bold()).foregroundStyle(.green)
                                }
                            }
                            Text("Masked: \(token.maskedValue)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                            if let expiry = token.expiresAt {
                                Text("Expires: \(expiry.formatted())").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("CLI Tokens")
        .toolbar {
            Button { showingAddToken = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAddToken) {
            addTokenSheet
        }
        .alert("Token Generated", isPresented: $showingAlert) {
            Button("I have saved this token", role: .cancel) { generatedToken = nil }
        } message: {
            if let token = generatedToken {
                Text("Your CLI token is:\n\n\(token)\n\nCopy it now. It will not be shown again.")
            }
        }
    }

    private var addTokenSheet: some View {
        NavigationStack {
            Form {
                TextField("Token Label", text: $tokenLabel)
                Picker("Expires In", selection: $selectedTTL) {
                    Text("1 Hour").tag(TimeInterval(3600))
                    Text("24 Hours").tag(TimeInterval(86400))
                    Text("7 Days").tag(TimeInterval(604800))
                    Text("30 Days").tag(TimeInterval(2592000))
                }
            }
            .navigationTitle("New CLI Token")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddToken = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        generate()
                    }
                    .disabled(tokenLabel.isEmpty)
                }
            }
        }
    }

    private func generate() {
        Task {
            let token = try? await keyService.createKey(label: tokenLabel, type: .cli, environment: .live, ttl: selectedTTL)
            await MainActor.run {
                generatedToken = token
                tokenLabel = ""
                showingAddToken = false
                showingAlert = true
            }
        }
    }
}
