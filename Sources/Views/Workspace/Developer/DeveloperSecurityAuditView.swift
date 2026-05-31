import SwiftUI

struct DeveloperSecurityAuditView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @ObservedObject var keyService = APIKeyService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                securityHealthSummary

                VStack(alignment: .leading, spacing: 16) {
                    Text("Security Audit Log").font(.headline)
                    let securityLogs = logService.logEntries.filter { $0.category == .authentication || $0.category == .security }

                    if securityLogs.isEmpty {
                        EmptyStateView(icon: "shield.text.badge.checkmark", title: "No Anomalies", message: "No security-related events have been flagged in your audit trail.")
                    } else {
                        ForEach(securityLogs.prefix(10)) { entry in
                            auditLogRow(entry)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Risk Remediation").font(.headline)
                    if keyService.keys.contains(where: { !$0.isRevoked && $0.createdAt.timeIntervalSinceNow < -90*24*3600 }) {
                        remediationCard(title: "Rotate Stale API Keys", detail: "One or more keys have exceeded the 90-day rotation policy.", icon: "key.fill", color: .orange)
                    }
                    if keyService.keys.filter({ !$0.isRevoked }).count > 10 {
                        remediationCard(title: "Excessive Key Volume", detail: "High number of active keys detected. Review and revoke unused credentials.", icon: "exclamationmark.shield.fill", color: .red)
                    }
                    remediationCard(title: "Minimum Privilege Audit", detail: "Ensure your application scopes follow the principle of least privilege.", icon: "lock.shield", color: .blue)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Security Audit")
    }

    private var securityHealthSummary: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Score").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)

            HStack(spacing: 32) {
                metricItem(label: "Active Risks", value: "0", color: .green)
                metricItem(label: "Warnings", value: "\(keyService.keys.filter { !$0.isRevoked && $0.lastUsedAt == nil }.count)", color: .orange)
                metricItem(label: "Auth Events", value: "\(logService.logEntries.filter({$0.category == .authentication}).count)", color: .blue)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func metricItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func auditLogRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.message).font(.subheadline.bold())
                Spacer()
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
            }
            Text("Origin: \(entry.source.component)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func remediationCard(title: String, detail: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.1))
                Image(systemName: icon).font(.headline).foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
