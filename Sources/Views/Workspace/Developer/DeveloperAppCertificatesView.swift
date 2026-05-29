import SwiftUI

struct DeveloperAppCertificatesView: View {
    var body: some View {
        List {
            Section("Active Certificates") {
                certificateRow(name: "Apple Push Services", id: "com.toolskit.push", expires: "Sep 12, 2025")
                certificateRow(name: "Developer ID Application", id: "DA12345678", expires: "Jan 05, 2027")
            }

            Section("Provisioning Profiles") {
                profileRow(name: "Tools-Kit App Store", appID: "com.tools-kit.app", status: "Active")
                profileRow(name: "Tools-Kit Development", appID: "com.tools-kit.app", status: "Active")
            }

            Section {
                Button("Request New Certificate") {}
                Button("Generate New Profile") {}
            }
        }
        .navigationTitle("Certificates & Profiles")
    }

    private func certificateRow(name: String, id: String, expires: String) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(.subheadline.bold())
            HStack {
                Text(id).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("Expires \(expires)").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func profileRow(name: String, appID: String, status: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.subheadline.bold())
                Text(appID).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(status).font(.caption2.bold()).foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}
