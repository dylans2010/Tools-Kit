import SwiftUI

struct DeveloperAppCertificatesView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddCertificate = false
    @State private var certificates: [AppCertificate] = [
        AppCertificate(name: "Development: John Doe", type: .development, expiry: Date().addingTimeInterval(365*24*3600), status: .active),
        AppCertificate(name: "Distribution: My Org", type: .distribution, expiry: Date().addingTimeInterval(30*24*3600), status: .expiringSoon)
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Certificates & Profiles").font(.headline)
                    Text("Manage signing identities and provisioning profiles for your applications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Signing Certificates") {
                if certificates.isEmpty {
                    Text("No certificates found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(certificates) { cert in
                        certificateRow(cert)
                    }
                    .onDelete(perform: deleteCertificate)
                }
            }

            Section("Provisioning Profiles") {
                ForEach(appService.apps) { app in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(app.name).font(.subheadline.bold())
                            Text(app.bundleId).font(.caption2).monospaced().foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Active").font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green.opacity(0.1), in: Capsule())
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button {
                    showingAddCertificate = true
                } label: {
                    Label("Request Certificate", systemImage: "plus.app.fill")
                        .font(.subheadline.bold())
                }
            }
        }
        .navigationTitle("Certificates")
        .sheet(isPresented: $showingAddCertificate) {
            AddCertificateSheet(certificates: $certificates)
        }
    }

    private func certificateRow(_ cert: AppCertificate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "seal.fill")
                .font(.title2)
                .foregroundStyle(cert.status == .active ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(cert.name).font(.subheadline.bold())
                Text(cert.type.rawValue).font(.caption2).foregroundStyle(.secondary)
                Text("Expires \(cert.expiry.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 8))
                    .foregroundStyle(cert.status == .expiringSoon ? .orange : .secondary)
            }
            Spacer()
            statusBadge(cert.status)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: AppCertificateStatus) -> some View {
        Text(status.rawValue).font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: AppCertificateStatus) -> Color {
        switch status {
        case .active: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        case .revoked: return .gray
        }
    }

    private func deleteCertificate(at offsets: IndexSet) {
        certificates.remove(atOffsets: offsets)
    }
}

struct AddCertificateSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var certificates: [AppCertificate]
    @State private var certName = ""
    @State private var certType: AppCertificateType = .development

    var body: some View {
        NavigationStack {
            Form {
                Section("Request New Certificate") {
                    TextField("Common Name", text: $certName)
                    Picker("Type", selection: $certType) {
                        Text("Development").tag(AppCertificateType.development)
                        Text("Distribution").tag(AppCertificateType.distribution)
                        Text("Push Notifications").tag(AppCertificateType.push)
                    }
                }

                Section {
                    Text("This will generate a Certificate Signing Request (CSR) and submit it for processing.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Certificate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Request") {
                        let newCert = AppCertificate(
                            name: certName,
                            type: certType,
                            expiry: Date().addingTimeInterval(365*24*3600),
                            status: .active
                        )
                        certificates.append(newCert)
                        dismiss()
                    }
                    .disabled(certName.isEmpty)
                }
            }
        }
    }
}

struct AppCertificate: Identifiable {
    let id = UUID()
    let name: String
    let type: AppCertificateType
    let expiry: Date
    let status: AppCertificateStatus
}

enum AppCertificateType: String {
    case development = "Development"
    case distribution = "Distribution"
    case push = "Push Notifications"
}

enum AppCertificateStatus: String {
    case active = "Active"
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
    case revoked = "Revoked"
}
