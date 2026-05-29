import SwiftUI

struct DeveloperAppCertificatesView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var selectedAppID: UUID?
    @State private var showingRequestDialog = false

    var appCertificates: [DeveloperCertificate] {
        store.certificates.filter { $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("Project", selection: $selectedAppID) {
                    Text("Select a Project").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Signing Certificates") {
                if let appID = selectedAppID {
                    if appCertificates.isEmpty {
                        VStack(spacing: 12) {
                            EmptyStateView(text: "No active signing certificates found.", icon: "doc.badge.gearshape")

                            Button {
                                showingRequestDialog = true
                            } label: {
                                Label("Request New Certificate", systemImage: "plus.app.fill")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(appCertificates) { cert in
                            VStack(alignment: .leading) {
                                Text(cert.name).font(.subheadline.bold())
                                Text("Expires: \(cert.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteCertificates)
                    }
                } else {
                    Text("Select a project above to manage its cryptographic signing certificates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Certificates")
        .alert("Certificate Request", isPresented: $showingRequestDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Request") {
                if let appID = selectedAppID {
                    let newCert = DeveloperCertificate(appID: appID, name: "Development Certificate", type: "Development")
                    var current = store.certificates
                    current.append(newCert)
                    store.saveCertificates(current)
                }
            }
        } message: {
            Text("This will initiate a certificate signing request (CSR) process.")
        }
    }

    private func deleteCertificates(at offsets: IndexSet) {
        var current = store.certificates
        let toDelete = offsets.map { appCertificates[$0].id }
        current.removeAll { toDelete.contains($0.id) }
        store.saveCertificates(current)
    }
}
