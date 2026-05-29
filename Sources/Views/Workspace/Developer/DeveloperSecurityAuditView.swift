import SwiftUI

struct DeveloperSecurityAuditView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Security Health").font(.headline)
                    HStack(spacing: 12) {
                        securityMetric(label: "Vulnerabilities", value: "0", color: .green)
                        securityMetric(label: "Warnings", value: "2", color: .orange)
                        securityMetric(label: "Critical", value: "0", color: .red)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Audit Log").font(.headline)
                    ForEach(0..<5) { i in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(i % 2 == 0 ? "Key Access" : "Scope Change").font(.subheadline.bold())
                                Spacer()
                                Text(Date().addingTimeInterval(Double(-i * 3600)).formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Text("A developer key was used to access the '/user' endpoint from IP 192.168.1.1").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommendations").font(.headline)
                    recommendationCard(title: "Rotate API Keys", detail: "Your primary API key hasn't been rotated in 90 days.")
                    recommendationCard(title: "Reduce Scopes", detail: "Your app 'GitHub Pro' has 'write:user' scope but hasn't used it recently.")
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
