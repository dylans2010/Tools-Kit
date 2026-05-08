import SwiftUI

struct PresetConnectorsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ConnectorManager.shared
    @State private var selectedProvider: PresetConnectorProvider = .openAI
    @State private var apiKey = ""
    @State private var displayName = ""
    @State private var showingValidation = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(PresetConnectorProvider.allCases) { provider in
                            Label(provider.name, systemImage: provider.icon).tag(provider)
                        }
                    }

                    providerSummary(selectedProvider)
                } header: {
                    Text("Provider")
                }

                Section {
                    TextField("Display Name", text: $displayName)
                    SecureField(selectedProvider.secretLabel, text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text(selectedProvider.credentialHelp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Credentials")
                }

                Section {
                    ForEach(selectedProvider.endpoints) { endpoint in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(endpoint.method)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12), in: Capsule())
                                Text(endpoint.path)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                            }
                            if !endpoint.headers.isEmpty {
                                Text("Headers: \(endpoint.headers.keys.sorted().joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Configured Endpoints")
                }

                Section {
                    Button {
                        addPreset()
                    } label: {
                        Label("Add \(selectedProvider.name)", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedProvider) { _, provider in
                displayName = provider.name
                apiKey = ""
            }
            .onAppear {
                if displayName.isEmpty { displayName = selectedProvider.name }
            }
            .alert("Preset Connector", isPresented: $showingValidation) {
                Button("OK") {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    private func providerSummary(_ provider: PresetConnectorProvider) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(provider.name, systemImage: provider.icon)
                .font(.headline)
            Text(provider.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(provider.baseURL)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func addPreset() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            validationMessage = "Enter a valid \(selectedProvider.secretLabel)."
            showingValidation = true
            return
        }

        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedProvider.name : displayName
        let id = UUID()
        let connector = ConnectorDefinition(
            id: id,
            name: name,
            identifier: uniqueIdentifier(for: selectedProvider),
            version: "1.0.0",
            description: selectedProvider.description,
            status: .active,
            endpoints: selectedProvider.endpoints,
            authConfig: selectedProvider.authConfig(secret: trimmedKey),
            schema: ConnectorSchema(mappings: selectedProvider.schemaMappings, jsonSchema: selectedProvider.jsonSchema),
            flow: ConnectorFlow(steps: selectedProvider.defaultFlowSteps)
        )

        manager.addConnector(connector)
        ConnectorAuthManager.shared.secureStore(key: selectedProvider.secretStorageKey, value: trimmedKey, connectorID: id)
        manager.addLog(ConnectorLog(connectorID: id, timestamp: Date(), type: .info, message: "Preset connector added for \(selectedProvider.name)", details: "\(selectedProvider.endpoints.count) live endpoint(s) configured"))
        dismiss()
    }

    private func uniqueIdentifier(for provider: PresetConnectorProvider) -> String {
        let base = "com.toolskit.preset.\(provider.rawValue)"
        if !manager.connectors.contains(where: { $0.identifier == base }) { return base }
        return "\(base).\(Int(Date().timeIntervalSince1970))"
    }
}

enum PresetConnectorProvider: String, CaseIterable, Identifiable {
    case openAI
    case gemini
    case github
    case anthropic
    case mistral
    case notion
    case slack
    case stripe

    var id: String { rawValue }

    var name: String {
        switch self {
        case .openAI: return "ChatGPT / OpenAI"
        case .gemini: return "Gemini"
        case .github: return "GitHub"
        case .anthropic: return "Anthropic Claude"
        case .mistral: return "Mistral AI"
        case .notion: return "Notion"
        case .slack: return "Slack"
        case .stripe: return "Stripe"
        }
    }

    var icon: String {
        switch self {
        case .openAI, .gemini, .anthropic, .mistral: return "sparkles"
        case .github: return "terminal.fill"
        case .notion: return "doc.richtext"
        case .slack: return "bubble.left.and.bubble.right.fill"
        case .stripe: return "creditcard.fill"
        }
    }

    var description: String {
        switch self {
        case .openAI: return "Connect to OpenAI's production API for models and chat completions."
        case .gemini: return "Connect to Google's Gemini API for model discovery and generation."
        case .github: return "Connect to GitHub REST APIs for authenticated user and repository data."
        case .anthropic: return "Connect to Anthropic's Messages API for Claude model workflows."
        case .mistral: return "Connect to Mistral AI for model listing and chat completions."
        case .notion: return "Connect to Notion's API for users, pages, and database automation."
        case .slack: return "Connect to Slack Web API for workspace identity and channel data."
        case .stripe: return "Connect to Stripe's API for account, customer, and payment data."
        }
    }

    var baseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .github: return "https://api.github.com"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .mistral: return "https://api.mistral.ai/v1"
        case .notion: return "https://api.notion.com/v1"
        case .slack: return "https://slack.com/api"
        case .stripe: return "https://api.stripe.com/v1"
        }
    }

    var secretLabel: String {
        switch self {
        case .github: return "Personal access token"
        case .slack: return "Bot token"
        default: return "API key"
        }
    }

    var credentialHelp: String {
        "The key is stored for this connector and sent only to \(baseURL)."
    }

    var secretStorageKey: String {
        switch authType {
        case .apiKey: return "apiKey"
        case .bearer: return "token"
        case .oauth2, .none: return "apiKey"
        }
    }

    private var authType: ConnectorAuthConfig.AuthType {
        switch self {
        case .openAI, .github, .mistral, .notion, .slack, .stripe: return .bearer
        case .gemini, .anthropic: return .apiKey
        }
    }

    func authConfig(secret: String) -> ConnectorAuthConfig {
        switch self {
        case .gemini:
            return ConnectorAuthConfig(type: .apiKey, credentials: ["headerName": "x-goog-api-key", "apiKey": secret])
        case .anthropic:
            return ConnectorAuthConfig(type: .apiKey, credentials: ["headerName": "x-api-key", "apiKey": secret])
        default:
            return ConnectorAuthConfig(type: .bearer, credentials: ["token": secret])
        }
    }

    var endpoints: [ConnectorEndpoint] {
        switch self {
        case .openAI:
            return [
                endpoint("/models", method: "GET"),
                endpoint("/chat/completions", method: "POST", headers: ["Content-Type": "application/json"])
            ]
        case .gemini:
            return [
                endpoint("/models", method: "GET"),
                endpoint("/models/gemini-1.5-flash:generateContent", method: "POST", headers: ["Content-Type": "application/json"])
            ]
        case .github:
            return [
                endpoint("/user", method: "GET", headers: ["Accept": "application/vnd.github+json"]),
                endpoint("/user/repos?sort=updated&per_page=20", method: "GET", headers: ["Accept": "application/vnd.github+json"])
            ]
        case .anthropic:
            return [
                endpoint("/models", method: "GET", headers: ["anthropic-version": "2023-06-01"]),
                endpoint("/messages", method: "POST", headers: ["Content-Type": "application/json", "anthropic-version": "2023-06-01"])
            ]
        case .mistral:
            return [endpoint("/models", method: "GET"), endpoint("/chat/completions", method: "POST", headers: ["Content-Type": "application/json"])]
        case .notion:
            return [endpoint("/users", method: "GET", headers: ["Notion-Version": "2022-06-28"]), endpoint("/search", method: "POST", headers: ["Content-Type": "application/json", "Notion-Version": "2022-06-28"])]
        case .slack:
            return [endpoint("/auth.test", method: "GET"), endpoint("/conversations.list", method: "GET")]
        case .stripe:
            return [endpoint("/account", method: "GET"), endpoint("/customers?limit=10", method: "GET")]
        }
    }

    var schemaMappings: [String: String] {
        ["provider": rawValue, "baseURL": baseURL, "auth": authType.rawValue]
    }

    var jsonSchema: String {
        """
        {"type":"object","properties":{"provider":{"const":"\(rawValue)"},"baseURL":{"const":"\(baseURL)"}}}
        """
    }

    var defaultFlowSteps: [FlowStep] {
        [
            FlowStep(type: .trigger, config: ["event": "manual.test", "provider": rawValue]),
            FlowStep(type: .action, config: ["endpoint": endpoints.first?.path ?? baseURL, "method": endpoints.first?.method ?? "GET"])
        ]
    }

    private func endpoint(_ path: String, method: String, headers: [String: String] = [:]) -> ConnectorEndpoint {
        ConnectorEndpoint(path: baseURL + path, method: method, headers: headers, queryParams: [:])
    }
}
