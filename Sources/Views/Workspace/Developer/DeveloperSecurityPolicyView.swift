import SwiftUI

struct DeveloperSecurityPolicyView: View {
    @ObservedObject var policyService = SecurityPolicyService.shared

    var body: some View {
        List {
            Section("Security Compliance") {
                if policyService.policies.isEmpty {
                    EmptyStateView(icon: "shield.checkered", title: "No Policies", message: "Configure security policies to audit your infrastructure compliance.")
                } else {
                    ForEach(policyService.policies) { policy in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(policy.name).font(.subheadline.bold())
                                Text(policy.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: policy.isCompliant ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(policy.isCompliant ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Security Policies")
    }
}
