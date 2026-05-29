import SwiftUI

struct SandboxEnvironmentView: View {
    @State private var isSandboxMode = false

    var body: some View {
        List {
            Section("Session Context") {
                Toggle("Enable Sandbox Mode", isOn: $isSandboxMode)
                Text("In sandbox mode, all operations (key creation, scope requests, marketplace submissions) are isolated from live data.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if isSandboxMode {
                Section {
                    HStack {
                        Image(systemName: "testtube.2").foregroundStyle(.orange)
                        Text("Sandbox Mode Active").bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .navigationTitle("Sandbox")
    }
}
