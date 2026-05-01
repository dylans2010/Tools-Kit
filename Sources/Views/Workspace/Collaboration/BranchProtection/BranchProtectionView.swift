import SwiftUI

struct BranchProtectionView: View {
    @StateObject private var protectionManager = BranchProtectionManager.shared
    let branchID: UUID
    let branchName: String

    @State private var rules = BranchProtectionRules()

    var body: some View {
        Form {
            Section(header: Text("Protection Rules for '\(branchName)'")) {
                Toggle("Require Pull Request Approvals", isOn: $rules.requireApprovals)

                if rules.requireApprovals {
                    Stepper("Required Approvals: \(rules.requiredApprovalCount)", value: $rules.requiredApprovalCount, in: 1...10)
                    Toggle("Dismiss Stale Reviews", isOn: $rules.dismissStaleReviews)
                }

                Toggle("Require Status Checks", isOn: $rules.requireStatusChecks)
            }

            Section(header: Text("Merge Restrictions")) {
                Text("Restrict who can merge to this branch")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(SpaceRole.allCases, id: \.self) { role in
                    Toggle(role.rawValue, isOn: roleBinding(role))
                }
            }

            Section {
                Button("Save Rules") {
                    protectionManager.setRules(for: branchID, rules: rules)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            if let existing = protectionManager.protectionMap[branchID] {
                rules = existing
            }
        }
        .navigationTitle("Branch Protection")
    }

    private func roleBinding(_ role: SpaceRole) -> Binding<Bool> {
        Binding(
            get: { rules.restrictMergesToRoles.contains(role) },
            set: { isSelected in
                if isSelected {
                    rules.restrictMergesToRoles.append(role)
                } else {
                    rules.restrictMergesToRoles.removeAll { $0 == role }
                }
            }
        )
    }
}

extension SpaceRole: CaseIterable {
    public static var allCases: [SpaceRole] {
        return [.owner, .admin, .editor, .commenter, .viewer]
    }
}
