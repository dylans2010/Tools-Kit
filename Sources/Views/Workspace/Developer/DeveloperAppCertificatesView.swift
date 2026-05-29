import SwiftUI

struct DeveloperAppCertificatesView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Signing Certificates") {
                if selectedAppID != nil {
                    Text("No certificates found for this app. Certificates are required for distribution.").font(.caption).foregroundStyle(.secondary)

                    Button("Request Certificate") {
                        // Awaiting backend integration
                    }
                } else {
                    Text("Select an app to manage certificates.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Certificates")
    }
}
