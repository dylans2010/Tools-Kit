import SwiftUI

struct ConnectorSecurityView: View {
    @State var connector: ConnectorDefinition? // Optional for global security view
    @StateObject private var manager = ConnectorManager.shared

    @State private var rateLimit = 60
    @State private var enforceTLS = true
    @State private var allowPublicAccess = false
    @State private var requestedScopes: Set<String> = ["api.read", "api.write"]

    var body: some View {
        Form {
            Section("Access Control") {
                Toggle("Enforce TLS 1.3+", isOn: $enforceTLS)
                Toggle("Allow Public Access", isOn: $allowPublicAccess)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Limit (Requests/min)").font(.caption).foregroundColor(.secondary)
                    Stepper("\(rateLimit) req/min", value: $rateLimit, in: 1...1000)
                }
            }

            Section("Required Scopes") {
                ForEach(Array(requestedScopes).sorted(), id: \.self) { scope in
                    HStack {
                        Image(systemName: "shield.fill").foregroundColor(.blue).font(.caption)
                        Text(scope)
                        Spacer()
                        Button {
                            requestedScopes.remove(scope)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                    }
                }

                Button("Add Scope") {
                    requestedScopes.insert("new.scope")
                }
            }

            Section("Compliance & Data") {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Data Residency: Local", systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                    Label("Encryption: AES-256", systemImage: "lock.fill")
                        .font(.subheadline)
                    Label("Audit Logs: Enabled", systemImage: "list.bullet.indent")
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }

            if let _ = connector {
                Section {
                    Button("Apply Security Policy") {
                        // Persist security settings
                    }
                    .frame(maxWidth: .infinity)
                    .bold()
                }
            }
        }
        .navigationTitle("Security & Scopes")
    }
}
