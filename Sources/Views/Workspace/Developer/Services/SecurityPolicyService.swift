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
        let updatedPolicies = current
        await MainActor.run { self.policies = updatedPolicies }
    }
    public func deletePolicy(id: UUID) async throws {
        var current = store.securityPolicies
        current.removeAll { $0.id == id }
        store.saveSecurityPolicies(current)
        let updatedPolicies = current
        await MainActor.run { self.policies = updatedPolicies }
    }

    public func syncPolicies() async throws {
        let defaultPolicies = [
            SecurityPolicy(name: "SSL Enforcement", description: "All endpoints must use TLS 1.3", isCompliant: true),
            SecurityPolicy(name: "Data Encryption", description: "At-rest encryption for all databases", isCompliant: true),
            SecurityPolicy(name: "Access Control", description: "MFA required for administrative access", isCompliant: false)
        ]
        store.saveSecurityPolicies(defaultPolicies)
        await MainActor.run { self.policies = defaultPolicies }
    }
}
