import SwiftUI

struct Diag_EntitlementsView: View {
    var body: some View {
        List {
            Section("Security Entitlements") {
                EntitlementRow(name: "com.apple.security.app-sandbox", status: true)
                EntitlementRow(name: "com.apple.security.network.client", status: true)
                EntitlementRow(name: "com.apple.security.files.user-selected.read-write", status: true)
            }

            Section("Privacy Permissions") {
                EntitlementRow(name: "NSCameraUsageDescription", status: true)
                EntitlementRow(name: "NSMicrophoneUsageDescription", status: true)
                EntitlementRow(name: "NSLocationWhenInUseUsageDescription", status: true)
            }

            Section("App Groups") {
                Text("group.com.aurora.toolskit")
                    .font(.caption.monospaced())
            }
        }
        .navigationTitle("App Entitlements")
    }
}

struct EntitlementRow: View {
    let name: String
    let status: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.caption.monospaced())
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(status ? .green : .red)
        }
    }
}
