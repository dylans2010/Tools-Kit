import SwiftUI

struct BranchSettingsView: View {
    let spaceID: UUID
    @StateObject private var protectionService = BranchProtectionService.shared
    @State private var showingAddRule = false

    var body: some View {
        List {
            Section("Protection Rules") {
                if let rules = protectionService.rules[spaceID], !rules.isEmpty {
                    ForEach(rules) { rule in
                        VStack(alignment: .leading) {
                            Text(rule.branchName)
                                .font(.headline)
                            if rule.requireApprovals {
                                Text("Requires \(rule.requiredApprovalCount) Approvals")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                } else {
                    Text("No Protection Rules Defined")
                        .foregroundColor(.secondary)
                }
            }

            Button("Add Protection Rule") {
                showingAddRule = true
            }
        }
        .navigationTitle("Branch Protection")
        .sheet(isPresented: $showingAddRule) {
            AddProtectionRuleView(spaceID: spaceID)
        }
    }
}

struct AddProtectionRuleView: View {
    let spaceID: UUID
    @Environment(\.dismiss) var dismiss
    @State private var branchName = "main"
    @State private var requireApprovals = true
    @State private var requiredApprovalCount = 1

    var body: some View {
        NavigationStack {
            Form {
                TextField("Branch Name", text: $branchName)
                Toggle("Require Approvals", isOn: $requireApprovals)
                if requireApprovals {
                    Stepper("Required Count: \(requiredApprovalCount)", value: $requiredApprovalCount, in: 1...5)
                }
            }
            .navigationTitle("New Rule")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let rule = BranchProtectionRule(
                            id: UUID(),
                            branchName: branchName,
                            requireApprovals: requireApprovals,
                            requiredApprovalCount: requiredApprovalCount,
                            restrictMerges: false,
                            allowedRoles: [.admin, .owner]
                        )
                        BranchProtectionService.shared.addRule(spaceID: spaceID, rule: rule)
                        dismiss()
                    }
                }
            }
        }
    }
}
