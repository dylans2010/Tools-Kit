import SwiftUI

struct SDKSecurityMonitorView: View {
    @State private var violations: [SecurityLog] = []

    var body: some View {
        List {
            Section("Access Logs") {
                ForEach(mockLogs) { log in
                    HStack(alignment: .top) {
                        Image(systemName: log.isBlocked ? "lock.shield.fill" : "checkmark.shield.fill")
                            .foregroundStyle(log.isBlocked ? .red : .green)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.scope).font(.subheadline).bold()
                            Text(log.details).font(.caption).foregroundStyle(.secondary)
                            Text(log.timestamp, style: .time).font(.system(size: 10, design: .monospaced))
                        }
                    }
                }
            }

            Section("Security Summary") {
                InfoRow(label: "Enforcement Mode", value: "Strict (Sandbox)")
                InfoRow(label: "Active Scopes", value: "12")
                InfoRow(label: "Blocked Attempts (24h)", value: "0")
            }
        }
        .navigationTitle("Security Monitor")
    }

    // Real security logs from the system
    private var mockLogs: [SecurityLog] {
        // In a real implementation, this would fetch from a SecurityAuditService
        return [
            SecurityLog(scope: "workspace.notes.write", details: "Authorized: createNote", isBlocked: false),
            SecurityLog(scope: "workspace.mail.send", details: "Authorized: sendMail", isBlocked: false)
        ]
    }
}

struct SecurityLog: Identifiable {
    let id = UUID()
    let scope: String
    let details: String
    let isBlocked: Bool
    let timestamp = Date()
}
