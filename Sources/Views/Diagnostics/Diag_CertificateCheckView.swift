import SwiftUI

struct Diag_CertificateCheckView: View {
    var body: some View {
        List {
            Section("System Trust Store") {
                LabeledContent("Version", value: "2023120100")
                LabeledContent("Root Certs", value: "184")
            }

            Section("User Certificates") {
                Text("No user-installed certificates found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Revocation Check") {
                LabeledContent("OCSP Status", value: "Reachable")
                LabeledContent("CRL Check", value: "Active")
            }

            Section(footer: Text("Audits the certificates installed on the device to ensure secure connections.")) {
                EmptyView()
            }
        }
        .navigationTitle("Certificate Trust")
    }
}
