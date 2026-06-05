import SwiftUI

struct DeveloperSecurityPolicyView: View {
    @ObservedObject var policyService = SecurityPolicyService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Infrastructure Compliance")
                                .font(.headline)
                            Text("Automated security policies continuously audit your registered infrastructure and application configuration to ensure compliance with enterprise standards.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Active Policies")
                                .font(.headline)

                            if policyService.policies.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "shield.checkered")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("No Policies")
                                        .font(.headline)
                                    Text("Register security rules to start auditing your fleet for compliance risks.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 40)
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

                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Policy Management")
                                .font(.headline)

                            Button {
                                Task {
                                    try? await policyService.syncPolicies()
                                }
                            } label: {
                                HStack {
                                    Label("Sync Global Policies", systemImage: "arrow.triangle.2.circlepath")
                                    Spacer()
                                }
                                .padding()
                            }

                            Button {
                                let event = DeveloperActivityEvent(eventType: .appUpdated, sourceAppName: "Security Report Generated")
                                DeveloperPersistentStore.shared.activities.append(event)
                            } label: {
                                HStack {
                                    Label("Generate Compliance PDF", systemImage: "doc.text.fill")
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Security Policies")
        }
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
