import SwiftUI

struct DeveloperAppCertificatesView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddCert = false
    @State private var certName = ""

    var body: some View {
        List {
            Section("Target Application") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Active Certificates") {
                if selectedAppID == nil {
                    Text("Select an app to manage certificates.").font(.caption).foregroundStyle(.secondary)
                } else {
                    certificateRow(name: "Development SSL", type: "Development", status: "Active", expiry: "Sep 20, 2025")
                    certificateRow(name: "Distribution Profile", type: "Production", status: "Active", expiry: "Dec 12, 2024")
                }
            }

            Section("Signing Identities") {
                Label("Main Signing Authority", systemImage: "checkmark.seal.fill").font(.subheadline).foregroundStyle(.green)
                Text("Your account is currently authorized for automatic signing.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Certificates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddCert = true } label: { Image(systemName: "plus") }
                    .disabled(selectedAppID == nil)
            }
        }
    }

    private func certificateRow(name: String, type: String, status: String, expiry: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text("\(type) • Expires \(expiry)").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(status).font(.system(size: 8, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.green.opacity(0.1)).foregroundStyle(.green).clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}
