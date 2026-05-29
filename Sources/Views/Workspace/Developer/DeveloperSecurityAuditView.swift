import SwiftUI

struct DeveloperSecurityAuditView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @ObservedObject var keyService = APIKeyService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Security Health").font(.headline)
                    HStack(spacing: 12) {
                        securityMetric(label: "Vulnerabilities", value: "0", color: .green)
                        securityMetric(label: "Warnings", value: "\(keyService.keys.filter { !$0.isRevoked && $0.lastUsedAt == nil }.count)", color: .orange)
                        securityMetric(label: "Critical", value: "0", color: .red)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Security Audit Log").font(.headline)
                    let securityLogs = logService.logEntries.filter { $0.category == .authentication }
                    if securityLogs.isEmpty {
                        Text("No security events recorded.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(securityLogs.prefix(5)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.message).font(.subheadline.bold())
                                    Spacer()
                                    Text(entry.timestamp.formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
                                }
                                Text("Source: \(entry.source.component)").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommendations").font(.headline)
                    if keyService.keys.contains(where: { !$0.isRevoked && $0.createdAt.timeIntervalSinceNow < -90*24*3600 }) {
                        recommendationCard(title: "Rotate API Keys", detail: "One or more API keys haven't been rotated in over 90 days.")
                    }
                    recommendationCard(title: "Review Scopes", detail: "Ensure your apps only have the minimum necessary permissions.")
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Security Audit")
    }

    private func securityMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func recommendationCard(title: String, detail: String) -> some View {
        HStack {
            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
