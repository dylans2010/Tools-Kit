import Foundation

public struct SDKDependencyScopeValidator {
    public init() {}

    public func validate(dependencies: [SDKDependencyNode], grantedScopes: Set<String>) throws {
        let missing = dependencies
            .flatMap { $0.requiredScopes }
            .filter { !grantedScopes.contains($0) && !grantedScopes.contains("*") }

        guard missing.isEmpty else {
            throw SDKError.permissionDenied(scope: Set(missing).sorted().joined(separator: ","))
        }
    }
}
