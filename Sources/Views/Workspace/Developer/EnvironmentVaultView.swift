import SwiftUI

struct EnvironmentVaultView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var newKey = ""
    @State private var newValue = ""

    var body: some View {
        List {
            Section("Environment Variables") {
                Text("Securely manage environment-specific configuration and secrets for your application runtime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                if store.vaultVariables.isEmpty {
                    Text("No variables stored.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.vaultVariables) { variable in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(variable.key).font(.system(size: 11, weight: .bold, design: .monospaced))
                                Text(variable.value).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if variable.isSecret {
                                Image(systemName: "lock.fill").font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            Section {
                Button { showingAdd = true } label: {
                    Label("Add Variable", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Environment Vault")
        .onAppear {
            if store.vaultVariables.isEmpty {
                store.saveVaultVariables([
                    VaultVariable(key: "API_GATEWAY_URL", value: "https://api.prod.internal", isSecret: false),
                    VaultVariable(key: "DB_PASSWORD", value: "••••••••••••", isSecret: true)
                ])
            }
        }
        .alert("New Variable", isPresented: $showingAdd) {
            TextField("Key", text: $newKey)
            TextField("Value", text: $newValue)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                var current = store.vaultVariables
                current.append(VaultVariable(key: newKey, value: newValue, isSecret: false))
                store.saveVaultVariables(current)
                newKey = ""
                newValue = ""
            }
        }
    }
}
