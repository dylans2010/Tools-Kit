
import SwiftUI

struct SDKComplianceAuditView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var findings: [String] = []

    var body: some View {
        List {
            Section("Security Audit Scan") {
                if findings.isEmpty {
                    Text("No findings. Run scan to begin.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(findings, id: \.self) { finding in
                        Label(finding, systemImage: "exclamationmark.shield").font(.caption)
                    }
                }
            }

            Button("Execute Security Audit") { runAudit() }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Compliance")
    }

    private func runAudit() {
        guard let project = projectManager.currentProject else { return }
        var result: [String] = []

        if project.enabledScopes.contains("external.api.unrestricted") {
            result.append("High Risk: Unrestricted API access enabled.")
        }
        if project.ownerIdentifier == "unregistered" {
            result.append("Warning: Project owner not verified.")
        }
        if project.enabledScopes.count > 10 {
            result.append("Advice: Large number of scopes requested. Review necessity.")
        }

        if result.isEmpty {
            result.append("No critical compliance issues found for current configuration.")
        }

        findings = result
    }
}
