import SwiftUI

struct PluginSandboxConfigView: View {
    @State private var networkAccess = true
    @State private var fileSystemAccess = false
    @State private var keychainAccess = false
    @State private var telemetryAllowed = true

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Strict Mode", systemImage: "shield.lefthalf.filled")
                        .font(.headline)
                    Text("Enforces hardware-level isolation for untrusted plugins.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Resource Permissions") {
                Toggle(isOn: $networkAccess) {
                    Label("Network Access", systemImage: "network")
                }
                Toggle(isOn: $fileSystemAccess) {
                    Label("File System (Isolated)", systemImage: "folder.badge.gearshape")
                }
                Toggle(isOn: $keychainAccess) {
                    Label("Keychain Access", systemImage: "key.fill")
                }
            }

            Section("Data Privacy") {
                Toggle("Allowed Telemetry", isOn: $telemetryAllowed)
                HStack {
                    Text("Data Locality")
                    Spacer()
                    Text("On-Device Only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive, action: resetToSafeDefaults) {
                    Text("Reset to Safe Defaults")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Sandbox Config")
    }

    private func resetToSafeDefaults() {
        networkAccess = false
        fileSystemAccess = false
        keychainAccess = false
        telemetryAllowed = true
    }
}
