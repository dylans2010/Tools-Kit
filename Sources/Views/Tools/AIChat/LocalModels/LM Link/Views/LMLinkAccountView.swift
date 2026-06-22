import SwiftUI

struct LMLinkAccountView: View {
    @StateObject private var authManager = LMLinkAuthManager.shared

    var body: some View {
        List {
            Section(header: Text("Account")) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(authManager.username ?? "Not available")
                            .font(.headline)
                        Text("LM Studio Account")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Connection Status")) {
                HStack {
                    Text("Status")
                    Spacer()
                    if authManager.isLinked {
                        Label("Linked", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Not Linked", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                if let keyId = authManager.keyId {
                    LabeledContent("Key ID", value: String(keyId.prefix(8)) + "...")
                }
            }

            Section {
                if authManager.isLinked {
                    Button(role: .destructive, action: {
                        authManager.unlink()
                    }) {
                        Text("Unlink Device")
                    }
                } else {
                    Button(action: {
                        authManager.initiateLink()
                    }) {
                        Text("Link LM Studio")
                    }
                }
            }

            Section(header: Text("About LM Link")) {
                Text("LM Link uses cryptographic signatures to securely identify your device to local LM Studio instances on your network.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Account")
        .refreshable {
            await authManager.refreshStatus()
        }
    }
}
