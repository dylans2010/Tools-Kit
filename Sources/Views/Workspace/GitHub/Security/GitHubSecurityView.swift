import SwiftUI

struct GitHubSecurityView: View {
    @State private var alerts: [SecurityAlert] = []
    @State private var selectedSeverity: AlertSeverity?

    var filteredAlerts: [SecurityAlert] {
        if let severity = selectedSeverity {
            return alerts.filter { $0.severity == severity }
        }
        return alerts
    }

    var body: some View {
        List {
            Section("Security Overview") {
                HStack(spacing: 16) {
                    severityCard(severity: .critical, count: alerts.count(where: { $0.severity == .critical }))
                    severityCard(severity: .high, count: alerts.count(where: { $0.severity == .high }))
                    severityCard(severity: .medium, count: alerts.count(where: { $0.severity == .medium }))
                    severityCard(severity: .low, count: alerts.count(where: { $0.severity == .low }))
                }
            }

            Section {
                Picker("Filter", selection: $selectedSeverity) {
                    Text("All").tag(Optional<AlertSeverity>.none)
                    ForEach(AlertSeverity.allCases, id: \.self) { s in
                        Text(s.rawValue.capitalized).tag(Optional(s))
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Security Alerts (\(filteredAlerts.count))") {
                ForEach(filteredAlerts) { alert in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(alert.severity.color)
                            Text(alert.title)
                                .font(.subheadline.bold())
                        }
                        Text(alert.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        HStack {
                            Text(alert.severity.rawValue.uppercased())
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(alert.severity.color.opacity(0.15))
                                .foregroundStyle(alert.severity.color)
                                .clipShape(Capsule())
                            if let pkg = alert.affectedPackage {
                                Text(pkg)
                                    .font(.caption.monospaced())
                            }
                            Spacer()
                            Text(alert.detectedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let fix = alert.fixAvailable {
                            HStack {
                                Image(systemName: "wrench")
                                Text("Fix: \(fix)")
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Security")
        .task { loadAlerts() }
    }

    private func severityCard(severity: AlertSeverity, count: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(severity.color)
            Text(severity.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadAlerts() {
        alerts = [
            SecurityAlert(title: "Remote Code Execution in dependency", severity: .critical, description: "A critical vulnerability was found in a transitive dependency allowing arbitrary code execution.", affectedPackage: "libxml2 2.9.10", fixAvailable: "Update to 2.9.14", detectedAt: Date().addingTimeInterval(-86400)),
            SecurityAlert(title: "Cross-site scripting in web view", severity: .high, description: "WebView component does not properly sanitize HTML input from untrusted sources.", affectedPackage: nil, fixAvailable: "Apply input sanitization", detectedAt: Date().addingTimeInterval(-172800)),
            SecurityAlert(title: "Insecure TLS configuration", severity: .medium, description: "Network client allows TLS 1.0 connections which are considered insecure.", affectedPackage: "URLSession", fixAvailable: "Set minimum TLS to 1.2", detectedAt: Date().addingTimeInterval(-259200)),
            SecurityAlert(title: "Deprecated hash algorithm", severity: .low, description: "SHA-1 is used for non-critical checksums. Consider upgrading to SHA-256.", affectedPackage: nil, fixAvailable: nil, detectedAt: Date().addingTimeInterval(-345600)),
        ]
    }
}

private struct SecurityAlert: Identifiable {
    let id = UUID()
    let title: String
    let severity: AlertSeverity
    let description: String
    let affectedPackage: String?
    let fixAvailable: String?
    let detectedAt: Date
}

private enum AlertSeverity: String, CaseIterable {
    case critical, high, medium, low

    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}
