import Foundation

/// Defines rules for branch protection.
struct BranchProtectionRules: Codable {
    var requireApprovals: Bool = false
    var requiredApprovalCount: Int = 1
    var dismissStaleReviews: Bool = false
    var requireStatusChecks: Bool = false // e.g., validation logic
    var restrictMergesToRoles: [SpaceRole] = [.owner, .admin]
}

/// Manages branch protection rules for Collaboration Spaces.
final class BranchProtectionManager: ObservableObject {
    static let shared = BranchProtectionManager()

    @Published var protectionMap: [UUID: BranchProtectionRules] = [:] // BranchID: Rules
    private let storageKey = "com.tools-kit.collaboration.protection"

    private init() {
        loadRules()
    }

    func setRules(for branchID: UUID, rules: BranchProtectionRules) {
        protectionMap[branchID] = rules
        saveRules()
    }

    func canMerge(branchID: UUID, approvals: Int, userRole: SpaceRole) -> Bool {
        guard let rules = protectionMap[branchID] else { return true }

        if rules.requireApprovals && approvals < rules.requiredApprovalCount {
            return false
        }

        if !rules.restrictMergesToRoles.contains(userRole) {
            return false
        }

        return true
    }

    private func saveRules() {
        if let encoded = try? JSONEncoder().encode(protectionMap) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadRules() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([UUID: BranchProtectionRules].self, from: data) {
            protectionMap = decoded
        }
    }
}
