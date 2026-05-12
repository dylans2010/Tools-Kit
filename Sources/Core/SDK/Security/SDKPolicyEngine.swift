import Foundation

public struct SDKSecurityScopeDefinition: Codable, Hashable, Sendable {
    public enum RiskLevel: String, Codable, CaseIterable, Sendable {
        case low, medium, high, critical
    }

    public let name: String
    public let description: String
    public let riskLevel: RiskLevel
    public let requiresJustification: Bool
    public let runtimeValidationHook: String?
}

public struct SDKPolicyRequest: Sendable {
    public let operationName: String
    public let scope: String
    public let projectID: UUID?
    public let appID: UUID?
    public let actorID: String
    public let apiKey: String?
    public let allowedScopes: Set<String>
    public let justification: String?
    public let privacyNote: String?

    public init(
        operationName: String,
        scope: String,
        projectID: UUID?,
        appID: UUID? = nil,
        actorID: String,
        apiKey: String?,
        allowedScopes: Set<String>,
        justification: String?,
        privacyNote: String?
    ) {
        self.operationName = operationName
        self.scope = scope
        self.projectID = projectID
        self.appID = appID
        self.actorID = actorID
        self.apiKey = apiKey
        self.allowedScopes = allowedScopes
        self.justification = justification
        self.privacyNote = privacyNote
    }
}

public struct SDKPolicyDecision: Sendable {
    public let scopeDefinition: SDKSecurityScopeDefinition
    public let rateRule: SDKRateLimiter.Rule
}

@MainActor
public final class SDKPolicyEngine: ObservableObject {
    public static let shared = SDKPolicyEngine()

    @Published public private(set) var scopeDefinitions: [String: SDKSecurityScopeDefinition] = [:]

    private let privacyManager = SDKPrivacyManager.shared

    private init() {
        registerDefaultScopes()
    }

    public func registerScope(_ definition: SDKSecurityScopeDefinition) {
        scopeDefinitions[definition.name] = definition
    }

    public func availableScopes() -> [SDKSecurityScopeDefinition] {
        scopeDefinitions.values.sorted { $0.name < $1.name }
    }

    public func evaluate(_ request: SDKPolicyRequest) throws -> SDKPolicyDecision {
        let definition = scopeDefinitions[request.scope] ?? SDKSecurityScopeDefinition(
            name: request.scope,
            description: "Custom scope",
            riskLevel: .medium,
            requiresJustification: false,
            runtimeValidationHook: nil
        )

        if definition.requiresJustification,
           (request.justification?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            throw SDKError.validationError(reason: "Justification required for scope: \(request.scope)")
        }

        try privacyManager.validatePrivacyNote(scope: request.scope, note: request.privacyNote)

        let rateRule = rule(for: definition)
        return SDKPolicyDecision(scopeDefinition: definition, rateRule: rateRule)
    }

    private func rule(for definition: SDKSecurityScopeDefinition) -> SDKRateLimiter.Rule {
        switch definition.riskLevel {
        case .low:
            return .init(requestsPerMinute: 180, dataFetchLimit: 5000, executionFrequencyCap: 180)
        case .medium:
            return .init(requestsPerMinute: 120, dataFetchLimit: 2500, executionFrequencyCap: 120)
        case .high:
            return .init(requestsPerMinute: 60, dataFetchLimit: 1000, executionFrequencyCap: 60)
        case .critical:
            return .init(requestsPerMinute: 30, dataFetchLimit: 500, executionFrequencyCap: 30)
        }
    }

    private func registerDefaultScopes() {
        registerScope(.init(
            name: "sdk.fetchData.full",
            description: "Full workspace data access",
            riskLevel: .high,
            requiresJustification: true,
            runtimeValidationHook: "audit.log.required"
        ))

        registerScope(.init(
            name: "external.api.unrestricted",
            description: "Unrestricted outbound API access",
            riskLevel: .critical,
            requiresJustification: true,
            runtimeValidationHook: "monitor.outbound.requests"
        ))

        registerScope(.init(
            name: "workspace.modify.bulk",
            description: "Mass workspace modification",
            riskLevel: .high,
            requiresJustification: true,
            runtimeValidationHook: "rate.limit.bulk.operations"
        ))

        for scope in SDKScope.allCases {
            let name = "workspace.\(String(describing: scope))"
            if scopeDefinitions[name] == nil {
                registerScope(.init(
                    name: name,
                    description: "Workspace scope \(scope)",
                    riskLevel: .medium,
                    requiresJustification: false,
                    runtimeValidationHook: nil
                ))
            }
        }
    }
}
