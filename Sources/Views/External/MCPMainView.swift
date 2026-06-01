import SwiftUI

struct MCPMainView: View {
    @StateObject private var mcpManager = MCPManager.shared
    @State private var showingAddServer = false
    @State private var showingBrowseServers = false
    @State private var showingDebug = false

    var body: some View {
        NavigationStack {
            List {
                Section("Platform Health") {
                    HStack(spacing: 20) {
                        HealthMetricView(label: "Connected", value: "\(connectedCount)", color: .green)
                        HealthMetricView(label: "Latency", value: avgLatency, color: .blue)
                        HealthMetricView(label: "Tools", value: "\(totalTools)", color: .purple)
                    }
                    .padding(.vertical, 8)
                }

                Section("Connected Servers") {
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
            }
            .navigationTitle("MCP Core")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingDebug = true
                    } label: {
                        Label("Debug", systemImage: "terminal")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showingBrowseServers = true
                        } label: {
                            Label("Browse", systemImage: "safari")
                        }

                        Button {
                            showingAddServer = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                MCPAddServerView()
            }
            .sheet(isPresented: $showingBrowseServers) {
                MCPListModelsSheet { server in
                    let newServer = MCPServer(
                        name: server.name,
                        baseURL: server.url,
                        authConfig: MCPAuthConfig()
                    )
                    var updatedConfig = newServer.authConfig
                    updatedConfig.type = server.authenticationType
                    var finalServer = newServer
                    finalServer.authConfig = updatedConfig
                    mcpManager.addServer(finalServer)
                }
            }
            .sheet(isPresented: $showingDebug) {
                MCPDebugConsole()
            }
        }
    }

    private var connectedCount: Int {
        mcpManager.servers.filter { $0.connectionStatus == .connected }.count
    }

    private var totalTools: Int {
        mcpManager.toolRegistry.values.reduce(0) { $0 + $1.count }
    }

    private var avgLatency: String {
        let latencies = mcpManager.servers.compactMap { $0.latency }
        guard !latencies.isEmpty else { return "--" }
        let avg = latencies.reduce(0, +) / Double(latencies.count)
        return "\(Int(avg))ms"
    }
}

struct HealthMetricView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Subviews

struct MCPServerRowView: View {
    let server: MCPServer
    @StateObject private var mcpManager = MCPManager.shared

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(server.connectionStatus.color.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: server.connectionStatus == .connected ? "checkmark.seal.fill" : "network")
                    .font(.system(size: 16))
                    .foregroundStyle(server.connectionStatus.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(server.baseURL)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let latency = server.latency {
                        Text("\(Int(latency))ms")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(latency < 200 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            if server.connectionStatus == .connected {
                let toolCount = mcpManager.toolRegistry[server.id.uuidString]?.count ?? 0
                Text("\(toolCount) tools")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue, in: Capsule())
            }

            Toggle("", isOn: Binding(
                get: { server.connectionStatus == .connected },
                set: { newValue in
                    Task {
                        if newValue {
                            try? await mcpManager.connect(to: server)
                        } else {
                            mcpManager.disconnect(server: server)
                        }
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .labelsHidden()
            .scaleEffect(0.7)
        }
        .padding(.vertical, 4)
    }
}

struct MCPServerDetailView: View {
    @State var server: MCPServer
    @ObservedObject private var mcpManager = MCPManager.shared
    @State private var isConnecting = false
    @State private var testResult: String?
    @State private var showingExport = false

    var body: some View {
        Form {
            Section("Status & Metrics") {
                HStack {
                    Label("Connection", systemImage: "antenna.radiowaves.left.and.right")
                    Spacer()
                    Text(server.connectionStatus.label)
                        .foregroundStyle(server.connectionStatus.color)
                        .bold()
                }

                if let latency = server.latency {
                    HStack {
                        Label("Latency", systemImage: "timer")
                        Spacer()
                        Text("\(Int(latency)) ms")
                            .font(.system(.body, design: .monospaced))
                    }
                }

                if let lastConnected = server.lastConnected {
                    HStack {
                        Label("Last Seen", systemImage: "clock")
                        Spacer()
                        Text(lastConnected, style: .relative)
                            .font(.caption)
                    }
                }

                if let lastError = server.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Last Error", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption.bold())
                        Text(lastError)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                HStack(spacing: 12) {
                    if server.connectionStatus == .connected {
                        Button {
                            mcpManager.disconnect(server: server)
                        } label: {
                            Label("Disconnect", systemImage: "power")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button {
                            Task {
                                isConnecting = true
                                try? await mcpManager.connect(to: server)
                                isConnecting = false
                            }
                        } label: {
                            Label("Establish Connection", systemImage: "bolt.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isConnecting)
                    }

                    if isConnecting {
                        ProgressView()
                    }

                    Spacer()

                    Button {
                        Task {
                            do {
                                let info = try await mcpManager.testConnection(server: server)
                                testResult = "Success: \(info.name) v\(info.version) (\(info.protocolVersion))"
                            } catch {
                                testResult = "Failed: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        Label("Ping", systemImage: "waveform.path.ecg")
                    }
                    .buttonStyle(.bordered)
                }

                if let testResult = testResult {
                    Text(testResult)
                        .font(.caption)
                        .foregroundStyle(testResult.hasPrefix("Success") ? .green : .red)
                }
            }

            Section("Endpoint") {
                TextField("Base URL", text: $server.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Toggle(isOn: $server.isTrusted) {
                    Label("Trust this server", systemImage: "shield.checkered")
                }
                .tint(.blue)

                if !server.baseURL.lowercased().hasPrefix("https") && !server.isTrusted {
                    Text("Warning: Non-HTTPS connections are insecure. You must 'Trust' this server to connect.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Section("Authentication") {
                Picker("Mechanism", selection: $server.authConfig.type) {
                    ForEach(MCPAuthType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                MCPAuthFormView(server: $server)
            }

            if server.connectionStatus == .connected {
                Section("Live Tool Registry") {
                    let tools = mcpManager.toolRegistry[server.id.uuidString] ?? []
                    if tools.isEmpty {
                        Text("No functional tools discovered.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tools) { tool in
                            MCPToolRowView(tool: tool)
                        }
                    }

                    Button {
                        Task {
                            try? await mcpManager.connect(to: server)
                        }
                    } label: {
                        Label("Re-scan for Tools", systemImage: "arrow.clockwise.circle")
                    }
                }
            }

            Section("Management") {
                Button {
                    var newServer = server
                    newServer.id = UUID()
                    newServer.name += " (Clone)"
                    newServer.connectionStatus = .disconnected
                    newServer.discoveredTools = []
                    newServer.trafficLogs = []
                    mcpManager.addServer(newServer)
                } label: {
                    Label("Clone Server Configuration", systemImage: "doc.on.doc")
                }

                Button {
                    showingExport = true
                } label: {
                    Label("Export Manifest", systemImage: "square.and.arrow.up")
                }

                Button("Purge Server", role: .destructive) {
                    mcpManager.removeServer(id: server.id)
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            MCPExportView(server: server)
        }
        .navigationTitle(server.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Commit Changes") {
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
                Text("Public access. No credentials required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .apiKey:
                TextField("Header Key", text: $server.authConfig.apiKeyHeaderName)
                SecureField("Secret Value", text: $secretInput)
                Button("Persist Key") {
                    mcpManager.saveSecret(secretInput, key: "apiKey", for: server)
                    secretInput = ""
                }

            case .bearerToken:
                SecureField("Token Payload", text: $secretInput)
                Button("Persist Token") {
                    mcpManager.saveSecret(secretInput, key: "bearerToken", for: server)
                    secretInput = ""
                }

            case .basicAuth:
                TextField("Identifier", text: $server.authConfig.username)
                SecureField("Credential", text: $secretInput)
                Button("Persist Identity") {
                    mcpManager.saveSecret(secretInput, key: "password", for: server)
                    secretInput = ""
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
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                    Button {
                        server.authConfig.customHeaderKeys.append("")
                        server.authConfig.customHeaderValues.append("")
                    } label: {
                        Label("Inject Header", systemImage: "plus.circle.fill")
                    }
                }
            case .oauth, .oauth2AuthCode:
                TextField("Auth Endpoint", text: $server.authConfig.authorizationEndpoint)
                TextField("Token Endpoint", text: $server.authConfig.tokenEndpoint)
                TextField("Client ID", text: $server.authConfig.clientId)
                TextField("Scopes", text: $server.authConfig.scopes)

            case .oauth2ClientCredentials:
                TextField("Token Endpoint", text: $server.authConfig.tokenEndpoint)
                TextField("Client ID", text: $server.authConfig.clientId)
                SecureField("Client Secret", text: $clientSecretInput)
                Button("Save Client Secret") {
                    mcpManager.saveSecret(clientSecretInput, key: "clientSecret", for: server)
                    clientSecretInput = ""
                }
            default:
                EmptyView()
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

struct MCPToolRowView: View {
    let tool: MCPTool
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tool.name)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                        Text(tool.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execution Schema")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.blue)
                        .padding(.top, 4)

                    if let props = tool.inputSchema.value as? [String: Any],
                       let properties = props["properties"] as? [String: Any] {
                        ForEach(properties.sorted(by: { $0.key < $1.key }), id: \.key) { key, prop in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(key)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    if let type = (prop as? [String: Any])?["type"] as? String {
                                        Text("(\(type))")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if let desc = (prop as? [String: Any])?["description"] as? String {
                                    Text(desc)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    } else {
                        Text("Static tool. No parameters required.")
                            .font(.caption2)
                            .italic()
                    }
                }
                .padding(10)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 6)
    }
}

struct MCPAddServerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var authType: MCPAuthType = .none
    @State private var authConfig = MCPAuthConfig()
    @State private var tempSecret = ""
    @State private var showingBrowse = false
    @State private var isTesting = false
    @State private var testStatus: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidURL(url)
    }

    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingBrowse = true
                    } label: {
                        Label("Discover MCP Servers", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                }

                Section("Infrastructure") {
                    TextField("Instance Name", text: $name)
                    TextField("Protocol Endpoint (HTTPS)", text: $url)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Security") {
                    Picker("Auth Mode", selection: $authType) {
                        ForEach(MCPAuthType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if authType != .none {
                        AddServerAuthFields(authType: $authType, authConfig: $authConfig, tempSecret: $tempSecret)
                    }
                }

                Section {
                    Button {
                        Task {
                            isTesting = true
                            testStatus = nil
                            do {
                                let mockServer = MCPServer(name: name, baseURL: url, authConfig: authConfig)
                                let info = try await MCPManager.shared.testConnection(server: mockServer)
                                testStatus = "Verified: \(info.name) v\(info.version)"
                            } catch {
                                testStatus = "Refused: \(error.localizedDescription)"
                            }
                            isTesting = false
                        }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().padding(.trailing, 8)
                            }
                            Label("Validate Endpoint", systemImage: "shield.checkerboard")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isValid || isTesting)

                    if let status = testStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(status.hasPrefix("Verified") ? .green : .red)
                    }
                }
            }
            .navigationTitle("Register Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abort") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Register") {
                        var finalConfig = authConfig
                        finalConfig.type = authType
                        let newServer = MCPServer(
                            name: name,
                            baseURL: url,
                            authConfig: finalConfig
                        )
                        MCPManager.shared.addServer(newServer)

                        if !tempSecret.isEmpty {
                            let key: String
                            switch authType {
                            case .apiKey: key = "apiKey"
                            case .bearerToken: key = "bearerToken"
                            case .basicAuth: key = "password"
                            default: key = ""
                            }
                            if !key.isEmpty {
                                MCPManager.shared.saveSecret(tempSecret, key: key, for: newServer)
                            }
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingBrowse) {
                MCPListModelsSheet { server in
                    self.name = server.name
                    self.url = server.url
                    self.authType = server.authenticationType
                }
            }
        }
    }
}

struct AddServerAuthFields: View {
    @Binding var authType: MCPAuthType
    @Binding var authConfig: MCPAuthConfig
    @Binding var tempSecret: String

    var body: some View {
        Group {
            switch authType {
            case .apiKey:
                TextField("Header Name", text: $authConfig.apiKeyHeaderName)
                SecureField("API Key", text: $tempSecret)
            case .bearerToken:
                SecureField("Token", text: $tempSecret)
                TextField("Refresh Endpoint (Optional)", text: $authConfig.tokenEndpoint)
            case .basicAuth:
                TextField("Username", text: $authConfig.username)
                SecureField("Password", text: $tempSecret)
            case .oauth, .oauth2AuthCode:
                TextField("Auth Endpoint", text: $authConfig.authorizationEndpoint)
                TextField("Token Endpoint", text: $authConfig.tokenEndpoint)
                TextField("Client ID", text: $authConfig.clientId)
                TextField("Scopes", text: $authConfig.scopes)
            case .oauth2ClientCredentials:
                TextField("Token Endpoint", text: $authConfig.tokenEndpoint)
                TextField("Client ID", text: $authConfig.clientId)
                SecureField("Client Secret", text: $tempSecret)
            case .customHeaders:
                VStack(alignment: .leading) {
                    ForEach(0..<authConfig.customHeaderKeys.count, id: \.self) { index in
                        HStack {
                            TextField("Key", text: $authConfig.customHeaderKeys[index])
                            TextField("Value", text: $authConfig.customHeaderValues[index])
                            Button {
                                authConfig.customHeaderKeys.remove(at: index)
                                authConfig.customHeaderValues.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                    Button {
                        authConfig.customHeaderKeys.append("")
                        authConfig.customHeaderValues.append("")
                    } label: {
                        Label("Add Header", systemImage: "plus.circle.fill")
                    }
                }
            default: EmptyView()
            }
        }
    }
}

struct MCPListModelsSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (MCPServerTemplate) -> Void

    @State private var servers: [MCPServerTemplate] = []
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var isLoading = true

    var filteredServers: [MCPServerTemplate] {
        servers.filter { server in
            let matchesSearch = searchText.isEmpty ||
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || server.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var categories: [String] {
        Array(Set(servers.map { $0.category })).sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading directory...")
                } else {
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                    selectedCategory = nil
                                }
                                ForEach(categories, id: \.self) { category in
                                    FilterChip(title: category, isSelected: selectedCategory == category) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Color(.systemGroupedBackground))

                        List(filteredServers) { server in
                            Button {
                                onSelect(server)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(server.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(server.category)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.1), in: Capsule())
                                    }

                                    Text(server.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)

                                    HStack {
                                        Label(server.authenticationType.displayName, systemImage: "lock.shield")
                                            .font(.caption2)
                                        Spacer()
                                        Text(server.url)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("MCP Directory")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search servers...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                loadServers()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func loadServers() {
        guard let url = Bundle.main.url(forResource: "MCPServers", withExtension: "json") else {
            print("MCPServers.json not found")
            isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.servers = try JSONDecoder().decode([MCPServerTemplate].self, from: data)
        } catch {
            print("Failed to decode MCPServers.json: \(error)")
        }
        isLoading = false
    }
}

struct MCPServerTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let url: String
    let authenticationType: MCPAuthType
    let category: String
    let authLink: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, url, category, authLink = "auth_link"
        case authenticationType = "authentication_type"
    }
}

struct MCPExportView: View {
    let server: MCPServer
    @Environment(\.dismiss) var dismiss

    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(server), let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "Failed to encode configuration."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(jsonString)
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Export Manifest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = jsonString
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

struct MCPEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "network")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 60)

            VStack(spacing: 8) {
                Text("No MCP Servers")
                    .font(.title2.bold())
                    .tracking(-0.5)

                Text("Connect to external services using the Model Context Protocol. Extend your AI with custom tools and data sources.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .padding(.bottom, 40)
    }
}
