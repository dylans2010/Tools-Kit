import SwiftUI

struct ConnectorSecurityView: View {
    let connector: ConnectorDefinition

    var body: some View {
        List {
            Section("Capabilities") {
                ForEach(connector.capabilities) { cap in
                    Label(cap.displayName, systemImage: cap.icon)
                }
            }

            Section("Security Policies") {
                Toggle("Enforce Rate Limiting", isOn: .constant(true))
                Toggle("Validate Data Schema", isOn: .constant(true))
                Toggle("Log All Requests", isOn: .constant(true))
            }

            Section("Data Exposure") {
                Text("Controls which parts of the workspace this connector can access.").font(.caption).secondary()
            }
        }
        .navigationTitle("Security & Scopes")
    }
}
