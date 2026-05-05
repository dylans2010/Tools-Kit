import SwiftUI

struct ConnectorAuthView: View {
    @Binding var auth: ConnectorAuth

    var body: some View {
        Form {
            Section("Authentication Method") {
                Picker("Type", selection: $auth.type) {
                    ForEach(AuthType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }

            if auth.type == .apiKey {
                Section("API Key Configuration") {
                    TextField("API Key", text: Binding(
                        get: { auth.apiKey ?? "" },
                        set: { auth.apiKey = $0 }
                    ))
                }
            } else if auth.type == .bearer {
                Section("Bearer Token") {
                    TextField("Token", text: Binding(
                        get: { auth.bearerToken ?? "" },
                        set: { auth.bearerToken = $0 }
                    ))
                }
            } else if auth.type == .oauth {
                Section("OAuth2 Configuration") {
                    Text("OAuth flow implementation logic here")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Section("Custom Headers") {
                // Implementation for custom headers list
                Text("Custom headers for authorization").font(.caption).secondary()
            }
        }
        .navigationTitle("Authentication")
    }
}
