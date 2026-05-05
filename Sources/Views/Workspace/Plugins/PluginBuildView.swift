import SwiftUI

struct PluginBuildView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = PluginManager.shared

    // Identity
    @State private var name = ""
    @State private var description = ""
    @State private var author = "Developer"
    @State private var version = "1.0.0"
    @State private var icon = "puzzlepiece"
    @State private var identifier = ""
    @State private var isIdentifierLocked = false

    // Capabilities & Actions
    @State private var selectedCapabilities: Set<PluginCapability> = []
    @State private var selectedActions: Set<PluginAction> = []

    // Security Scopes (High-Risk)
    @State private var apiKey: String?
    @State private var privacyNote: String?
    @State private var dataUsageExplanation: String?
    @State private var retentionPolicy: String?

    // Logic
    @State private var sourceCode = """
export async function onEvent(event, ctx) {
  if (event.type === "note.created") {
    const summary = await ctx.ai.summarize(event.payload.content)
    await ctx.notes.updateNote(event.payload.id, summary)
  }
}
"""

    // NEW: External Endpoints
    @State private var endpoints: [ExternalAPIEndpoint] = []
    @State private var showingAddEndpoint = false
    @State private var selectedEndpointForEdit: ExternalAPIEndpoint?

    // NEW: Data Mapping
    @State private var dataMappings: [DataMapping] = []

    // NEW: Execution Rules
    @State private var executionRules: [ExecutionRule] = []

    // NEW: UI Extensions
    @State private var uiExtensions: [UIExtension] = []

    // NEW: Toolkit Tools
    @State private var toolkitTools: [PluginToolkitTool] = []

    // NEW: Release Info
    @State private var releaseNotes = ""

    // Testing
    @State private var testEventPayload = """
{"type":"note.created","payload":{"id":"sample-id","content":"Draft note text"}}
"""
    @State private var simulatedBuildOutput: [String] = []

    @State private var showingIdentifierLockAlert = false
    @State private var errorMessage: String?

    @State private var selectedSection: BuildSection = .identity

    enum BuildSection: String, CaseIterable {
        case identity = "Identity"
        case capabilities = "Capabilities"
        case security = "Security"
        case endpoints = "Endpoints"
        case logic = "Logic"
        case mapping = "Mapping"
        case rules = "Rules"
        case ui = "UI"
        case toolkit = "Toolkit"
        case testing = "Testing"
        case release = "Release"
    }

    var body: some View {
        List {
            Section {
                Picker("Section", selection: $selectedSection) {
                    ForEach(BuildSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.menu)
            }

            switch selectedSection {
            case .identity: identitySection
            case .capabilities:
                capabilitiesSection
                actionsSection
            case .security: securitySection
            case .endpoints: externalEndpointsSection
            case .logic: logicEditorSection
            case .mapping: dataMappingSection
            case .rules: executionRulesSection
            case .ui: uiInjectionSection
            case .toolkit: toolkitSection
            case .testing: testingSection
            case .release: releaseSection
            }

            buildSection
        }
        .navigationTitle("Plugin Builder")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Identifier Locked", isPresented: $showingIdentifierLockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The identifier 'com.toolskit.\(identifier)' cannot be changed after creation.")
        }
        .sheet(isPresented: $showingAddEndpoint) {
            AddEndpointView { endpoint in
                endpoints.append(endpoint)
            }
        }
        .sheet(item: $selectedEndpointForEdit) { endpoint in
            EditEndpointView(endpoint: endpoint) { updated in
                if let index = endpoints.firstIndex(where: { $0.id == updated.id }) {
                    endpoints[index] = updated
                }
            }
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section("Plugin Identity") {
            TextField("Name", text: $name)
            TextField("Description", text: $description)
            TextField("Author", text: $author)
            TextField("Version", text: $version)

            HStack {
                Text("Identifier")
                Spacer()
                if isIdentifierLocked {
                    Text("com.toolskit.\(identifier)")
                        .foregroundColor(.secondary)
                } else {
                    Text("com.toolskit.")
                        .foregroundColor(.secondary)
                    TextField("unique-id", text: $identifier)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .onTapGesture {
                if isIdentifierLocked { showingIdentifierLockAlert = true }
            }
        }
    }

    private var capabilitiesSection: some View {
        Section("Capabilities (System Access)") {
            ForEach(PluginCapability.allCases) { cap in
                Toggle(isOn: Binding(
                    get: { selectedCapabilities.contains(cap) },
                    set: { isSelected in
                        if isSelected {
                            selectedCapabilities.insert(cap)
                        } else {
                            selectedCapabilities.remove(cap)
                            selectedActions = selectedActions.filter { $0.parentCapability != cap }
                        }
                    }
                )) {
                    Label(cap.displayName, systemImage: cap.icon)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions (Event Subscriptions)") {
            if selectedCapabilities.isEmpty {
                Text("Select capabilities first").foregroundColor(.secondary).font(.caption)
            } else {
                ForEach(PluginAction.allCases.filter { selectedCapabilities.contains($0.parentCapability) }) { action in
                    Toggle(action.rawValue, isOn: Binding(
                        get: { selectedActions.contains(action) },
                        set: { isSelected in
                            if isSelected { selectedActions.insert(action) }
                            else { selectedActions.remove(action) }
                        }
                    ))
                }
            }
        }
    }

    private var securitySection: some View {
        Section("Security & Scopes") {
            let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }

            if highRiskSelected {
                NavigationLink(destination: SecurityScopeApplicationView(plugin: Binding(
                    get: { dummyPluginForSecurity },
                    set: { updated in
                        self.apiKey = updated.apiKey
                        self.privacyNote = updated.privacyNote
                        self.dataUsageExplanation = updated.dataUsageExplanation
                        self.retentionPolicy = updated.retentionPolicy
                    }
                ))) {
                    HStack {
                        Label("High-Risk Security Gate", systemImage: "shield.fill")
                            .foregroundColor(.red)
                        Spacer()
                        if apiKey != nil && privacyNote != nil {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("No high-risk scopes selected.").font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var externalEndpointsSection: some View {
        Section("External Endpoints") {
            ForEach(endpoints) { endpoint in
                HStack {
                    VStack(alignment: .leading) {
                        Text(endpoint.name).font(.headline)
                        Text("\(endpoint.method.rawValue) \(endpoint.baseURL)\(endpoint.path)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        selectedEndpointForEdit = endpoint
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .onDelete { indices in
                endpoints.remove(atOffsets: indices)
            }

            Button(action: { showingAddEndpoint = true }) {
                Label("Add Endpoint", systemImage: "plus.circle")
            }
        }
    }

    private var logicEditorSection: some View {
        Section("Logic Editor (JS)") {
            VStack(alignment: .leading) {
                Text("Source Code").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $sourceCode)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 300)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }

            VStack(alignment: .leading) {
                Text("Context Autocomplete (Simulated)").font(.caption).bold()
                Text("ctx.notes, ctx.tasks, ctx.ai, ctx.integrations, ctx.endpoints")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
    }

    private var dataMappingSection: some View {
        Section("Data Mapping") {
            ForEach($dataMappings) { $mapping in
                VStack {
                    TextField("Source (e.g. event.note.content)", text: $mapping.sourceField)
                    TextField("Target (e.g. payload.body.text)", text: $mapping.targetField)
                    if let _ = mapping.transformer {
                        TextField("Transformer Logic", text: Binding(
                            get: { mapping.transformer ?? "" },
                            set: { mapping.transformer = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .onDelete { dataMappings.remove(atOffsets: $0) }

            Button("Add Mapping") {
                dataMappings.append(DataMapping(sourceField: "", targetField: ""))
            }
        }
    }

    private var executionRulesSection: some View {
        Section("Execution Rules") {
            ForEach($executionRules) { $rule in
                VStack {
                    Picker("Type", selection: $rule.type) {
                        ForEach(RuleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Condition (JS)", text: $rule.condition)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .onDelete { executionRules.remove(atOffsets: $0) }

            Button("Add Rule") {
                executionRules.append(ExecutionRule(type: .eventFilter, condition: "true"))
            }
        }
    }

    private var uiInjectionSection: some View {
        Section("UI Injection") {
            ForEach($uiExtensions) { $ext in
                VStack {
                    Picker("Type", selection: $ext.type) {
                        ForEach(UIExtensionType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                    }
                    Picker("Component", selection: $ext.component) {
                        ForEach(UIComponentType.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                    }
                    TextField("Target View", text: $ext.targetView)
                    TextField("Action Binding", text: $ext.actionBinding)
                }
            }
            .onDelete { uiExtensions.remove(atOffsets: $0) }

            Button("Add UI Extension") {
                uiExtensions.append(UIExtension(type: .overlay, component: .button, targetView: "", actionBinding: ""))
            }
        }
    }

    private var toolkitSection: some View {
        Section("Plugin Toolkit") {
            ForEach($toolkitTools) { $tool in
                VStack {
                    Picker("Category", selection: $tool.category) {
                        ForEach(PluginToolCategory.allCases, id: \.self) { c in Text(c.rawValue.capitalized).tag(c) }
                    }

                    Picker("Tool", selection: $tool.name) {
                        ForEach(availableToolkitTools(for: tool.category), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .onDelete { toolkitTools.remove(atOffsets: $0) }

            Button("Add Toolkit Tool") {
                toolkitTools.append(PluginToolkitTool(name: "AI Text Summarizer", category: .ai, config: [:]))
            }
        }
    }

    private func availableToolkitTools(for category: PluginToolCategory) -> [String] {
        switch category {
        case .ai: return ["AI Text Summarizer", "AI Code Generator", "AI Context Analyzer", "AI Classification Engine"]
        case .data: return ["Data Filter Engine", "Data Transformer", "JSON Builder", "CSV Exporter"]
        case .automation: return ["Workflow Trigger Builder", "Multi-Step Executor", "Delay Scheduler", "Conditional Router"]
        case .integrations: return ["Webhook Sender", "API Request Builder", "Response Parser", "Retry Handler"]
        case .workspace: return ["Notes Updater", "Task Generator", "Calendar Sync Tool", "File Organizer"]
        case .developer: return ["Log Stream Viewer", "Error Catcher", "Performance Tracker", "Debug Breakpoints"]
        case .security: return ["Permission Validator", "Scope Checker", "Data Sanitizer", "Access Logger"]
        case .event: return ["Event Listener Builder", "Event Transformer", "Event Replay Tool", "Event Filter Engine"]
        }
    }

    private var testingSection: some View {
        Section("Test Plugin (Sandbox)") {
            TextEditor(text: $testEventPayload)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

            Button("Simulate Event") {
                runLocalValidation()
            }
            .buttonStyle(.bordered)

            if !simulatedBuildOutput.isEmpty {
                VStack(alignment: .leading) {
                    Text("Execution Logs").font(.caption).bold()
                    ForEach(simulatedBuildOutput, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(line.contains("ERROR") ? .red : .secondary)
                    }
                }
            }
        }
    }

    private var releaseSection: some View {
        Section("Release & Versioning") {
            TextField("Version", text: $version)
            TextEditor(text: $releaseNotes)
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

            VStack(alignment: .leading) {
                Text("Diff Viewer (Simulated)").font(.subheadline).bold()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Version").font(.caption).secondary()
                        Text("v1.0.0").font(.system(.caption, design: .monospaced))
                    }
                    Spacer()
                    Image(systemName: "arrow.right").foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("New Version").font(.caption).secondary()
                        Text("v\(version)").font(.system(.caption, design: .monospaced)).foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)

                Text("+ Added \(endpoints.count) Endpoints").font(.caption).foregroundColor(.green)
                Text("+ Added \(uiExtensions.count) UI Extensions").font(.caption).foregroundColor(.green)
                if !releaseNotes.isEmpty {
                    Text("+ Release Notes updated").font(.caption).foregroundColor(.green)
                }
            }

            Text("Changelog Preview").font(.subheadline).bold()
            ForEach(dummyPluginForSecurity.changelog) { entry in
                HStack {
                    Text(entry.version).bold()
                    Text(entry.date, style: .date).foregroundColor(.secondary)
                    Text(entry.notes).font(.caption)
                }
            }
        }
    }

    private var buildSection: some View {
        Section {
            let errors = performStrictValidation()

            if !errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Validation Issues", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red).bold()
                    ForEach(errors, id: \.self) { error in
                        Text("• \(error)").foregroundColor(.red).font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }

            Button(action: buildAndInstall) {
                Text("Build & Install Plugin")
                    .frame(maxWidth: .infinity)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!errors.isEmpty)
        }
    }

    // MARK: - Validation & Actions

    private func performStrictValidation() -> [String] {
        var errors: [String] = []

        if name.isEmpty { errors.append("Name is required.") }
        if identifier.isEmpty { errors.append("Identifier is required.") }
        if selectedCapabilities.isEmpty { errors.append("At least one capability is required.") }
        if selectedActions.isEmpty { errors.append("At least one action is required.") }
        if sourceCode.isEmpty { errors.append("Source code is required.") }

        let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }
        if highRiskSelected && (apiKey == nil || privacyNote == nil) {
            errors.append("High-risk scopes require API Key and Privacy Note.")
        }

        // External API validation
        if !endpoints.isEmpty {
            if !selectedCapabilities.contains(.externalApiConnect) {
                errors.append("External endpoints require 'external.api.connect' capability.")
            }
            for ep in endpoints {
                if ep.baseURL.isEmpty || ep.name.isEmpty {
                    errors.append("Endpoint \(ep.name) has invalid configuration.")
                }
            }
        }

        // UI Extension validation
        if !uiExtensions.isEmpty {
            let uiCaps: Set<PluginCapability> = [.uiOverlayPresent, .uiPanelInject, .uiCommandbarExtend, .uiContextmenuModify]
            if selectedCapabilities.isDisjoint(with: uiCaps) {
                errors.append("UI Extensions require at least one UI capability.")
            }
        }

        // Version validation
        let versionParts = version.split(separator: ".")
        if versionParts.count < 2 {
            errors.append("Version must follow semantic versioning (e.g., 1.0.0).")
        }

        return errors
    }

    private func buildAndInstall() {
        let errors = performStrictValidation()
        if !errors.isEmpty {
            return
        }

        if manager.installedPlugins.contains(where: { $0.identifier == "com.toolskit.\(identifier)" }) {
            errorMessage = "Identifier already in use."
            return
        }

        let newPlugin = PluginDefinition(
            id: UUID(),
            name: name,
            description: description,
            author: author,
            version: version,
            icon: icon,
            identifier: "com.toolskit.\(identifier)",
            isEnabled: true,
            isInstalled: true,
            installedAt: Date(),
            capabilities: Array(selectedCapabilities),
            actions: Array(selectedActions),
            sourceCode: sourceCode,
            releaseNotes: releaseNotes.isEmpty ? nil : releaseNotes,
            apiKey: apiKey,
            privacyNote: privacyNote,
            dataUsageExplanation: dataUsageExplanation,
            retentionPolicy: retentionPolicy,
            endpoints: endpoints,
            dataMappings: dataMappings,
            executionRules: executionRules,
            uiExtensions: uiExtensions,
            toolkitTools: toolkitTools
        )

        manager.savePlugin(newPlugin)
        dismiss()
    }

    private func runLocalValidation() {
        var output: [String] = []
        output.append("• [\(Date().formatted())] Initializing simulation...")

        let errors = performStrictValidation()
        for error in errors {
            output.append("ERROR: \(error)")
        }

        // Simulate Logic Check
        output.append("• Validating logic syntax...")
        if sourceCode.contains("await") && !sourceCode.contains("async") {
            output.append("  ERROR: 'await' used outside of 'async' function")
        }

        if errors.isEmpty && output.count == 2 {
            output.append("✓ Validation successful. Execution preview started.")
            output.append("• ctx.ai.summarize called with payload...")
            output.append("• ctx.notes.updateNote success.")
        }

        simulatedBuildOutput = output
    }

    private var dummyPluginForSecurity: PluginDefinition {
        PluginDefinition(
            id: UUID(),
            name: name,
            description: description,
            author: author,
            version: version,
            icon: icon,
            identifier: "com.toolskit.\(identifier)",
            capabilities: Array(selectedCapabilities),
            actions: Array(selectedActions),
            sourceCode: sourceCode,
            apiKey: apiKey,
            privacyNote: privacyNote,
            dataUsageExplanation: dataUsageExplanation,
            retentionPolicy: retentionPolicy,
            endpoints: endpoints,
            dataMappings: dataMappings,
            executionRules: executionRules,
            uiExtensions: uiExtensions,
            toolkitTools: toolkitTools
        )
    }
}

// MARK: - Supporting Views

struct AddEndpointView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (ExternalAPIEndpoint) -> Void

    @State private var name = ""
    @State private var baseURL = "https://api.example.com"
    @State private var path = "/v1/resource"
    @State private var method: HTTPMethod = .get
    @State private var authType: AuthType = .none

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    TextField("Endpoint Name", text: $name)
                    TextField("Base URL", text: $baseURL)
                    TextField("Path", text: $path)
                    Picker("Method", selection: $method) {
                        ForEach(HTTPMethod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Authentication") {
                    Picker("Auth Type", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }

                Section("Configuration") {
                    Text("Headers, Query Params, and Body Schema can be edited after creation.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Endpoint")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let endpoint = ExternalAPIEndpoint(
                            name: name,
                            baseURL: baseURL,
                            path: path,
                            method: method,
                            headers: [:],
                            queryParams: [:],
                            authType: authType,
                            retryPolicy: RetryPolicy()
                        )
                        onAdd(endpoint)
                        dismiss()
                    }
                    .disabled(name.isEmpty || baseURL.isEmpty)
                }
            }
        }
    }
}

struct EditEndpointView: View {
    @Environment(\.dismiss) var dismiss
    @State var endpoint: ExternalAPIEndpoint
    var onSave: (ExternalAPIEndpoint) -> Void

    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""
    @State private var isHeaderSecure = false

    @State private var newParamKey = ""
    @State private var newParamValue = ""

    var body: some View {
        NavigationView {
            Form {
                Section("API Details") {
                    TextField("Name", text: $endpoint.name)
                    TextField("Base URL", text: $endpoint.baseURL)
                    TextField("Path", text: $endpoint.path)
                    Picker("Method", selection: $endpoint.method) {
                        ForEach(HTTPMethod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Headers") {
                    ForEach(Array(endpoint.headers.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key).bold()
                            if endpoint.encryptedHeaders.contains(key) {
                                Image(systemName: "lock.fill").foregroundColor(.blue).font(.caption)
                            }
                            Spacer()
                            Text(endpoint.headers[key] ?? "").foregroundColor(.secondary).lineLimit(1)
                        }
                    }
                    .onDelete { indices in
                        let keys = Array(endpoint.headers.keys.sorted())
                        indices.forEach { keyIndex in
                            let key = keys[keyIndex]
                            endpoint.headers.removeValue(forKey: key)
                            endpoint.encryptedHeaders.removeAll { $0 == key }
                        }
                    }

                    VStack(spacing: 8) {
                        HStack {
                            TextField("Key", text: $newHeaderKey)
                            TextField("Value", text: $newHeaderValue)
                        }
                        HStack {
                            Toggle("Secure", isOn: $isHeaderSecure)
                                .labelsHidden()
                            Text("Secure (Encrypted)").font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Button("Add Header") {
                                let finalValue = isHeaderSecure ? PluginSecurityService.encryptHeader(newHeaderValue) : newHeaderValue
                                endpoint.headers[newHeaderKey] = finalValue
                                if isHeaderSecure { endpoint.encryptedHeaders.append(newHeaderKey) }
                                newHeaderKey = ""
                                newHeaderValue = ""
                                isHeaderSecure = false
                            }
                            .disabled(newHeaderKey.isEmpty)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Query Parameters") {
                    ForEach(Array(endpoint.queryParams.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key).bold()
                            Spacer()
                            Text(endpoint.queryParams[key] ?? "").foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indices in
                        let keys = Array(endpoint.queryParams.keys.sorted())
                        indices.forEach { endpoint.queryParams.removeValue(forKey: keys[$0]) }
                    }

                    HStack {
                        TextField("Key", text: $newParamKey)
                        TextField("Value", text: $newParamValue)
                        Button("Add") {
                            endpoint.queryParams[newParamKey] = newParamValue
                            newParamKey = ""
                            newParamValue = ""
                        }
                        .disabled(newParamKey.isEmpty)
                    }
                }

                Section("Body Schema (JSON)") {
                    TextEditor(text: Binding(
                        get: { endpoint.bodySchema ?? "" },
                        set: { endpoint.bodySchema = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Endpoint")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(endpoint)
                        dismiss()
                    }
                }
            }
        }
    }
}

extension View {
    func secondary() -> some View {
        self.foregroundColor(.secondary)
    }
}
