import SwiftUI

struct DeveloperSecurityPolicyView: View {
    @ObservedObject var policyService = SecurityPolicyService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    var body: some View {
        List {
            Section("Infrastructure Compliance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Automated security policies continuously audit your registered infrastructure and application configuration to ensure compliance with enterprise standards.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Active Policies") {
                if policyService.policies.isEmpty {
                    EmptyStateView(icon: "shield.checkered", title: "No Policies", message: "Register security rules to start auditing your fleet for compliance risks.")
                } else {
                    ForEach(policyService.policies) { policy in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(policy.name).font(.subheadline.bold())
                                    Text(policy.description).font(.system(size: 9)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                statusIndicator(isCompliant: policy.isCompliant)
                            }

                            if !policy.isCompliant {
                                Text("Remediation required to satisfy enterprise security standards.")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Policy Management") {
                Button { /* sync policies */ } label: { Label("Sync Global Policies", systemImage: "arrow.triangle.2.circlepath") }
                Button { /* audit report */ } label: { Label("Generate Compliance PDF", systemImage: "doc.text.fill") }
            }
        }
        .navigationTitle("Security Policies")
    }

    private func statusIndicator(isCompliant: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isCompliant ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            Text(isCompliant ? "COMPLIANT" : "NON-COMPLIANT")
        }
        .font(.system(size: 8, weight: .black))
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(isCompliant ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .foregroundStyle(isCompliant ? .green : .red)
        .clipShape(Capsule())
    }
}
