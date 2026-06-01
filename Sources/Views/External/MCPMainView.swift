import SwiftUI

struct MCPMainView: View {
    @StateObject private var mcpManager = MCPManager.shared
    @State private var showingAddServer = false
    @State private var showingBrowseServers = false

    var body: some View {
        NavigationStack {
            List {
                if mcpManager.servers.isEmpty {
                    MCPEmptyStateView {
                        showingAddServer = true
                    }
                } else {
                    Section {
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
                    } header: {
                        HStack {
                            Text("Your Servers")
                            Spacer()
                            Menu {
                                Button {
                                    Task {
                                        for server in mcpManager.servers {
                                            try? await mcpManager.connect(to: server)
                                        }
                                    }
                                } label: {
                                    Label("Connect All", systemImage: "bolt.fill")
                                }

                                Button(role: .destructive) {
                                    for server in mcpManager.servers {
                                        mcpManager.disconnect(server: server)
                                    }
                                } label: {
                                    Label("Disconnect All", systemImage: "power")
                                }
                            } label: {
                                Label("Bulk Actions", systemImage: "ellipsis.circle")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("MCP Servers")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            Task {
                                for server in mcpManager.servers {
                                    try? await mcpManager.connect(to: server)
                                }
                            }
                        } label: {
                            Label("Connect All", systemImage: "bolt.fill")
                        }

                        Button(role: .destructive) {
                            for server in mcpManager.servers {
                                mcpManager.disconnect(server: server)
                            }
                        } label: {
                            Label("Disconnect All", systemImage: "power")
                        }

                        Divider()

                        Button {
                            Task {
                                for server in mcpManager.servers where server.connectionStatus == .connected {
                                    try? await mcpManager.connect(to: server)
                                }
                            }
                        } label: {
                            Label("Refresh All", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showingBrowseServers = true
                        } label: {
                            Label("Browse", systemImage: "magnifyingglass.circle")
                        }

                        Button {
                            showingAddServer = true
                        } label: {
                            Image(systemName: "plus")
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
                        authConfig: MCPAuthConfig(type: server.authenticationType)
                    )
                    mcpManager.addServer(newServer)
                }
            }
        }
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
                    .frame(width: 32, height: 32)

                Image(systemName: server.connectionStatus == .connected ? "checkmark.circle.fill" : "network")
                    .font(.system(size: 14))
                    .foregroundStyle(server.connectionStatus.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.headline)
                Text(server.baseURL)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if server.connectionStatus == .connected {
                Text("\(server.discoveredTools.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
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
                            Label("Connect", systemImage: "network")
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
                                testResult = "Success: \(info.name) v\(info.version)"
                            } catch {
                                testResult = "Failed: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        Label("Test", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.bordered)
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

                NavigationLink(destination: MCPGuideView()) {
                    Label("View Setup Guide", systemImage: "book.fill")
                        .foregroundStyle(.blue)
                }
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

            Section("Traffic Inspector") {
                if let logs = server.trafficLogs, !logs.isEmpty {
                    NavigationLink(destination: MCPTrafficInspectorView(server: server)) {
                        Label("View \(logs.count) entries", systemImage: "list.bullet.rectangle.portrait")
                    }
                } else {
                    Text("No logs recorded yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Management") {
                Button {
                    var newServer = server
                    newServer.id = UUID()
                    newServer.name += " (Copy)"
                    newServer.connectionStatus = .disconnected
                    newServer.discoveredTools = []
                    newServer.trafficLogs = []
                    mcpManager.addServer(newServer)
                } label: {
                    Label("Duplicate Server", systemImage: "plus.square.on.square")
                }

                Button {
                    showingExport = true
                } label: {
                    Label("Export Configuration", systemImage: "square.and.arrow.up")
                }

                Button("Remove Server", role: .destructive) {
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

            case .oauth, .oauth2AuthCode:
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
        return url.scheme != nil && (url.host != nil || url.scheme == "file")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingBrowse = true
                    } label: {
                        Label("Browse MCP Directory", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(Color.clear)
                }

                Section("Server Details") {
                    TextField("Server Name", text: $name)
                    TextField("Base URL (e.g. https://.../mcp)", text: $url)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Authentication") {
                    Picker("Auth Type", selection: $authType) {
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
                                testStatus = "Verified: \(info.name) (\(info.version))"
                            } catch {
                                testStatus = "Error: \(error.localizedDescription)"
                            }
                            isTesting = false
                        }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().padding(.trailing, 8)
                            }
                            Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
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
            .navigationTitle("Add MCP Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
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

// MARK: - MCP Directory Models & Sheet

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
                                        if let authLink = server.authLink, let url = URL(string: authLink) {
                                            Button {
                                                UIApplication.shared.open(url)
                                            } label: {
                                                Text("Get Credentials")
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(.blue)
                                            }
                                            .buttonStyle(.plain)
                                        }
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


struct MCPTrafficInspectorView: View {
    let server: MCPServer

    var body: some View {
        List((server.trafficLogs ?? []).reversed()) { log in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: log.direction == .request ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(log.direction == .request ? .blue : .green)
                    Text(log.direction.rawValue.uppercased())
                        .font(.caption2.bold())

                    if let method = log.method {
                        Text(method)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()
                    Text(log.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(log.payload)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Traffic: \(server.name)")
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
            .navigationTitle("Export Config")
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
