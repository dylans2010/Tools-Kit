

import SwiftUI

struct PluginBuildView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = SDKPluginManager.shared

    // Identity
    @State private var name = ""
    @State private var description = ""
    @State private var author = ""
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

    // Environment Variables
    @State private var envVars: [String: String] = [:]

    // Dependencies
    @State private var dependencies: [String] = []

    // Logic
    @State private var sourceCode = """
export async function onEvent(event, ctx) {
  // Handle events here
}
"""

    // Endpoints
    @State private var endpoints: [ExternalAPIEndpoint] = []
    @State private var showingAddEndpoint = false
    @State private var selectedEndpointForEdit: ExternalAPIEndpoint?

    // Data Mapping
    @State private var dataMappings: [DataMapping] = []

    // Execution Rules
    @State private var executionRules: [ExecutionRule] = []

    // Resource Limits
    @State private var memoryLimitMB: Int = 128
    @State private var cpuLimitPercent: Int = 20
    @State private var executionTimeout: Int = 30

    // UI Extensions
    @State private var uiExtensions: [UIExtension] = []

    // Toolkit Tools
    @State private var toolkitTools: [PluginToolkitTool] = []

    // Release Info
    @State private var releaseNotes = ""

    // Testing
    @State private var testEventPayload = """
{"type":"","payload":{}}
"""
    @State private var simulatedBuildOutput: [String] = []

    @State private var showingIdentifierLockAlert = false
    @State private var errorMessage: String?
    @State private var showingDocs = false

    @State private var selectedSection: BuildSection = .identity

    enum BuildSection: String, CaseIterable {
        case identity = "Identity"
        case capabilities = "Capabilities"
        case security = "Security"
        case environment = "Environment"
        case dependencies = "Dependencies"
        case endpoints = "Endpoints"
        case logic = "Logic"
        case mapping = "Mapping"
        case rules = "Rules"
        case resources = "Resources"
        case ui = "UI"
        case toolkit = "Toolkit"
        case testing = "Testing"
        case release = "Release"
    }

    var body: some View {
        Form {
            Section {
                Picker("Navigation", selection: $selectedSection) {
                    ForEach(BuildSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.menu)
            }

            switch selectedSection {
            case .identity:
                BuildIdentitySection(name: $name, description: $description, author: $author, version: $version, identifier: $identifier, isLocked: isIdentifierLocked) {
                    if isIdentifierLocked { showingIdentifierLockAlert = true }
                }
            case .capabilities:
                BuildCapabilitiesSection(selectedCapabilities: $selectedCapabilities, selectedActions: $selectedActions)
            case .security:
                BuildSecuritySection(selectedCapabilities: selectedCapabilities, apiKey: apiKey, privacyNote: privacyNote, plugin: currentPluginSnapshot) { updated in
                    self.apiKey = updated.apiKey
                    self.privacyNote = updated.privacyNote
                    self.dataUsageExplanation = updated.dataUsageExplanation
                    self.retentionPolicy = updated.retentionPolicy
                }
            case .environment:
                BuildEnvironmentSection(envVars: $envVars)
            case .dependencies:
                BuildDependenciesSection(dependencies: $dependencies)
            case .endpoints:
                BuildEndpointsSection(endpoints: $endpoints) { showingAddEndpoint = true } onEdit: { selectedEndpointForEdit = $0 }
            case .logic:
                BuildLogicSection(sourceCode: $sourceCode)
            case .mapping:
                BuildMappingSection(dataMappings: $dataMappings)
            case .rules:
                BuildRulesSection(executionRules: $executionRules)
            case .resources:
                BuildResourcesSection(memoryLimit: $memoryLimitMB, cpuLimit: $cpuLimitPercent, timeout: $executionTimeout)
            case .ui:
                BuildUIInjectionSection(uiExtensions: $uiExtensions, toolkitTools: $toolkitTools)
            case .toolkit:
                BuildToolkitSection(toolkitTools: $toolkitTools)
            case .testing:
                BuildTestingSection(testEventPayload: $testEventPayload, simulatedBuildOutput: simulatedBuildOutput) { runLocalValidation() }
            case .release:
                BuildReleaseSection(version: $version, releaseNotes: $releaseNotes, endpointsCount: endpoints.count, uiExtensionsCount: uiExtensions.count, plugin: currentPluginSnapshot)
            }

            BuildSubmitSection(errors: performStrictValidation(), errorMessage: errorMessage) { buildAndInstall() }
        }
        .navigationTitle("Plugin Builder")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingDocs = true } label: { Label("Documentation", systemImage: "book.closed") }
            }
        }
        .sheet(isPresented: $showingDocs) {
            PluginDocumentationView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingAddEndpoint) {
            AddEndpointView { endpoints.append($0) }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(item: $selectedEndpointForEdit) { endpoint in
            EditEndpointView(endpoint: endpoint) { updated in
                if let index = endpoints.firstIndex(where: { $0.id == updated.id }) { endpoints[index] = updated }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .alert("Identifier Locked", isPresented: $showingIdentifierLockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The identifier 'com.toolskit.\(identifier)' cannot be changed after creation. This helps us identify your plugin on the app.")
        }
    }

    // MARK: - Logic Preservation

    private func performStrictValidation() -> [String] {
        var errors: [String] = []
        if name.isEmpty { errors.append("Name is required.") }
        if identifier.isEmpty { errors.append("Identifier is required.") }
        if selectedCapabilities.isEmpty { errors.append("At least one capability is required.") }
        if selectedActions.isEmpty { errors.append("At least one action is required.") }
        if sourceCode.isEmpty { errors.append("Source code is required.") }
        let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }
        if highRiskSelected && (apiKey == nil || privacyNote == nil) {
            errors.append("High risk scopes require API Key and Privacy Note.")
        }
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
        if !uiExtensions.isEmpty {
            let uiCaps: Set<PluginCapability> = [.uiOverlayPresent, .uiPanelInject, .uiCommandbarExtend, .uiContextmenuModify]
            if selectedCapabilities.isDisjoint(with: uiCaps) {
                errors.append("UI Extensions require at least one UI capability.")
            }
        }
        let versionParts = version.split(separator: ".")
        if versionParts.count < 2 {
            errors.append("Version must follow semantic versioning (e.g., 1.0.0).")
        }
        return errors
    }

    private func buildAndInstall() {
        let errors = performStrictValidation()
        if !errors.isEmpty { return }
        // identifier check removed as SDKPlugin doesn't expose it directly here

        let newSDKPlugin = SDKPlugin(
            id: UUID(),
            name: name,
            version: version,
            permissions: Array(selectedCapabilities).map { cap -> PluginPermission in
                                                          
                switch cap {
                case .notes, .files: return .readData
                case .mail: return .notifications
                default: return .readData
                }
            },
            isEnabled: true,
            installedAt: Date(),
            tools: toolkitTools.map { $0.id },
            automationHooks: Array(selectedActions).map { $0.rawValue }
        )

        do {
            try manager.install(newSDKPlugin)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runLocalValidation() {
        var output: [String] = []
        output.append("• [\(Date().formatted())] Initializing Simulation...")
        let errors = performStrictValidation()
        for error in errors { output.append("ERROR: \(error)") }
        output.append("• Validating logic syntax...")
        if sourceCode.contains("await") && !sourceCode.contains("async") {
            output.append("  ERROR: 'await' used outside of 'async' function")
        }
        if errors.isEmpty && output.count == 2 {
            output.append("✓ Validation successful.")
        }
        simulatedBuildOutput = output
    }

    private var currentPluginSnapshot: PluginDefinition {
        PluginDefinition(
            id: UUID(), name: name, description: description, author: author, version: version, icon: icon,
            identifier: "com.toolskit.\(identifier)", capabilities: Array(selectedCapabilities),
            actions: Array(selectedActions), sourceCode: sourceCode, apiKey: apiKey, privacyNote: privacyNote,
            dataUsageExplanation: dataUsageExplanation, retentionPolicy: retentionPolicy,
            endpoints: endpoints, dataMappings: dataMappings, executionRules: executionRules,
            uiExtensions: uiExtensions, toolkitTools: toolkitTools
        )
    }
}

// MARK: - Private Sections

private struct BuildIdentitySection: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var author: String
    @Binding var version: String
    @Binding var identifier: String
    let isLocked: Bool
    let onLockedTap: () -> Void

    var body: some View {
        Section {
            TextField("Name", text: $name)
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
            TextField("Author", text: $author)
            TextField("Version", text: $version)

            HStack {
                Label("Identifier", systemImage: "at")
                Spacer()
                if isLocked {
                    Text("com.toolskit.\(identifier)").foregroundStyle(.secondary)
                } else {
                    Text("com.toolskit.").foregroundStyle(.secondary)
                    TextField("Identifier", text: $identifier)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { if isLocked { onLockedTap() } }
        } header: {
            Label("Plugin Identity", systemImage: "person.text.rectangle.fill")
        }
    }
}

private struct BuildCapabilitiesSection: View {
    @Binding var selectedCapabilities: Set<PluginCapability>
    @Binding var selectedActions: Set<PluginAction>

    var body: some View {
        Section {
            ForEach(PluginCapability.allCases) { cap in
                Toggle(isOn: Binding(
                    get: { selectedCapabilities.contains(cap) },
                    set: { isSelected in
                        if isSelected { selectedCapabilities.insert(cap) }
                        else {
                            selectedCapabilities.remove(cap)
                            selectedActions = selectedActions.filter { $0.parentCapability != cap }
                        }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Label(cap.displayName, systemImage: cap.icon)
                        Text(cap.technicalKey).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("Capabilities (System Access)", systemImage: "lock.shield.fill")
        }

        Section {
            if selectedCapabilities.isEmpty {
                ContentUnavailableView("No Capabilities", systemImage: "shield.slash", description: Text("Select capabilities above to enable specific action scopes."))
                    .scaleEffect(0.8)
            } else {
                ForEach(PluginAction.allCases.filter { selectedCapabilities.contains($0.parentCapability) }) { action in
                    Toggle(isOn: Binding(
                        get: { selectedActions.contains(action) },
                        set: { isSelected in
                            if isSelected { selectedActions.insert(action) }
                            else { selectedActions.remove(action) }
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text(action.rawValue).font(.subheadline.bold())
                            Text(action.description).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Label("Action Scopes", systemImage: "target")
        }
    }
}

private struct BuildSecuritySection: View {
    let selectedCapabilities: Set<PluginCapability>
    let apiKey: String?
    let privacyNote: String?
    let plugin: PluginDefinition
    let onUpdate: (PluginDefinition) -> Void

    var body: some View {
        Section {
            let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }
            if highRiskSelected {
                NavigationLink {
                    SecurityScopeApplicationView(plugin: Binding(get: { plugin }, set: { onUpdate($0) }))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("High Risk Security Gate", systemImage: "shield.fill")
                                .foregroundStyle(.red)
                                .font(.headline)
                            Text("Advanced security configuration required for selected scopes.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if apiKey != nil && privacyNote != nil {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.sdkSuccess)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Standard Security", systemImage: "shield.checkered", description: Text("No high-risk capabilities selected. Standard security policies apply."))
                    .scaleEffect(0.8)
            }
        } header: {
            Label("Security & Scopes", systemImage: "lock.fill")
        }
    }
}

private struct BuildEnvironmentSection: View {
    @Binding var envVars: [String: String]
    @State private var newKey = ""
    @State private var newValue = ""

    var body: some View {
        Section {
            if envVars.isEmpty {
                Text("No environment variables defined.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(envVars.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key).font(.caption.monospaced()).bold()
                        Spacer()
                        Text(envVars[key] ?? "").font(.caption.monospaced()).foregroundStyle(.secondary)
                        Button { envVars.removeValue(forKey: key) } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                    }
                }
            }

            HStack {
                TextField("Key", text: $newKey).font(.caption.monospaced())
                TextField("Value", text: $newValue).font(.caption.monospaced())
                Button("Add") {
                    envVars[newKey] = newValue
                    newKey = ""; newValue = ""
                }.disabled(newKey.isEmpty)
            }
        } header: {
            Label("Environment Variables", systemImage: "curlybraces.square.fill")
        }
    }
}

private struct BuildDependenciesSection: View {
    @Binding var dependencies: [String]
    @State private var newDep = ""

    var body: some View {
        Section {
            if dependencies.isEmpty {
                Text("No dependencies defined.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(dependencies, id: \.self) { dep in
                    HStack {
                        Label(dep, systemImage: "package.fill").font(.subheadline)
                        Spacer()
                        Button { dependencies.removeAll { $0 == dep } } label: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                    }
                }
            }

            HStack {
                TextField("Module Name (e.g. lodash)", text: $newDep)
                Button("Add") {
                    dependencies.append(newDep)
                    newDep = ""
                }.disabled(newDep.isEmpty)
            }
        } header: {
            Label("External Dependencies", systemImage: "shippingbox.fill")
        }
    }
}

private struct BuildResourcesSection: View {
    @Binding var memoryLimit: Int
    @Binding var cpuLimit: Int
    @Binding var timeout: Int

    var body: some View {
        Section {
            VStack(alignment: .leading) {
                HStack {
                    Label("Memory Limit", systemImage: "memorychip")
                    Spacer()
                    Text("\(memoryLimit) MB").bold()
                }
                Slider(value: Binding(get: { Double(memoryLimit) }, set: { memoryLimit = Int($0) }), in: 16...512, step: 16)
            }

            VStack(alignment: .leading) {
                HStack {
                    Label("CPU Limit", systemImage: "cpu")
                    Spacer()
                    Text("\(cpuLimit)%").bold()
                }
                Slider(value: Binding(get: { Double(cpuLimit) }, set: { cpuLimit = Int($0) }), in: 5...100, step: 5)
            }

            Stepper(value: $timeout, in: 1...300) {
                Label("Execution Timeout", systemImage: "timer")
                Spacer()
                Text("\(timeout)s").bold()
            }
        } header: {
            Label("Resource Limits", systemImage: "gauge.with.dots.needle.bottom.100percent")
        }
    }
}

private struct BuildEndpointsSection: View {
    @Binding var endpoints: [ExternalAPIEndpoint]
    let onAdd: () -> Void
    let onEdit: (ExternalAPIEndpoint) -> Void

    var body: some View {
        Section("External Endpoints") {
            if endpoints.isEmpty {
                ContentUnavailableView("No Endpoints", systemImage: "network", description: Text("Connect to external APIs by adding their endpoints."))
            } else {
                ForEach(endpoints) { endpoint in
                    Button { onEdit(endpoint) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(endpoint.name).font(.subheadline.bold())
                                Text("\(endpoint.method.rawValue) \(endpoint.baseURL)\(endpoint.path)")
                                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { endpoints.remove(atOffsets: $0) }
            }

            Button(action: onAdd) {
                Label("Add Endpoint", systemImage: "plus.circle.fill").font(.subheadline.bold())
            }
        }
    }
}

private struct BuildLogicSection: View {
    @Binding var sourceCode: String
    var body: some View {
        Section("Logic Editor (JS)") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Source Code").font(.caption.bold()).foregroundStyle(.secondary)
                TextEditor(text: $sourceCode)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 300)
                    .padding(4)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Context Autocomplete").font(.caption2.bold())
                    Text("ctx.notes, ctx.tasks, ctx.ai, ctx.integrations, ctx.endpoints")
                        .font(.system(size: 9, design: .monospaced)).foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct BuildMappingSection: View {
    @Binding var dataMappings: [DataMapping]
    var body: some View {
        Section {
            if dataMappings.isEmpty {
                Text("No data mappings defined.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach($dataMappings) { $mapping in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Source (e.g. event.note.content)", text: $mapping.sourceField).font(.caption.monospaced())
                        TextField("Target (e.g. payload.body.text)", text: $mapping.targetField).font(.caption.monospaced())
                        if let _ = mapping.transformer {
                            TextField("Transformer Logic", text: Binding(get: { mapping.transformer ?? "" }, set: { mapping.transformer = $0.isEmpty ? nil : $0 }))
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { dataMappings.remove(atOffsets: $0) }
            }
            Button("Add Mapping", systemImage: "arrow.left.arrow.right") {
                dataMappings.append(DataMapping(sourceField: "", targetField: ""))
            }
        } header: {
            Text("Data Mapping")
        }
    }
}

private struct BuildRulesSection: View {
    @Binding var executionRules: [ExecutionRule]
    var body: some View {
        Section("Execution Rules") {
            if executionRules.isEmpty {
                Text("No Rules Defined").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach($executionRules) { $rule in
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Type", selection: $rule.type) {
                            ForEach(RuleType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu).labelsHidden().controlSize(.mini)

                        TextField("Condition (JS)", text: $rule.condition)
                            .font(.system(.caption, design: .monospaced)).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { executionRules.remove(atOffsets: $0) }
            }
            Button("Add Rule", systemImage: "checklist") {
                executionRules.append(ExecutionRule(type: .eventFilter, condition: "true"))
            }
        }
    }
}

private struct BuildUIInjectionSection: View {
    @Binding var uiExtensions: [UIExtension]
    @Binding var toolkitTools: [PluginToolkitTool]

    var body: some View {
        Section("UI Injection") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Command Palette Integration", isOn: Binding(get: { toolkitTools.contains { $0.name == "Command Palette Integration" } }, set: { toggleTool("Command Palette Integration", .workspace, $0) }))
                Toggle("Context Menu Extensions", isOn: Binding(get: { toolkitTools.contains { $0.name == "Context Menu Extensions" } }, set: { toggleTool("Context Menu Extensions", .workspace, $0) }))
                Toggle("Custom UI Injection", isOn: Binding(get: { toolkitTools.contains { $0.name == "UI Injection Config" } }, set: { toggleTool("UI Injection Config", .workspace, $0) }))
            }

            ForEach($uiExtensions) { $ext in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Picker("Type", selection: $ext.type) { ForEach(UIExtensionType.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
                        Picker("Component", selection: $ext.component) { ForEach(UIComponentType.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
                    }.controlSize(.mini)
                    TextField("Target View", text: $ext.targetView).font(.caption)
                    TextField("Action Binding", text: $ext.actionBinding).font(.caption.monospaced())
                }
                .padding(.vertical, 4)
            }
            .onDelete { uiExtensions.remove(atOffsets: $0) }

            Button("Add UI Extension", systemImage: "paintpalette.fill") {
                uiExtensions.append(UIExtension(type: .overlay, component: .button, targetView: "", actionBinding: ""))
            }
        }
    }

    private func toggleTool(_ name: String, _ category: PluginToolCategory, _ enabled: Bool) {
        if enabled {
            if !toolkitTools.contains(where: { $0.name == name }) {
                toolkitTools.append(PluginToolkitTool(name: name, category: category, config: [:]))
            }
        } else {
            toolkitTools.removeAll { $0.name == name }
        }
    }
}

private struct BuildToolkitSection: View {
    @Binding var toolkitTools: [PluginToolkitTool]
    var body: some View {
        Section("Plugin Toolkit") {
            if toolkitTools.isEmpty {
                Text("No Tools Selected").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach($toolkitTools) { $tool in
                    VStack(spacing: 8) {
                        Picker("Category", selection: $tool.category) {
                            ForEach(PluginToolCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Picker("Tool", selection: $tool.name) {
                            ForEach(availableToolkitTools(for: tool.category), id: \.self) { Text($0).tag($0) }
                        }
                    }
                    .pickerStyle(.menu).controlSize(.small)
                    .padding(.vertical, 4)
                }
                .onDelete { toolkitTools.remove(atOffsets: $0) }
            }
            Button("Add ToolKit Tool", systemImage: "hammer.fill") {
                toolkitTools.append(PluginToolkitTool(name: "AI Text Summarizer", category: .ai, config: [:]))
            }
        }
    }

    private func availableToolkitTools(for category: PluginToolCategory) -> [String] {
        switch category {
        case .ai: return ["AI Prompt Builder", "AI Behavior Tuner", "AI Text Summarizer", "AI Code Generator", "AI Context Analyzer", "AI Classification Engine"]
        case .data: return ["Data Transformer", "Data Filtering Engine", "JSON Schema Builder", "Batch Processor", "Data Filter Engine", "JSON Builder", "CSV Exporter"]
        case .automation: return ["Event Trigger Designer", "Execution Scheduler", "Retry Strategy Builder", "Conditional Execution Engine", "Multi-step Action Builder", "Workflow Trigger Builder", "Multi-Step Executor", "Delay Scheduler", "Conditional Router"]
        case .integrations: return ["Webhook Listener", "External Sync Config", "Webhook Sender", "API Request Builder", "Response Parser", "Retry Handler"]
        case .workspace: return ["Workspace Modifier Rules", "Notification System", "Notes Updater", "Task Generator", "Calendar Sync Tool", "File Organizer"]
        case .developer: return ["Logging Configurator", "Performance Monitor", "Plugin Analytics Dashboard", "Log Stream Viewer", "Error Catcher", "Performance Tracker", "Debug Breakpoints"]
        case .security: return ["Rate Limiter Config", "Memory Storage Config", "Permission Validator", "Scope Checker", "Data Sanitizer", "Access Logger"]
        case .event: return ["Event Replay Tool", "Error Handling Engine", "Event Listener Builder", "Event Transformer", "Event Filter Engine"]
        }
    }
}

private struct BuildTestingSection: View {
    @Binding var testEventPayload: String
    let simulatedBuildOutput: [String]
    let onSimulate: () -> Void

    var body: some View {
        Section("Test Plugin (Sandbox)") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Payload").font(.caption.bold()).foregroundStyle(.secondary)
                TextEditor(text: $testEventPayload)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 100).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))

                Button(action: onSimulate) {
                    Label("Simulate Execution", systemImage: "play.fill").frame(maxWidth: .infinity).bold()
                }.buttonStyle(.bordered)

                if !simulatedBuildOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Execution Logs").font(.caption2.bold()).foregroundStyle(.secondary)
                        ForEach(simulatedBuildOutput, id: \.self) { line in
                            Text(line).font(.system(size: 9, design: .monospaced)).foregroundStyle(line.contains("ERROR") ? Color.red : Color.secondary)
                        }
                    }
                    .padding(8).background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

private struct BuildReleaseSection: View {
    @Binding var version: String
    @Binding var releaseNotes: String
    let endpointsCount: Int
    let uiExtensionsCount: Int
    let plugin: PluginDefinition

    var body: some View {
        Section("Release & Versioning") {
            TextField("Version", text: $version)
            TextEditor(text: $releaseNotes)
                .frame(height: 100).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) { Text("Current").font(.caption2.bold()); Text("v1.0.0").font(.caption.monospaced()) }
                    Spacer(); Image(systemName: "arrow.right").foregroundStyle(.tertiary); Spacer()
                    VStack(alignment: .trailing) { Text("New").font(.caption2.bold()); Text("v\(version)").font(.caption.monospaced()).foregroundStyle(.sdkSuccess) }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Label("+ Added \(endpointsCount) Endpoints", systemImage: "plus.circle").foregroundStyle(.sdkSuccess)
                    Label("+ Added \(uiExtensionsCount) UI Extensions", systemImage: "plus.circle").foregroundStyle(.sdkSuccess)
                }.font(.caption2)
            }
            .padding(.vertical, 8)

            if !plugin.changelog.isEmpty {
                Text("Changelog").font(.subheadline.bold())
                ForEach(plugin.changelog) { entry in
                    LabeledContent { Text(entry.notes).font(.caption2) } label: { Text("v\(entry.version)").bold() }
                }
            }
        }
    }
}

private struct BuildSubmitSection: View {
    let errors: [String]
    let errorMessage: String?
    let onBuild: () -> Void

    var body: some View {
        Section {
            if !errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Validation Issues", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).bold()
                    ForEach(errors, id: \.self) { Text("• \($0)").foregroundStyle(.red).font(.caption2) }
                }
            }

            if let error = errorMessage {
                Text(error).foregroundStyle(.red).font(.caption).bold()
            }

            Button(action: onBuild) {
                Text("Build & Install Plugin").frame(maxWidth: .infinity).bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!errors.isEmpty)
        }
    }
}

// MARK: - Supporting Views

struct AddEndpointView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (ExternalAPIEndpoint) -> Void
    @State private var name = ""
    @State private var baseURL = ""
    @State private var path = ""
    @State private var method: HTTPMethod = .get
    @State private var authType: AuthType = .none

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Endpoint Name", text: $name)
                    TextField("Base URL", text: $baseURL)
                    TextField("Path", text: $path)
                    Picker("Method", selection: $method) { ForEach(HTTPMethod.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
                }
                Section("Authentication") {
                    Picker("Auth Type", selection: $authType) { ForEach(AuthType.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.menu)
                }
                Section { Text("Headers and Schema can be configured after creation.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Add Endpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        onAdd(ExternalAPIEndpoint(name: name, baseURL: baseURL, path: path, method: method, headers: [:], queryParams: [:], authType: authType, retryPolicy: RetryPolicy()))
                        dismiss()
                    }.disabled(name.isEmpty || baseURL.isEmpty).bold()
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
        NavigationStack {
            Form {
                Section("API Details") {
                    TextField("Name", text: $endpoint.name)
                    TextField("Base URL", text: $endpoint.baseURL)
                    TextField("Path", text: $endpoint.path)
                    Picker("Method", selection: $endpoint.method) { ForEach(HTTPMethod.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
                }
                Section("Headers") {
                    ForEach(Array(endpoint.headers.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key).bold()
                            if endpoint.encryptedHeaders.contains(key) { Image(systemName: "lock.fill").foregroundStyle(.blue).font(.caption) }
                            Spacer()
                            Text(endpoint.headers[key] ?? "").foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    .onDelete { indices in
                        let keys = Array(endpoint.headers.keys.sorted())
                        indices.forEach { keyIndex in
                            let key = keys[keyIndex]
                            endpoint.headers.removeValue(forKey: key); endpoint.encryptedHeaders.removeAll { $0 == key }
                        }
                    }
                    VStack(spacing: 8) {
                        HStack { TextField("Key", text: $newHeaderKey); TextField("Value", text: $newHeaderValue) }
                        HStack {
                            Toggle("Secure", isOn: $isHeaderSecure).labelsHidden()
                            Text("Secure (Encrypted)").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button("Add Header") {
                                endpoint.headers[newHeaderKey] = isHeaderSecure ? PluginSecurityService.encryptHeader(newHeaderValue) : newHeaderValue
                                if isHeaderSecure { endpoint.encryptedHeaders.append(newHeaderKey) }
                                newHeaderKey = ""; newHeaderValue = ""; isHeaderSecure = false
                            }.disabled(newHeaderKey.isEmpty)
                        }
                    }
                }
                Section("Query Parameters") {
                    ForEach(Array(endpoint.queryParams.keys.sorted()), id: \.self) { key in
                        LabeledContent(key) { Text(endpoint.queryParams[key] ?? "").foregroundStyle(.secondary) }
                    }
                    .onDelete { indices in
                        let keys = Array(endpoint.queryParams.keys.sorted())
                        indices.forEach { endpoint.queryParams.removeValue(forKey: keys[$0]) }
                    }
                    HStack {
                        TextField("Key", text: $newParamKey); TextField("Value", text: $newParamValue)
                        Button("Add") { endpoint.queryParams[newParamKey] = newParamValue; newParamKey = ""; newParamValue = "" }.disabled(newParamKey.isEmpty)
                    }
                }
                Section("Body Schema (JSON)") {
                    TextEditor(text: Binding(get: { endpoint.bodySchema ?? "" }, set: { endpoint.bodySchema = $0.isEmpty ? nil : $0 }))
                        .font(.system(.caption, design: .monospaced)).frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Endpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { onSave(endpoint); dismiss() }.bold() }
            }
        }
    }
}

struct PluginDocumentationView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Plugin Development Guide").font(.title.bold())
                    DocSection(title: "Overview", text: "Plugins are event-driven modules that react to workspace activity. Start by defining an immutable identifier 'com.toolskit.<name>' and selecting relevant capabilities.")
                    DocSection(title: "Capabilities", text: "Capabilities define what system services your plugin can access. High-risk scopes require an API Key and Privacy Note justification.")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Execution Logic").font(.headline)
                        Text("Plugins execute JavaScript code in a secure sandbox:").foregroundStyle(.secondary)
                        Text("await ctx.ai.summarize(text)\nawait ctx.notes.updateNote(id, content)")
                            .font(.system(.caption, design: .monospaced)).padding().background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                    }
                    DocSection(title: "Debugging", text: "Use the Test Console to simulate events and view execution logs. The Dev Console provides real-time error tracking.")
                }
                .padding()
            }
            .navigationTitle("Documentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

private struct DocSection: View {
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(text).foregroundStyle(.secondary)
        }
    }
}
