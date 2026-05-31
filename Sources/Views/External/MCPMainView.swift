import SwiftUI

struct MCPMainView: View {
    @StateObject private var mcpManager = MCPManager.shared
    @State private var showingAddServer = false

    var body: some View {
        NavigationStack {
            List {
                if mcpManager.servers.isEmpty {
                    MCPEmptyStateView {
                        showingAddServer = true
                    }
                } else {
                    ForEach(mcpManager.servers) { server in
                        NavigationLink(destination: MCPServerDetailView(server: server)) {
                            MCPServerRowView(server: server)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            mcpManager.removeServer(id: mcpManager.servers[index].id)
                        }
                    }
                }
            }
            .navigationTitle("MCP Servers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddServer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                MCPAddServerView()
            }
        }
    }
}

// MARK: - Subviews

struct MCPServerRowView: View {
    let server: MCPServer

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(server.connectionStatus.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.headline)
                Text(server.baseURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if server.connectionStatus == .connected {
                Text("\(server.discoveredTools.count) tools")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1), in: Capsule())
            }
        }
    }
}

struct MCPServerDetailView: View {
    @State var server: MCPServer
    @ObservedObject private var mcpManager = MCPManager.shared
    @State private var isConnecting = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Base URL", text: $server.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                HStack {
                    Text("Status")
                    Spacer()
                    Text(server.connectionStatus.label)
                        .foregroundStyle(server.connectionStatus.color)
                        .bold()
                }

                if let lastError = server.lastError {
                    Text(lastError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                HStack(spacing: 12) {
                    if server.connectionStatus == .connected {
                        Button("Disconnect") {
                            mcpManager.disconnect(server: server)
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button("Connect") {
                            Task {
                                isConnecting = true
                                try? await mcpManager.connect(to: server)
                                isConnecting = false
                            }
                        }
                        .disabled(isConnecting)
                    }

                    if isConnecting {
                        ProgressView()
                    }

                    Spacer()

                    Button("Test Connection") {
                        Task {
                            do {
                                let info = try await mcpManager.testConnection(server: server)
                                testResult = "Success: \(info.name) v\(info.version)"
                            } catch {
                                testResult = "Failed: \(error.localizedDescription)"
                            }
                        }
                    }
                    .font(.subheadline)
                }

                if let testResult = testResult {
                    Text(testResult)
                        .font(.caption)
                        .foregroundStyle(testResult.hasPrefix("Success") ? .green : .red)
                }
            }

            Section("Authentication") {
                Picker("Auth Type", selection: $server.authConfig.type) {
                    ForEach(MCPAuthType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: server.authConfig.type) { _, _ in
                    mcpManager.updateServer(server)
                }

                MCPAuthFormView(server: $server)

                MCPAuthGuideView(type: server.authConfig.type)
            }

            if server.connectionStatus == .connected {
                Section("Discovered Tools") {
                    if server.discoveredTools.isEmpty {
                        Text("No tools found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(server.discoveredTools) { tool in
                            MCPToolRowView(tool: tool)
                        }
                    }

                    Button("Refresh Tools") {
                        Task {
                            try? await mcpManager.connect(to: server)
                        }
                    }
                }
            }

            Section("Server Notes") {
                TextEditor(text: $server.notes)
                    .frame(minHeight: 100)
                    .onChange(of: server.notes) { _, _ in
                        mcpManager.updateServer(server)
                    }
            }

            Section {
                Button("Remove Server", role: .destructive) {
                    mcpManager.removeServer(id: server.id)
                }
            }
        }
        .navigationTitle(server.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    mcpManager.updateServer(server)
                }
            }
        }
    }
}

struct MCPAuthFormView: View {
    @Binding var server: MCPServer
    @ObservedObject private var mcpManager = MCPManager.shared

    @State private var secretInput: String = ""
    @State private var clientSecretInput: String = ""

    var body: some View {
        Group {
            switch server.authConfig.type {
            case .none:
                Text("No configuration required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .apiKey:
                TextField("Header Name", text: $server.authConfig.apiKeyHeaderName)
                SecureField("API Key", text: $secretInput)
                Button("Save Key") {
                    mcpManager.saveSecret(secretInput, key: "apiKey", for: server)
                    secretInput = ""
                }

            case .bearerToken:
                SecureField("Token", text: $secretInput)
                TextField("Refresh Endpoint (Optional)", text: $server.authConfig.tokenEndpoint)
                Button("Save Token") {
                    mcpManager.saveSecret(secretInput, key: "bearerToken", for: server)
                    secretInput = ""
                }

            case .basicAuth:
                TextField("Username", text: $server.authConfig.username)
                SecureField("Password", text: $secretInput)
                Button("Save Credentials") {
                    mcpManager.saveSecret(secretInput, key: "password", for: server)
                    secretInput = ""
                }

            case .oauth2AuthCode:
                TextField("Auth Endpoint", text: $server.authConfig.authorizationEndpoint)
                TextField("Token Endpoint", text: $server.authConfig.tokenEndpoint)
                TextField("Client ID", text: $server.authConfig.clientId)
                TextField("Scopes", text: $server.authConfig.scopes)
                Button("Start OAuth Flow") {
                    Task {
                        try? await mcpManager.performOAuth2PKCE(server: server)
                    }
                }

            case .oauth2ClientCredentials:
                TextField("Token Endpoint", text: $server.authConfig.tokenEndpoint)
                TextField("Client ID", text: $server.authConfig.clientId)
                SecureField("Client Secret", text: $clientSecretInput)
                Button("Save Secret") {
                    mcpManager.saveSecret(clientSecretInput, key: "clientSecret", for: server)
                    clientSecretInput = ""
                }

            case .customHeaders:
                VStack(alignment: .leading) {
                    ForEach(0..<server.authConfig.customHeaderKeys.count, id: \.self) { index in
                        HStack {
                            TextField("Key", text: $server.authConfig.customHeaderKeys[index])
                            TextField("Value", text: $server.authConfig.customHeaderValues[index])
                            Button {
                                server.authConfig.customHeaderKeys.remove(at: index)
                                server.authConfig.customHeaderValues.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    Button {
                        server.authConfig.customHeaderKeys.append("")
                        server.authConfig.customHeaderValues.append("")
                    } label: {
                        Label("Add Header", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .onAppear {
            if server.authConfig.type == .apiKey {
                secretInput = mcpManager.loadSecret(key: "apiKey", for: server)
            } else if server.authConfig.type == .bearerToken {
                secretInput = mcpManager.loadSecret(key: "bearerToken", for: server)
            } else if server.authConfig.type == .basicAuth {
                secretInput = mcpManager.loadSecret(key: "password", for: server)
            }
        }
    }
}

struct MCPAuthGuideView: View {
    let type: MCPAuthType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Setup Guide", systemImage: "info.circle.fill")
                .font(.headline)

            Text(type.setupGuide)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Group {
                switch type {
                case .apiKey:
                    guideItem("1", "Check service documentation for API keys.")
                    guideItem("2", "Usually 'X-API-Key' or similar header is expected.")
                case .bearerToken:
                    guideItem("1", "Generate a Personal Access Token (PAT).")
                    guideItem("2", "Paste the full token; 'Bearer' prefix is added by app.")
                case .oauth2AuthCode:
                    guideItem("1", "Register Tools-Kit as an app in your provider.")
                    guideItem("2", "Set redirect URI to toolskit://oauth/callback.")
                default:
                    EmptyView()
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    func guideItem(_ step: String, _ text: String) -> some View {
        HStack(alignment: .top) {
            Text(step).bold()
            Text(text)
        }
        .font(.caption2)
    }
}

struct MCPToolRowView: View {
    let tool: MCPTool
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(tool.name)
                            .font(.system(.body, design: .monospaced))
                            .bold()
                        Text(tool.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Input Schema")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    if let props = tool.inputSchema.properties {
                        ForEach(props.sorted(by: { $0.key < $1.key }), id: \.key) { key, prop in
                            HStack {
                                Text(key)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                Text("(\(prop.type))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                if let desc = prop.description {
                                    Text("— \(desc)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("No arguments required")
                            .font(.caption2)
                            .italic()
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MCPAddServerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var authType: MCPAuthType = .none

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Server Name", text: $name)
                    TextField("Base URL (e.g. https://.../mcp)", text: $url)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Initial Authentication") {
                    Picker("Auth Type", selection: $authType) {
                        ForEach(MCPAuthType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    Text("You can configure full credentials after adding the server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add MCP Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newServer = MCPServer(
                            name: name,
                            baseURL: url,
                            authConfig: MCPAuthConfig(type: authType)
                        )
                        MCPManager.shared.addServer(newServer)
                        dismiss()
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
        }
    }
}

struct MCPEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .padding(.top, 40)

            Text("No MCP Servers")
                .font(.title2.bold())

            Text("Connect to external services using the Model Context Protocol. You can add local or remote servers to extend the AI's capabilities.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onAdd) {
                Label("Add Your First Server", systemImage: "plus")
                    .padding()
                    .background(Color.blue, in: Capsule())
                    .foregroundStyle(.white)
                    .bold()
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
}
