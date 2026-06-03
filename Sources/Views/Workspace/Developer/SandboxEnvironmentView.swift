import SwiftUI

struct SandboxEnvironmentView: View {
    @State private var isSandboxMode = false
    @State private var showingReset = false

    var body: some View {
        List {
            Section("Developer Context") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "testtube.2").foregroundStyle(.orange)
                        Text("Simulated Runtime").font(.subheadline.bold())
                    }
                    Text("In Sandbox mode, all operations (API calls, key generation, database writes) are isolated from live production data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Toggle("Active Sandbox Session", isOn: $isSandboxMode)
            }

            if isSandboxMode {
                Section("Sandbox Configuration") {
                    HStack {
                        Text("Sandbox API Server")
                        Spacer()
                        Text("https://sandbox.api.internal").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Simulated Latency")
                        Spacer()
                        Text("84ms").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingReset = true
                    } label: {
                        Label("Reset Sandbox Data", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Runtime Environment")
        .confirmationDialog("Reset Sandbox?", isPresented: $showingReset) {
            Button("Reset Everything", role: .destructive) {
                DeveloperPersistentStore.shared.saveApps([])
                DeveloperPersistentStore.shared.saveKeys([])
                DeveloperPersistentStore.shared.saveWebhooks([])
            }
        } message: {
            Text("This will permanently clear all data associated with your sandbox session.")
        }
    }
}
