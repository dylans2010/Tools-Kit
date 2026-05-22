

import SwiftUI

struct ConnectorBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = ConnectorManager.shared

    // Identity
    @State private var name = ""
    @State private var identifier = ""
    @State private var version = "1.0.0"
    @State private var description = ""
    @State private var isIdentifierLocked = false
    @State private var connectorID: UUID?

    // Auth Configuration
    @State private var selectedAuthType: ConnectorAuthConfig.AuthType = .none
    @State private var apiKeyHeaderName = "X-API-Key"
    @State private var apiKeyValue = ""
    @State private var bearerToken = ""
    @State private var oauthClientID = ""
    @State private var oauthClientSecret = ""
    @State private var oauthAuthURL = ""
    @State private var oauthTokenURL = ""
    @State private var oauthScopes = ""

    // Endpoints
    @State private var baseURL = ""
    @State private var quickEndpointPath = ""
    @State private var quickEndpointMethod = "GET"
    @State private var pendingEndpoints: [ConnectorEndpoint] = []

    // Headers & Query Params
    @State private var globalHeaders: [KeyValuePair] = []
    @State private var globalQueryParams: [KeyValuePair] = []

    // Flow Builder
    @State private var flowSteps: [FlowStep] = []

    // Schema
    @State private var schemaMappings: [KeyValuePair] = []
    @State private var jsonSchemaText = "{}"

    // Environment Variables
    @State private var envVariables: [KeyValuePair] = []

    // Webhook
    @State private var webhookURL = ""
    @State private var webhookEvents: [String] = []
    @State private var newWebhookEvent = ""

    // Rate Limiting
    @State private var rateLimitEnabled = false
    @State private var rateLimitRequests = 60
    @State private var rateLimitWindow = 60
    @State private var retryEnabled = true
    @State private var maxRetries = 3
    @State private var retryBackoffSeconds = 2.0

    // Timeout
    @State private var timeoutSeconds: Double = 30.0

    // Logging
    @State private var loggingEnabled = true
    @State private var loggingVerbose = false

    // Sheets
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingPresetConnectors = false
    @State private var showingEndpointEditor = false
    @State private var showingFlowBuilder = false
    @State private var showingSchemaEditor = false
    @State private var showingHeadersEditor = false
    @State private var showingEnvEditor = false
    @State private var showingWebhookConfig = false
    @State private var showingTestConsole = false
    @State private var showingLogsViewer = false
    @State private var showingImportExport = false

    // Test Console
    @State private var testEndpointIndex: Int?
    @State private var testResponseBody = ""
    @State private var testResponseStatus = ""
    @State private var testIsRunning = false

    init(connector: ConnectorDefinition? = nil) {
        if let connector = connector {
            _name = State(initialValue: connector.name)
            _identifier = State(initialValue: connector.identifier.replacingOccurrences(of: "com.toolskit.", with: ""))
            _version = State(initialValue: connector.version)
            _description = State(initialValue: connector.description)
            _isIdentifierLocked = State(initialValue: true)
            _connectorID = State(initialValue: connector.id)
            _selectedAuthType = State(initialValue: connector.authConfig.type)
            _pendingEndpoints = State(initialValue: connector.endpoints)
            _flowSteps = State(initialValue: connector.flow.steps)
            _schemaMappings = State(initialValue: connector.schema.mappings.map { KeyValuePair(key: $0.key, value: $0.value) })
            _jsonSchemaText = State(initialValue: connector.schema.jsonSchema)
            if connector.authConfig.type == .apiKey { _apiKeyHeaderName = State(initialValue: connector.authConfig.credentials["headerName"] ?? "X-API-Key") }
            else if connector.authConfig.type == .bearer { _bearerToken = State(initialValue: connector.authConfig.credentials["token"] ?? "") }
            else if connector.authConfig.type == .oauth2, let oauth = connector.authConfig.oauthConfig {
                _oauthClientID = State(initialValue: oauth.clientID); _oauthClientSecret = State(initialValue: oauth.clientSecret)
                _oauthAuthURL = State(initialValue: oauth.authURL); _oauthTokenURL = State(initialValue: oauth.tokenURL)
                _oauthScopes = State(initialValue: oauth.scopes.joined(separator: ", "))
            }
        }
    }

    var body: some View {
        Form {
            BuildIdentitySection(name: $name, identifier: $identifier, version: $version, description: $description, isLocked: isIdentifierLocked)

            Section("Network Root") {
                TextField("https://api.example.com/v1", text: $baseURL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                Text("All endpoint paths will be relative to this base URL.").font(.caption2).foregroundStyle(.secondary)

                HStack {
                    Label("Timeout", systemImage: "clock")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(timeoutSeconds))s")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $timeoutSeconds, in: 5...120, step: 5)
            }

            AuthStrategySection(selectedAuthType: $selectedAuthType, apiKeyHeaderName: $apiKeyHeaderName, apiKeyValue: $apiKeyValue, bearerToken: $bearerToken, oauthClientID: $oauthClientID, oauthClientSecret: $oauthClientSecret, oauthAuthURL: $oauthAuthURL, oauthTokenURL: $oauthTokenURL)

            EndpointsConfigSection(endpoints: $pendingEndpoints, quickMethod: $quickEndpointMethod, quickPath: $quickEndpointPath, onAdd: addEndpoint)

            connectorToolsSection

            managementToolsSection

            Section("Reliability") {
                Toggle("Rate Limiting", isOn: $rateLimitEnabled)
                if rateLimitEnabled {
                    HStack {
                        Text("Requests").font(.caption)
                        Spacer()
                        TextField("60", value: $rateLimitRequests, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.caption.monospaced())
                        Text("/ \(rateLimitWindow)s").font(.caption2).foregroundStyle(.secondary)
                    }
                }

                Toggle("Auto Retry", isOn: $retryEnabled)
                if retryEnabled {
                    Stepper("Max Retries: \(maxRetries)", value: $maxRetries, in: 1...10)
                        .font(.caption)
                }
            }

            Section("Logging & Monitoring") {
                Toggle("Enable Logging", isOn: $loggingEnabled)
                if loggingEnabled {
                    Toggle("Verbose Mode", isOn: $loggingVerbose)
                }

                if let id = connectorID {
                    let connectorLogs = manager.logs.filter { $0.connectorID == id }
                    if !connectorLogs.isEmpty {
                        Button {
                            showingLogsViewer = true
                        } label: {
                            Label("View Logs (\(connectorLogs.count))", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                }
            }

            Section("System Capabilities") {
                CapabilityRow(title: "REST Integration", icon: "network", met: true)
                CapabilityRow(title: "Automated Flows", icon: "arrow.triangle.branch", met: !flowSteps.isEmpty)
                CapabilityRow(title: "Schema Mapping", icon: "doc.text.magnifyingglass", met: !schemaMappings.isEmpty)
                CapabilityRow(title: "Secure Auth", icon: "lock.shield", met: selectedAuthType != .none)
                CapabilityRow(title: "Webhooks", icon: "bell.badge", met: !webhookURL.isEmpty)
                CapabilityRow(title: "Rate Limiting", icon: "gauge.with.dots.needle.bottom.50percent", met: rateLimitEnabled)
                CapabilityRow(title: "Auto Retry", icon: "arrow.clockwise", met: retryEnabled)
                CapabilityRow(title: "Logging", icon: "doc.plaintext", met: loggingEnabled)
            }

            Section {
                Button(action: validateAndSave) {
                    Label(connectorID == nil ? "Initialize Connector" : "Commit Changes", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent).disabled(name.isEmpty || identifier.isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(connectorID == nil ? "New Connector" : "Edit Connector")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if connectorID == nil { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingPresetConnectors = true } label: {
                        Label("Presets Library", systemImage: "square.grid.2x2")
                    }
                    Button { showingImportExport = true } label: {
                        Label("Import / Export", systemImage: "arrow.up.arrow.down.square")
                    }
                    if connectorID != nil {
                        Button { showingTestConsole = true } label: {
                            Label("Test Console", systemImage: "play.rectangle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPresetConnectors) { PresetConnectorsView().presentationDetents([.large]) }
        .sheet(isPresented: $showingFlowBuilder) { flowBuilderSheet.presentationDetents([.large]) }
        .sheet(isPresented: $showingSchemaEditor) { schemaEditorSheet.presentationDetents([.large]) }
        .sheet(isPresented: $showingHeadersEditor) { headersEditorSheet.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showingEnvEditor) { envEditorSheet.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showingWebhookConfig) { webhookConfigSheet.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showingTestConsole) { testConsoleSheet.presentationDetents([.large]) }
        .sheet(isPresented: $showingLogsViewer) { logsViewerSheet.presentationDetents([.large]) }
        .sheet(isPresented: $showingImportExport) { importExportSheet.presentationDetents([.medium]) }
        .alert("Validation", isPresented: $showingValidationAlert) { Button("OK") {} } message: { Text(validationMessage) }
    }

    // MARK: - Connector Tools Section

    private var connectorToolsSection: some View {
        Section("Connector Tools") {
            connectorToolRow("OAuth Token Inspector", icon: "lock.open.rotation", desc: "Decode and inspect OAuth access & refresh tokens")
            connectorToolRow("API Key Validator", icon: "key.fill", desc: "Validate API keys against the target service")
            connectorToolRow("Request Signature Generator", icon: "signature", desc: "Generate HMAC-SHA256 request signatures")
            connectorToolRow("Webhook Debugger", icon: "antenna.radiowaves.left.and.right", desc: "Inspect incoming webhook payloads in real-time")
            connectorToolRow("Rate Limit Monitor", icon: "gauge.with.dots.needle.bottom.50percent", desc: "Track API rate limit headers and usage")
            connectorToolRow("Response Cache Manager", icon: "archivebox", desc: "Cache and manage API response data locally")
            connectorToolRow("Header Builder", icon: "list.bullet.clipboard", desc: "Build and template complex request headers")
            connectorToolRow("Payload Transformer", icon: "arrow.triangle.swap", desc: "Transform JSON payloads between different schemas")
            connectorToolRow("GraphQL Explorer", icon: "point.3.connected.trianglepath.dotted", desc: "Build and test GraphQL queries and mutations")
            connectorToolRow("SOAP Envelope Builder", icon: "envelope.fill", desc: "Construct SOAP XML envelopes for legacy APIs")
            connectorToolRow("Certificate Pinning", icon: "lock.shield.fill", desc: "Configure SSL certificate pinning for endpoints")
            connectorToolRow("API Diff Checker", icon: "doc.text.magnifyingglass", desc: "Compare API responses across versions")
            connectorToolRow("Batch Request Runner", icon: "square.stack.3d.up", desc: "Execute multiple API requests in sequence or parallel")
            connectorToolRow("Mock Server", icon: "server.rack", desc: "Create mock API responses for offline testing")
            connectorToolRow("Error Code Reference", icon: "exclamationmark.triangle", desc: "HTTP status code reference and custom error mapping")
            connectorToolRow("Retry Policy Editor", icon: "arrow.clockwise.circle", desc: "Configure exponential backoff and retry strategies")
            connectorToolRow("Data Pagination Helper", icon: "arrow.right.arrow.left", desc: "Handle cursor-based and offset pagination")
            connectorToolRow("OAuth2 PKCE Generator", icon: "lock.rotation", desc: "Generate PKCE code verifiers and challenges")
            connectorToolRow("API Blueprint Generator", icon: "doc.badge.gearshape", desc: "Auto-generate API documentation from endpoints")
            connectorToolRow("Multipart Form Builder", icon: "doc.richtext", desc: "Build multipart/form-data requests with file uploads")
            connectorToolRow("WebSocket Tester", icon: "bolt.horizontal", desc: "Test WebSocket connections and message streaming")
            connectorToolRow("gRPC Client", icon: "arrow.left.arrow.right.circle", desc: "Build and test gRPC service calls")
            connectorToolRow("SSE Stream Listener", icon: "waveform", desc: "Listen to Server-Sent Events streams")
            connectorToolRow("API Health Monitor", icon: "heart.text.square", desc: "Continuous health checks with uptime tracking")
            connectorToolRow("JWT Token Generator", icon: "person.badge.key.fill", desc: "Create and sign JWT tokens for API auth")
            connectorToolRow("CORS Policy Checker", icon: "globe.badge.chevron.backward", desc: "Verify CORS headers and policy compliance")
            connectorToolRow("API Version Manager", icon: "clock.badge.checkmark", desc: "Manage and switch between API versions")
        }
    }

    private func connectorToolRow(_ title: String, icon: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium))
                Text(desc).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Management Tools

    private var managementToolsSection: some View {
        Section("Advanced Configuration") {
            Button { showingFlowBuilder = true } label: {
                Label {
                    HStack {
                        Text("Flow Builder")
                        Spacer()
                        Text("\(flowSteps.count) steps").font(.caption2).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.branch")
                }
            }

            Button { showingSchemaEditor = true } label: {
                Label {
                    HStack {
                        Text("Schema Mapping")
                        Spacer()
                        Text("\(schemaMappings.count) mappings").font(.caption2).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
            }

            Button { showingHeadersEditor = true } label: {
                Label {
                    HStack {
                        Text("Global Headers")
                        Spacer()
                        Text("\(globalHeaders.count)").font(.caption2).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "list.bullet.rectangle")
                }
            }

            Button { showingEnvEditor = true } label: {
                Label {
                    HStack {
                        Text("Environment Variables")
                        Spacer()
                        Text("\(envVariables.count)").font(.caption2).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "terminal")
                }
            }

            Button { showingWebhookConfig = true } label: {
                Label {
                    HStack {
                        Text("Webhook Configuration")
                        Spacer()
                        if !webhookURL.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2).foregroundStyle(.green)
                        }
                    }
                } icon: {
                    Image(systemName: "bell.badge")
                }
            }
        }
    }

    // MARK: - Flow Builder Sheet

    private var flowBuilderSheet: some View {
        NavigationStack {
            List {
                if flowSteps.isEmpty {
                    ContentUnavailableView("No Flow Steps", systemImage: "arrow.triangle.branch", description: Text("Add steps to build an automated flow."))
                }

                ForEach($flowSteps) { $step in
                    HStack(spacing: 12) {
                        Image(systemName: flowStepIcon(step.type))
                            .font(.title3)
                            .foregroundStyle(flowStepColor(step.type))
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.type.rawValue.capitalized)
                                .font(.subheadline.bold())
                            if let desc = step.config["description"] {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { flowSteps.remove(atOffsets: $0) }
                .onMove { flowSteps.move(fromOffsets: $0, toOffset: $1) }

                Section {
                    ForEach(FlowStep.StepType.allCases, id: \.rawValue) { stepType in
                        Button {
                            flowSteps.append(FlowStep(type: stepType, config: ["description": ""]))
                        } label: {
                            Label("Add \(stepType.rawValue.capitalized)", systemImage: flowStepIcon(stepType))
                        }
                    }
                }
            }
            .navigationTitle("Flow Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingFlowBuilder = false }
                        .bold()
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    // MARK: - Schema Editor Sheet

    private var schemaEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Field Mappings") {
                    ForEach($schemaMappings) { $pair in
                        HStack {
                            TextField("Source", text: $pair.key)
                                .font(.caption.monospaced())
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            TextField("Target", text: $pair.value)
                                .font(.caption.monospaced())
                        }
                    }
                    .onDelete { schemaMappings.remove(atOffsets: $0) }

                    Button {
                        schemaMappings.append(KeyValuePair(key: "", value: ""))
                    } label: {
                        Label("Add Mapping", systemImage: "plus.circle")
                    }
                }

                Section("JSON Schema") {
                    TextEditor(text: $jsonSchemaText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Schema Mapping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingSchemaEditor = false }.bold()
                }
            }
        }
    }

    // MARK: - Headers Editor Sheet

    private var headersEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Global Request Headers") {
                    ForEach($globalHeaders) { $pair in
                        HStack {
                            TextField("Header", text: $pair.key)
                                .font(.caption.monospaced())
                            TextField("Value", text: $pair.value)
                                .font(.caption.monospaced())
                        }
                    }
                    .onDelete { globalHeaders.remove(atOffsets: $0) }

                    Button {
                        globalHeaders.append(KeyValuePair(key: "", value: ""))
                    } label: {
                        Label("Add Header", systemImage: "plus.circle")
                    }
                }

                Section("Common Headers") {
                    Button { globalHeaders.append(KeyValuePair(key: "Content-Type", value: "application/json")) } label: {
                        Text("Content-Type: application/json").font(.caption.monospaced())
                    }
                    Button { globalHeaders.append(KeyValuePair(key: "Accept", value: "application/json")) } label: {
                        Text("Accept: application/json").font(.caption.monospaced())
                    }
                    Button { globalHeaders.append(KeyValuePair(key: "User-Agent", value: "ToolsKit/1.0")) } label: {
                        Text("User-Agent: ToolsKit/1.0").font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle("Headers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingHeadersEditor = false }.bold()
                }
            }
        }
    }

    // MARK: - Environment Variables Sheet

    private var envEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Environment Variables") {
                    Text("Define variables that can be referenced in endpoint paths and headers using {{variable_name}} syntax.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach($envVariables) { $pair in
                        HStack {
                            TextField("Key", text: $pair.key)
                                .font(.caption.monospaced())
                            TextField("Value", text: $pair.value)
                                .font(.caption.monospaced())
                        }
                    }
                    .onDelete { envVariables.remove(atOffsets: $0) }

                    Button {
                        envVariables.append(KeyValuePair(key: "", value: ""))
                    } label: {
                        Label("Add Variable", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Environment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingEnvEditor = false }.bold()
                }
            }
        }
    }

    // MARK: - Webhook Configuration Sheet

    private var webhookConfigSheet: some View {
        NavigationStack {
            Form {
                Section("Webhook Endpoint") {
                    TextField("https://your-server.com/webhook", text: $webhookURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(.caption.monospaced())
                }

                Section("Subscribed Events") {
                    ForEach(webhookEvents, id: \.self) { event in
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(event).font(.caption.monospaced())
                        }
                    }
                    .onDelete { webhookEvents.remove(atOffsets: $0) }

                    HStack {
                        TextField("event.name", text: $newWebhookEvent)
                            .font(.caption.monospaced())
                            .textInputAutocapitalization(.never)
                        Button {
                            guard !newWebhookEvent.isEmpty else { return }
                            webhookEvents.append(newWebhookEvent)
                            newWebhookEvent = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newWebhookEvent.isEmpty)
                    }
                }

                Section("Quick Add Events") {
                    ForEach(["connector.request.success", "connector.request.error", "connector.auth.expired", "connector.health.check"], id: \.self) { event in
                        Button {
                            if !webhookEvents.contains(event) {
                                webhookEvents.append(event)
                            }
                        } label: {
                            Text(event).font(.caption.monospaced())
                        }
                        .disabled(webhookEvents.contains(event))
                    }
                }
            }
            .navigationTitle("Webhooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingWebhookConfig = false }.bold()
                }
            }
        }
    }

    // MARK: - Test Console Sheet

    private var testConsoleSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if pendingEndpoints.isEmpty {
                    ContentUnavailableView("No Endpoints", systemImage: "network.slash", description: Text("Add endpoints to test them."))
                } else {
                    List {
                        Section("Select Endpoint") {
                            ForEach(pendingEndpoints.indices, id: \.self) { idx in
                                Button {
                                    testEndpointIndex = idx
                                    testResponseBody = ""
                                    testResponseStatus = ""
                                } label: {
                                    HStack {
                                        Text(pendingEndpoints[idx].method)
                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(methodColor(pendingEndpoints[idx].method).opacity(0.15), in: Capsule())
                                            .foregroundStyle(methodColor(pendingEndpoints[idx].method))
                                        Text(pendingEndpoints[idx].path)
                                            .font(.caption.monospaced())
                                            .lineLimit(1)
                                        Spacer()
                                        if testEndpointIndex == idx {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }

                        if testEndpointIndex != nil {
                            Section {
                                Button {
                                    runTestRequest()
                                } label: {
                                    HStack {
                                        if testIsRunning {
                                            ProgressView()
                                                .controlSize(.small)
                                        }
                                        Label("Send Request", systemImage: "paperplane.fill")
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(testIsRunning)
                            }
                            .listRowBackground(Color.clear)
                        }

                        if !testResponseStatus.isEmpty {
                            Section("Response") {
                                HStack {
                                    Text("Status")
                                        .font(.caption.bold())
                                    Spacer()
                                    Text(testResponseStatus)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(testResponseStatus.hasPrefix("2") ? .green : .red)
                                }

                                if !testResponseBody.isEmpty {
                                    ScrollView {
                                        Text(testResponseBody)
                                            .font(.system(.caption2, design: .monospaced))
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxHeight: 300)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Test Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingTestConsole = false }.bold()
                }
            }
        }
    }

    // MARK: - Logs Viewer Sheet

    private var logsViewerSheet: some View {
        NavigationStack {
            let filteredLogs = connectorID.map { id in manager.logs.filter { $0.connectorID == id } } ?? []
            List {
                if filteredLogs.isEmpty {
                    ContentUnavailableView("No Logs", systemImage: "doc.plaintext", description: Text("No activity logs for this connector."))
                }
                ForEach(filteredLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: logIcon(log.type))
                                .font(.caption)
                                .foregroundStyle(logColor(log.type))
                            Text(log.type.rawValue.uppercased())
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(logColor(log.type))
                            Spacer()
                            Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(log.message)
                            .font(.caption)
                        if let details = log.details {
                            Text(details)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Connector Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let id = connectorID {
                        Button("Clear", role: .destructive) {
                            manager.clearLogs(for: id)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingLogsViewer = false }.bold()
                }
            }
        }
    }

    // MARK: - Import / Export Sheet

    private var importExportSheet: some View {
        NavigationStack {
            List {
                Section("Export") {
                    Button {
                        exportConnectorJSON()
                    } label: {
                        Label("Copy as JSON", systemImage: "doc.on.clipboard")
                    }
                }

                Section("Import") {
                    Button {
                        importConnectorFromClipboard()
                    } label: {
                        Label("Paste from Clipboard", systemImage: "clipboard")
                    }
                }
            }
            .navigationTitle("Import / Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingImportExport = false }.bold()
                }
            }
        }
    }

    // MARK: - Actions

    private func addEndpoint() {
        let fullPath = (!baseURL.isEmpty && !quickEndpointPath.hasPrefix("http")) ? (baseURL.hasSuffix("/") ? "\(baseURL)\(quickEndpointPath)" : "\(baseURL)/\(quickEndpointPath)") : quickEndpointPath
        var headers = globalHeaders.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
        let queryParams = globalQueryParams.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
        pendingEndpoints.append(ConnectorEndpoint(path: fullPath, method: quickEndpointMethod, headers: headers, queryParams: queryParams))
        quickEndpointPath = ""
    }

    private func validateAndSave() {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { validationMessage = "Name required."; showingValidationAlert = true; return }
        if identifier.trimmingCharacters(in: .whitespaces).isEmpty { validationMessage = "Identifier required."; showingValidationAlert = true; return }
        if !baseURL.isEmpty && URL(string: baseURL) == nil { validationMessage = "Base URL is invalid."; showingValidationAlert = true; return }
        saveConnector()
    }

    private func saveConnector() {
        let authConfig = buildAuthConfig()
        let mappings = schemaMappings.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
        let schema = ConnectorSchema(mappings: mappings, jsonSchema: jsonSchemaText)
        let flow = ConnectorFlow(steps: flowSteps)

        if let id = connectorID {
            if var c = manager.connectors.first(where: { $0.id == id }) {
                c.name = name; c.version = version; c.description = description
                c.authConfig = authConfig; c.endpoints = pendingEndpoints
                c.schema = schema; c.flow = flow; c.updatedAt = Date()
                manager.updateConnector(c)
            }
        } else {
            var c = ConnectorDefinition(id: UUID(), name: name, identifier: "com.toolskit.\(identifier)", version: version, description: description, authConfig: authConfig, schema: schema, flow: flow)
            c.endpoints = pendingEndpoints
            manager.addConnector(c)
        }
        dismiss()
    }

    private func buildAuthConfig() -> ConnectorAuthConfig {
        switch selectedAuthType {
        case .apiKey: return ConnectorAuthConfig(type: .apiKey, credentials: ["headerName": apiKeyHeaderName, "apiKey": apiKeyValue])
        case .bearer: return ConnectorAuthConfig(type: .bearer, credentials: ["token": bearerToken])
        case .oauth2: return ConnectorAuthConfig(type: .oauth2, credentials: [:], oauthConfig: OAuthConfig(clientID: oauthClientID, clientSecret: oauthClientSecret, authURL: oauthAuthURL, tokenURL: oauthTokenURL, scopes: oauthScopes.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }))
        case .none: return ConnectorAuthConfig(type: .none)
        }
    }

    private func runTestRequest() {
        guard let idx = testEndpointIndex, idx < pendingEndpoints.count else { return }
        testIsRunning = true
        testResponseBody = ""
        testResponseStatus = ""
        let endpoint = pendingEndpoints[idx]

        Task {
            do {
                let authConfig = buildAuthConfig()
                let connector = ConnectorDefinition(id: connectorID ?? UUID(), name: name, identifier: "com.toolskit.\(identifier)", version: version, description: description, authConfig: authConfig, schema: ConnectorSchema(mappings: [:], jsonSchema: "{}"), flow: ConnectorFlow(steps: []))
                let data = try await ConnectorExecutionService.shared.execute(endpoint: endpoint, connector: connector)
                let responseText = String(data: data, encoding: .utf8) ?? "Binary data (\(data.count) bytes)"
                await MainActor.run {
                    testResponseStatus = "200 OK"
                    testResponseBody = responseText
                    testIsRunning = false
                }
            } catch {
                await MainActor.run {
                    testResponseStatus = "Error"
                    testResponseBody = error.localizedDescription
                    testIsRunning = false
                }
            }
        }
    }

    private func exportConnectorJSON() {
        let authConfig = buildAuthConfig()
        let mappings = schemaMappings.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
        let schema = ConnectorSchema(mappings: mappings, jsonSchema: jsonSchemaText)
        let flow = ConnectorFlow(steps: flowSteps)
        let connector = ConnectorDefinition(id: connectorID ?? UUID(), name: name, identifier: "com.toolskit.\(identifier)", version: version, description: description, authConfig: authConfig, schema: schema, flow: flow)
        if let data = try? JSONEncoder().encode(connector), let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = json
        }
    }

    private func importConnectorFromClipboard() {
        guard let json = UIPasteboard.general.string,
              let data = json.data(using: .utf8),
              let connector = try? JSONDecoder().decode(ConnectorDefinition.self, from: data) else { return }
        name = connector.name
        identifier = connector.identifier.replacingOccurrences(of: "com.toolskit.", with: "")
        version = connector.version
        description = connector.description
        selectedAuthType = connector.authConfig.type
        pendingEndpoints = connector.endpoints
        flowSteps = connector.flow.steps
        schemaMappings = connector.schema.mappings.map { KeyValuePair(key: $0.key, value: $0.value) }
        jsonSchemaText = connector.schema.jsonSchema
    }

    // MARK: - Helpers

    private func flowStepIcon(_ type: FlowStep.StepType) -> String {
        switch type {
        case .trigger: return "bolt.fill"
        case .condition: return "arrow.triangle.branch"
        case .action: return "play.fill"
        case .delay: return "clock"
        }
    }

    private func flowStepColor(_ type: FlowStep.StepType) -> Color {
        switch type {
        case .trigger: return .orange
        case .condition: return .blue
        case .action: return .green
        case .delay: return .purple
        }
    }

    private func methodColor(_ m: String) -> Color {
        switch m.uppercased() { case "GET": return .blue; case "POST": return .green; case "PUT": return .orange; case "DELETE": return .red; default: return .secondary }
    }

    private func logIcon(_ type: ConnectorLog.LogType) -> String {
        switch type {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .performance: return "gauge.with.dots.needle.bottom.50percent"
        }
    }

    private func logColor(_ type: ConnectorLog.LogType) -> Color {
        switch type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .performance: return .purple
        }
    }
}

// MARK: - Key-Value Pair Helper

private struct KeyValuePair: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

// MARK: - Private Sub-structs

private struct BuildIdentitySection: View {
    @Binding var name: String
    @Binding var identifier: String
    @Binding var version: String
    @Binding var description: String
    let isLocked: Bool

    var body: some View {
        Section("Identity") {
            TextField("Connector Name", text: $name).font(.headline)
            HStack {
                Text("com.toolskit.").foregroundStyle(.tertiary).font(.system(.subheadline, design: .monospaced))
                if isLocked { Text(identifier).foregroundStyle(.secondary).font(.system(.subheadline, design: .monospaced)) }
                else { TextField("identifier", text: $identifier).textInputAutocapitalization(.never).autocorrectionDisabled().font(.system(.subheadline, design: .monospaced)) }
            }
            HStack {
                Image(systemName: "tag.fill").font(.caption2).foregroundStyle(.secondary)
                TextField("v1.0.0", text: $version).font(.system(.caption2, design: .monospaced))
            }
            TextEditor(text: $description).frame(minHeight: 60).font(.caption).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct AuthStrategySection: View {
    @Binding var selectedAuthType: ConnectorAuthConfig.AuthType
    @Binding var apiKeyHeaderName: String
    @Binding var apiKeyValue: String
    @Binding var bearerToken: String
    @Binding var oauthClientID: String
    @Binding var oauthClientSecret: String
    @Binding var oauthAuthURL: String
    @Binding var oauthTokenURL: String

    var body: some View {
        Section("Authentication") {
            Picker("Strategy", selection: $selectedAuthType) {
                Text("None").tag(ConnectorAuthConfig.AuthType.none)
                Text("API Key").tag(ConnectorAuthConfig.AuthType.apiKey)
                Text("Bearer").tag(ConnectorAuthConfig.AuthType.bearer)
                Text("OAuth 2.0").tag(ConnectorAuthConfig.AuthType.oauth2)
            }
            switch selectedAuthType {
            case .apiKey:
                TextField("Header Name", text: $apiKeyHeaderName).font(.caption.monospaced())
                SecureField("API Key Value", text: $apiKeyValue).font(.caption.monospaced())
            case .bearer:
                SecureField("Bearer Token", text: $bearerToken).font(.caption.monospaced())
            case .oauth2:
                TextField("Client ID", text: $oauthClientID).font(.caption.monospaced())
                SecureField("Client Secret", text: $oauthClientSecret).font(.caption.monospaced())
                TextField("Auth URL", text: $oauthAuthURL).keyboardType(.URL).font(.caption.monospaced())
                TextField("Token URL", text: $oauthTokenURL).keyboardType(.URL).font(.caption.monospaced())
            case .none:
                Label("No Authentication Required", systemImage: "shield.slash").font(.caption).foregroundStyle(.secondary).padding(.vertical, 4)
            }
        }
    }
}

private struct EndpointsConfigSection: View {
    @Binding var endpoints: [ConnectorEndpoint]
    @Binding var quickMethod: String
    @Binding var quickPath: String
    let onAdd: () -> Void

    var body: some View {
        Section("Endpoints") {
            if !endpoints.isEmpty {
                ForEach(endpoints) { ep in
                    HStack {
                        Text(ep.method).font(.system(size: 8, weight: .black, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(methodColor(ep.method).opacity(0.1), in: Capsule()).foregroundStyle(methodColor(ep.method))
                        Text(ep.path).font(.system(.caption2, design: .monospaced)).lineLimit(1)
                    }
                }.onDelete { endpoints.remove(atOffsets: $0) }
            }
            HStack {
                Picker("", selection: $quickMethod) { ForEach(["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu).frame(width: 90)
                TextField("/path", text: $quickPath).textInputAutocapitalization(.never).autocorrectionDisabled().font(.caption.monospaced())
                Button(action: onAdd) { Image(systemName: "plus.circle.fill") }.disabled(quickPath.isEmpty)
            }
        }
    }
    private func methodColor(_ m: String) -> Color {
        switch m.uppercased() { case "GET": return .blue; case "POST": return .green; case "PUT": return .orange; case "DELETE": return .red; case "PATCH": return .purple; default: return .secondary }
    }
}

private struct CapabilityRow: View {
    let title: String
    let icon: String
    let met: Bool
    var body: some View {
        Label {
            HStack { Text(title).font(.caption); Spacer(); Image(systemName: met ? "checkmark.circle.fill" : "circle").foregroundStyle(met ? Color.green : Color.secondary) }
        } icon: { Image(systemName: icon).foregroundStyle(Color.accentColor) }.font(.caption)
    }
}
