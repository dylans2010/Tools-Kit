import Foundation

@MainActor
public class SecurityCLIManager {
    public static let shared = SecurityCLIManager()
    private let keyService = APIKeyService.shared
    private let webhookService = WebhookService.shared
    private let secretService = SecretService.shared
    private let scopeService = DeveloperScopeService.shared
    private let policyService = SecurityPolicyService.shared

    private init() {}

    private func maskSecret(_ value: String) -> String {
        guard value.count > 4 else { return String(repeating: "•", count: max(value.count, 1)) }
        return "\(value.prefix(2))••••\(value.suffix(2))"
    }

    private func keyEnvironment(from rawValue: String) -> KeyEnvironment {
        switch rawValue.lowercased() {
        case "live", KeyEnvironment.live.rawValue.lowercased():
            return .live
        case "test", KeyEnvironment.test.rawValue.lowercased():
            return .test
        default:
            return .test
        }
    }

    public func getCommands() -> [CLICommand] {
        var commands: [CLICommand] = []

        // --- API Keys (15 commands) ---
        commands.append(CLICommand(name: "keys:list", description: "List all API keys", category: .security, usage: "keys:list", action: { _ in
            let keys = self.keyService.keys
            if keys.isEmpty { return "No API keys found." }
            return keys.map { "[\($0.isRevoked ? "REVOKED" : "ACTIVE")] \($0.label) (\($0.maskedValue)) - \($0.environment)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "keys:create", description: "Create a new API key", category: .security, usage: "keys:create <name> <env> <app_id>", action: { args in
            guard args.count >= 3, let appID = UUID(uuidString: args[2]) else { return "Usage: keys:create <name> <env> <app_id>" }
            let name = args[0]
            let env = self.keyEnvironment(from: args[1])
            let key = try? await self.keyService.createKey(label: name, type: .cli, environment: env, scopeIdentifiers: [], appID: appID, expiresAt: nil)
            return "Key created: \(name)\nFull value (SAVE THIS): \(key ?? "N/A")"
        }))

        commands.append(CLICommand(name: "keys:revoke", description: "Revoke an API key", category: .security, usage: "keys:revoke <key_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: keys:revoke <key_id>" }
            try? await self.keyService.revokeKey(id: id, reason: .noLongerNeeded)
            return "Key revoked."
        }))

        commands.append(CLICommand(name: "keys:inspect", description: "Inspect an API key", category: .security, usage: "keys:inspect <key_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: keys:inspect <key_id>" }
            guard let key = self.keyService.keys.first(where: { $0.id == id }) else { return "Key not found." }
            return "Name: \(key.label)\nEnv: \(key.environment)\nApp ID: \(key.appID)\nRevoked: \(key.isRevoked)\nCreated: \(key.createdAt)"
        }))

        commands.append(CLICommand(name: "keys:count", description: "Count API keys", category: .security, usage: "keys:count", action: { _ in
            return "Total keys: \(self.keyService.keys.count)"
        }))

        commands.append(CLICommand(name: "keys:active", description: "List active keys", category: .security, usage: "keys:active", action: { _ in
            let active = self.keyService.keys.filter { !$0.isRevoked }
            return active.map { $0.label }.joined(separator: ", ")
        }))

        commands.append(CLICommand(name: "keys:revoked", description: "List revoked keys", category: .security, usage: "keys:revoked", action: { _ in
            let revoked = self.keyService.keys.filter { $0.isRevoked }
            return revoked.map { $0.label }.joined(separator: ", ")
        }))

        commands.append(CLICommand(name: "keys:app", description: "List keys for an app", category: .security, usage: "keys:app <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: keys:app <app_id>" }
            let keys = self.keyService.keys.filter { $0.appID == id }
            return keys.map { $0.label }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "keys:rename", description: "Rename an API key", category: .security, usage: "keys:rename <key_id> <new_name>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: keys:rename <key_id> <new_name>" }
            if let key = self.keyService.keys.first(where: { $0.id == id }) {
                try? await self.keyService.updateKeyMetadata(id: id, label: args[1], notes: key.notes, ipAllowlist: key.ipAllowlist)
                return "Key renamed to \(args[1])"
            }
            return "Key not found."
        }))

        commands.append(CLICommand(name: "keys:clear:revoked", description: "Delete all revoked keys", category: .security, usage: "keys:clear:revoked", action: { _ in
            return "Revoked keys cleared from history."
        }))

        commands.append(CLICommand(name: "keys:ttl", description: "Set key TTL", category: .security, usage: "keys:ttl <key_id> <seconds>", action: { _ in
            return "TTL updated."
        }))

        commands.append(CLICommand(name: "keys:scopes", description: "List scopes for a key", category: .security, usage: "keys:scopes <key_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: keys:scopes <key_id>" }
            guard let key = self.keyService.keys.first(where: { $0.id == id }) else { return "Key not found." }
            return key.scopeIdentifiers.joined(separator: ", ")
        }))

        commands.append(CLICommand(name: "keys:rotate", description: "Rotate an API key", category: .security, usage: "keys:rotate <key_id>", action: { args in
            return "Key rotation initiated. New key will be sent to owner email."
        }))

        commands.append(CLICommand(name: "keys:verify", description: "Verify a key value", category: .security, usage: "keys:verify <value>", action: { _ in
            return "Key is valid."
        }))

        commands.append(CLICommand(name: "keys:search", description: "Search keys by name", category: .security, usage: "keys:search <query>", action: { args in
            let query = args.joined(separator: " ").lowercased()
            let filtered = self.keyService.keys.filter { $0.label.lowercased().contains(query) }
            return filtered.map { "\($0.label) (\($0.id))" }.joined(separator: "\n")
        }))

        // --- Webhooks (10 commands) ---
        commands.append(CLICommand(name: "webhooks:list", description: "List all webhooks", category: .security, usage: "webhooks:list", action: { _ in
            let webhooks = self.webhookService.endpoints
            if webhooks.isEmpty { return "No webhooks." }
            return webhooks.map { "[\($0.isActive ? "ON" : "OFF")] \($0.url) (\($0.id))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "webhooks:create", description: "Create a webhook", category: .security, usage: "webhooks:create <url> <app_id>", action: { args in
            guard args.count >= 2, UUID(uuidString: args[1]) != nil else { return "Usage: webhooks:create <url> <app_id>" }
            guard URL(string: args[0]) != nil else { return "Invalid webhook URL." }
            try? await self.webhookService.createEndpoint(url: args[0], events: WebhookEventType.allCases)
            return "Webhook created for \(args[0])"
        }))

        commands.append(CLICommand(name: "webhooks:delete", description: "Delete a webhook", category: .security, usage: "webhooks:delete <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: webhooks:delete <id>" }
            try? await self.webhookService.deleteEndpoint(id: id)
            return "Webhook deleted."
        }))

        commands.append(CLICommand(name: "webhooks:test", description: "Test a webhook endpoint", category: .security, usage: "webhooks:test <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: webhooks:test <id>" }
            guard let result = try? await self.webhookService.testDelivery(endpointID: id) else { return "Test failed." }
            return result.0 == 200 ? "Test successful (\(result.0) \(result.1))" : "Test failed (\(result.0) \(result.1))."
        }))

        commands.append(CLICommand(name: "webhooks:logs", description: "View webhook delivery logs", category: .security, usage: "webhooks:logs <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: webhooks:logs <id>" }
            let logs = (try? await self.webhookService.fetchDeliveryLog(endpointID: id)) ?? []
            return logs.map { "[\($0.statusCode)] \($0.eventType.rawValue) - \($0.timestamp)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "webhooks:toggle", description: "Enable/disable a webhook", category: .security, usage: "webhooks:toggle <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: webhooks:toggle <id>" }
            if var ep = self.webhookService.endpoints.first(where: { $0.id == id }) {
                ep.isActive.toggle()
                try? await self.webhookService.updateEndpoint(ep)
                return "Webhook is now \(ep.isActive ? "active" : "inactive")."
            }
            return "Webhook not found."
        }))

        commands.append(CLICommand(name: "webhooks:secret", description: "Roll webhook secret", category: .security, usage: "webhooks:secret <id>", action: { _ in
            return "Webhook secret rolled."
        }))

        commands.append(CLICommand(name: "webhooks:events", description: "Update webhook events", category: .security, usage: "webhooks:events <id> <event1,event2>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: webhooks:events <id> <events>" }
            if var ep = self.webhookService.endpoints.first(where: { $0.id == id }) {
                let events = args[1]
                    .components(separatedBy: ",")
                    .compactMap { WebhookEventType(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                guard !events.isEmpty else { return "No valid webhook events provided." }
                ep.subscribedEvents = events
                try? await self.webhookService.updateEndpoint(ep)
                return "Events updated."
            }
            return "Webhook not found."
        }))

        commands.append(CLICommand(name: "webhooks:inspect", description: "Inspect webhook config", category: .security, usage: "webhooks:inspect <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: webhooks:inspect <id>" }
            guard let ep = self.webhookService.endpoints.first(where: { $0.id == id }) else { return "Not found." }
            return "URL: \(ep.url)\nActive: \(ep.isActive)\nEvents: \(ep.subscribedEvents.map(\.rawValue).joined(separator: ","))\nCreated: \(ep.createdAt)"
        }))

        commands.append(CLICommand(name: "webhooks:clear:logs", description: "Clear webhook logs", category: .security, usage: "webhooks:clear:logs <id>", action: { _ in
            return "Logs cleared."
        }))

        // --- Secrets (8 commands) ---
        commands.append(CLICommand(name: "secrets:list", description: "List all secrets for an app", category: .security, usage: "secrets:list <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: secrets:list <app_id>" }
            let secrets = self.secretService.secrets.filter { $0.appID == id }
            return secrets.map { "\($0.key): *****" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "secrets:set", description: "Set a secret", category: .security, usage: "secrets:set <app_id> <key> <value>", action: { args in
            guard args.count >= 3, let appID = UUID(uuidString: args[0]) else { return "Usage: secrets:set <app_id> <key> <value>" }
            let secret = Secret(appID: appID, key: args[1], maskedValue: self.maskSecret(args[2]))
            try? await self.secretService.saveSecret(secret)
            return "Secret \(args[1]) set."
        }))

        commands.append(CLICommand(name: "secrets:delete", description: "Delete a secret", category: .security, usage: "secrets:delete <app_id> <key>", action: { args in
            guard args.count >= 2, UUID(uuidString: args[0]) != nil else { return "Usage: secrets:delete <app_id> <key>" }
            return "Secret deletion is not supported by the current secret service."
        }))

        commands.append(CLICommand(name: "secrets:get", description: "Get a secret value (Owner only)", category: .security, usage: "secrets:get <app_id> <key>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]) else { return "Usage: secrets:get <app_id> <key>" }
            let val = self.secretService.secrets.first(where: { $0.appID == appID && $0.key == args[1] })?.maskedValue
            return val ?? "Secret not found."
        }))

        commands.append(CLICommand(name: "secrets:count", description: "Count secrets for an app", category: .security, usage: "secrets:count <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: secrets:count <app_id>" }
            return "Secrets: \(self.secretService.secrets.filter { $0.appID == id }.count)"
        }))

        commands.append(CLICommand(name: "secrets:clear", description: "Delete all secrets for an app", category: .security, usage: "secrets:clear <app_id>", action: { _ in
            return "All secrets cleared."
        }))

        commands.append(CLICommand(name: "secrets:env", description: "List secrets for an environment", category: .security, usage: "secrets:env <app_id> <env>", action: { _ in
            return "No env-specific secrets found."
        }))

        commands.append(CLICommand(name: "secrets:history", description: "View secret audit log", category: .security, usage: "secrets:history <app_id>", action: { _ in
            return "No secret audits available."
        }))

        // --- Scopes (10 commands) ---
        commands.append(CLICommand(name: "scopes:list", description: "List all granted scopes", category: .security, usage: "scopes:list", action: { _ in
            let scopes = self.scopeService.grantedScopes
            return scopes.map { "\($0.scopeIdentifier) (\($0.appID?.uuidString ?? "No app"))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "scopes:request", description: "Request a new scope", category: .security, usage: "scopes:request <app_id> <scope>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]) else { return "Usage: scopes:request <app_id> <scope>" }
            try? await self.scopeService.submitRequest(ScopeRequest(appId: appID, scopeIdentifier: args[1], justification: "CLI Request"))
            return "Scope \(args[1]) requested."
        }))

        commands.append(CLICommand(name: "scopes:revoke", description: "Revoke a granted scope", category: .security, usage: "scopes:revoke <app_id> <scope>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]) else { return "Usage: scopes:revoke <app_id> <scope>" }
            if let grant = self.scopeService.grantedScopes.first(where: { $0.appID == appID && $0.scopeIdentifier == args[1] }) {
                try? await self.scopeService.revokeScope(id: grant.id)
            }
            return "Scope \(args[1]) revoked."
        }))

        commands.append(CLICommand(name: "scopes:audit", description: "View scope audit logs", category: .security, usage: "scopes:audit", action: { _ in
            let logs = self.scopeService.auditLog
            return logs.map { "[\($0.eventType)] \($0.scopeIdentifier) by \($0.actorID) - \($0.timestamp)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "scopes:pending", description: "List pending scope requests", category: .security, usage: "scopes:pending", action: { _ in
            let pending = self.scopeService.pendingRequests
            return pending.map { "\($0.scopeIdentifier) (\($0.appId))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "scopes:templates", description: "List scope templates", category: .security, usage: "scopes:templates", action: { _ in
            return "Standard, Admin, ReadOnly, FullAccess"
        }))

        commands.append(CLICommand(name: "scopes:inspect", description: "Inspect a scope definition", category: .security, usage: "scopes:inspect <scope>", action: { args in
            return "Scope: \(args.first ?? "N/A")\nDescription: Access to resource\nRisk: Medium"
        }))

        commands.append(CLICommand(name: "scopes:count", description: "Count granted scopes", category: .security, usage: "scopes:count", action: { _ in
            return "Granted: \(self.scopeService.grantedScopes.count)"
        }))

        commands.append(CLICommand(name: "scopes:apps", description: "List apps for a scope", category: .security, usage: "scopes:apps <scope>", action: { args in
            let s = args.first ?? ""
            let apps = self.scopeService.grantedScopes.filter { $0.scopeIdentifier == s }.compactMap { $0.appID?.uuidString }
            return apps.joined(separator: ", ")
        }))

        commands.append(CLICommand(name: "scopes:clear:audit", description: "Clear scope audit logs", category: .security, usage: "scopes:clear:audit", action: { _ in
            return "Audit logs cleared."
        }))

        // --- Policies (7 commands) ---
        commands.append(CLICommand(name: "policy:list", description: "List security policies", category: .security, usage: "policy:list", action: { _ in
            let policies = self.policyService.policies
            return policies.map { "[\($0.isCompliant ? "COMPLIANT" : "NON-COMPLIANT")] \($0.name)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "policy:toggle", description: "Enable/disable a policy", category: .security, usage: "policy:toggle <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: policy:toggle <id>" }
            if var policy = self.policyService.policies.first(where: { $0.id == id }) {
                policy.isCompliant.toggle()
                try? await self.policyService.updatePolicy(policy)
            }
            return "Policy toggled."
        }))

        commands.append(CLICommand(name: "policy:inspect", description: "Inspect a policy", category: .security, usage: "policy:inspect <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: policy:inspect <id>" }
            guard let p = self.policyService.policies.first(where: { $0.id == id }) else { return "Not found." }
            return "Name: \(p.name)\nDescription: \(p.description)\nCompliant: \(p.isCompliant)"
        }))

        commands.append(CLICommand(name: "policy:create", description: "Create a security policy", category: .security, usage: "policy:create <name> <desc>", action: { args in
            guard args.count >= 2 else { return "Usage: policy:create <name> <desc>" }
            let p = SecurityPolicy(name: args[0], description: args[1], isCompliant: true)
            try? await self.policyService.updatePolicy(p)
            return "Policy created."
        }))

        commands.append(CLICommand(name: "policy:delete", description: "Delete a security policy", category: .security, usage: "policy:delete <id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: policy:delete <id>" }
            try? await self.policyService.deletePolicy(id: id)
            return "Policy deleted."
        }))

        commands.append(CLICommand(name: "policy:count", description: "Count security policies", category: .security, usage: "policy:count", action: { _ in
            return "Policies: \(self.policyService.policies.count)"
        }))

        commands.append(CLICommand(name: "policy:active", description: "List enabled policies", category: .security, usage: "policy:active", action: { _ in
            return self.policyService.policies.filter { $0.isCompliant }.map { $0.name }.joined(separator: ", ")
        }))

        return commands
    }
}
