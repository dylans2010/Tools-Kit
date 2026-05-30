import Foundation

public class SecurityPolicyService: ObservableObject {
    public static let shared = SecurityPolicyService()
    private let store = DeveloperPersistentStore.shared

    @Published public var policies: [SecurityPolicy] = []

    private init() { loadPolicies() }

    public func loadPolicies() { self.policies = store.securityPolicies }

    public func updatePolicy(_ policy: SecurityPolicy) async throws {
        var current = store.securityPolicies
        if let index = current.firstIndex(where: { $0.id == policy.id }) {
            current[index] = policy
        } else {
            current.append(policy)
        }
        store.saveSecurityPolicies(current)
        await MainActor.run { self.policies = current }
    }
}
