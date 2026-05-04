import SwiftUI

struct SecurityRecoveryOptionsView: View {
    @State private var recoveryKeyGenerated = false
    @State private var recoveryKey = "TOOL-SKIT-RECO-VERY-KEY-1234-5678"
    @State private var useBackupPin = false
    @State private var backupPin = ""

    var body: some View {
        List {
            Section(header: Text("Master Recovery Key")) {
                if !recoveryKeyGenerated {
                    Button("Generate Recovery Key") {
                        recoveryKeyGenerated = true
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recoveryKey)
                            .font(.system(.headline, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        Text("Save this key in a secure location. It is the only way to recover your vault if you forget your master password.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            UIPasteboard.general.string = recoveryKey
                        } label: {
                            Label("Copy Key", systemImage: "doc.on.doc")
                        }
                    }
                }
            }

            Section(header: Text("Backup Access")) {
                Toggle("Enable Backup PIN", isOn: $useBackupPin)
                if useBackupPin {
                    SecureField("Set Backup PIN", text: $backupPin)
                        .keyboardType(.numberPad)
                }
            }
        }
        .navigationTitle("Recovery Options")
    }
}
