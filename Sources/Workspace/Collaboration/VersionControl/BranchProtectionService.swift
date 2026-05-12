import Foundation
import Combine

/// Defines rules for branch protection.
struct BranchProtectionRule: Codable, Identifiable, Sendable {
    let id: UUID
    var branchName: String
    var requireApprovals: Bool
    var requiredApprovalCount: Int
    var restrictMerges: Bool
    var allowedRoles: [SpaceRole]
}

/// Service for managing and enforcing branch protection rules.
final class BranchProtectionService: ObservableObject {
    static let shared = BranchProtectionService()

    @Published var rules: [UUID: [BranchProtectionRule]] = [:] // spaceID: rules

    private init() {}

    func addRule(spaceID: UUID, rule: BranchProtectionRule) {
        if rules[spaceID] != nil {
            rules[spaceID]?.append(rule)
        } else {
            rules[spaceID] = [rule]
        }
    }

    func canMerge(spaceID: UUID, branchName: String, userRole: SpaceRole, approvalCount: Int) -> Bool {
        guard let spaceRules = rules[spaceID],
              let rule = spaceRules.first(where: { $0.branchName == branchName }) else { return true }

        if rule.requireApprovals && approvalCount < rule.requiredApprovalCount {
            return false
        }

        if rule.restrictMerges && !rule.allowedRoles.contains(userRole) {
            return false
        }

        return true
    }
}
