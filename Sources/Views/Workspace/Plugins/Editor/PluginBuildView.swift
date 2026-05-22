

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
    @State private var homepage = ""
    @State private var license = "MIT"
    @State private var category: PluginMarketCategory = .utility
    @State private var tags: [String] = []
    @State private var minPlatformVersion = "1.0"
    @State private var supportEmail = ""

    // Capabilities & Actions
    @State private var selectedCapabilities: Set<PluginCapability> = []
    @State private var selectedActions: Set<PluginAction> = []

    // Security Scopes (High-Risk)
    @State private var apiKey: String?
    @State private var privacyNote: String?
    @State private var dataUsageExplanation: String?
    @State private var retentionPolicy: String?
    @State private var sandboxMode: SandboxExecutionMode = .strict
    @State private var ipAllowlist: [String] = []
    @State private var rateLimitPerMinute: Int = 60
    @State private var signatureVerification = true
    @State private var contentSecurityPolicy = "default-src 'self'"

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
    @State private var endpointHealthChecks = true
    @State private var endpointTimeoutMs: Int = 5000
    @State private var endpointCircuitBreakerThreshold: Int = 5
    @State private var endpointCacheTTL: Int = 0

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
    @State private var releaseChannel: ReleaseChannel = .stable
    @State private var rolloutPercentage: Double = 100
    @State private var deprecationNotice = ""
    @State private var migrationGuide = ""
    @State private var signRelease = true
    @State private var previousVersions: [String] = []

    // Testing
    @State private var testSuites: [PluginTestSuite] = []
    @State private var coverageTarget: Double = 80
    @State private var enableLoadTesting = false
    @State private var loadTestConcurrency: Int = 10
    @State private var loadTestDuration: Int = 30
    @State private var mockResponses: [String: String] = [:]

    @State private var testEventPayload = """
{"type":"","payload":{}}
"""
    @State private var simulatedBuildOutput: [String] = []

    // Webhooks
    @State private var webhooks: [PluginWebhookConfig] = []
    @State private var webhookRetryCount: Int = 3
    @State private var webhookDeliveryTimeout: Int = 10

    // Localization
    @State private var supportedLocales: [PluginLocaleEntry] = []
    @State private var defaultLocale = "en"
    @State private var autoDetectLocale = true

    // Analytics
    @State private var analyticsEnabled = true
    @State private var trackUsageEvents = true
    @State private var trackPerformanceMetrics = true
    @State private var analyticsRetentionDays: Int = 90
    @State private var customAnalyticsEvents: [String] = []

    // Collaboration
    @State private var collaborationEnabled = false
    @State private var maxCollaborators: Int = 5
    @State private var collaboratorEmails: [String] = []
    @State private var sharePermission: PluginSharePermission = .readOnly

    // Scheduling
    @State private var scheduledTasks: [PluginScheduledTask] = []
    @State private var enableBackgroundExecution = false
    @State private var maxConcurrentScheduledTasks: Int = 3

    // Notifications
    @State private var notificationRules: [PluginNotificationRule] = []
    @State private var enablePushNotifications = false
    @State private var enableEmailNotifications = false
    @State private var notificationThrottleSeconds: Int = 60

    // Feature Flags
    @State private var featureFlags: [PluginFeatureFlag] = []
    @State private var enableRemoteConfig = false

    // Accessibility
    @State private var accessibilityLabelsEnabled = true
    @State private var dynamicTypeSupport = true
    @State private var reduceMotionSupport = true
    @State private var voiceOverOptimized = true
    @State private var highContrastMode = false
    @State private var minimumTouchTarget: Int = 44

    // Backup & Restore
    @State private var autoBackupEnabled = false
    @State private var backupFrequencyHours: Int = 24
    @State private var maxBackupCount: Int = 5
    @State private var backupEncryption = true
    @State private var lastBackupDate: Date?

    // Logging
    @State private var logLevel: PluginLogLevel = .info
    @State private var enableRemoteLogging = false
    @State private var logRetentionDays: Int = 30
    @State private var sensitiveDataMasking = true
    @State private var structuredLogging = true

    // Build Pipeline
    @State private var buildPipelineStages: [PluginBuildStage] = []
    @State private var enableContinuousIntegration = false
    @State private var autoRunTestsOnBuild = true
    @State private var enableLinting = true
    @State private var enableMinification = false

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
        case webhooks = "Webhooks"
        case localization = "Localization"
        case analytics = "Analytics"
        case collaboration = "Collaboration"
        case scheduling = "Scheduling"
        case notifications = "Notifications"
        case featureFlags = "Feature Flags"
        case accessibility = "Accessibility"
        case backup = "Backup"
        case logging = "Logging"
        case pipeline = "Pipeline"
        case release = "Release"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Navigation", selection: $selectedSection) {
                        ForEach(BuildSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.menu)
                }

                sectionContent
                BuildSubmitSection(errors: performStrictValidation(), errorMessage: errorMessage) { buildAndInstall() }
            }
            .navigationTitle("Plugin Builder")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingDocs = true } label: { Label("Documentation", systemImage: "book.closed") }
                }
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

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .identity:
            BuildIdentitySection(name: $name, description: $description, author: $author, version: $version, identifier: $identifier, isLocked: isIdentifierLocked, homepage: $homepage, license: $license, category: $category, tags: $tags, minPlatformVersion: $minPlatformVersion, supportEmail: $supportEmail) {
                if isIdentifierLocked { showingIdentifierLockAlert = true }
            }
        case .capabilities:
            BuildCapabilitiesSection(selectedCapabilities: $selectedCapabilities, selectedActions: $selectedActions)
        case .security:
            BuildSecuritySection(selectedCapabilities: selectedCapabilities, apiKey: apiKey, privacyNote: privacyNote, plugin: currentPluginSnapshot, sandboxMode: $sandboxMode, ipAllowlist: $ipAllowlist, rateLimitPerMinute: $rateLimitPerMinute, signatureVerification: $signatureVerification, contentSecurityPolicy: $contentSecurityPolicy) { updated in
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
            BuildEndpointsSection(endpoints: $endpoints, healthChecks: $endpointHealthChecks, timeoutMs: $endpointTimeoutMs, circuitBreakerThreshold: $endpointCircuitBreakerThreshold, cacheTTL: $endpointCacheTTL) { showingAddEndpoint = true } onEdit: { selectedEndpointForEdit = $0 }
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
            BuildTestingSection(testEventPayload: $testEventPayload, simulatedBuildOutput: simulatedBuildOutput, testSuites: $testSuites, coverageTarget: $coverageTarget, enableLoadTesting: $enableLoadTesting, loadTestConcurrency: $loadTestConcurrency, loadTestDuration: $loadTestDuration, mockResponses: $mockResponses) { runLocalValidation() }
        case .webhooks:
            BuildWebhooksSection(webhooks: $webhooks, retryCount: $webhookRetryCount, deliveryTimeout: $webhookDeliveryTimeout)
        case .localization:
            BuildLocalizationSection(supportedLocales: $supportedLocales, defaultLocale: $defaultLocale, autoDetectLocale: $autoDetectLocale)
        case .analytics:
            BuildAnalyticsSection(analyticsEnabled: $analyticsEnabled, trackUsageEvents: $trackUsageEvents, trackPerformanceMetrics: $trackPerformanceMetrics, retentionDays: $analyticsRetentionDays, customEvents: $customAnalyticsEvents)
        case .collaboration:
            BuildCollaborationSection(enabled: $collaborationEnabled, maxCollaborators: $maxCollaborators, collaboratorEmails: $collaboratorEmails, sharePermission: $sharePermission)
        case .scheduling:
            BuildSchedulingSection(scheduledTasks: $scheduledTasks, enableBackgroundExecution: $enableBackgroundExecution, maxConcurrent: $maxConcurrentScheduledTasks)
        case .notifications:
            BuildNotificationsSection(rules: $notificationRules, enablePush: $enablePushNotifications, enableEmail: $enableEmailNotifications, throttleSeconds: $notificationThrottleSeconds)
        case .featureFlags:
            BuildFeatureFlagsSection(featureFlags: $featureFlags, enableRemoteConfig: $enableRemoteConfig)
        case .accessibility:
            BuildAccessibilitySection(labelsEnabled: $accessibilityLabelsEnabled, dynamicType: $dynamicTypeSupport, reduceMotion: $reduceMotionSupport, voiceOver: $voiceOverOptimized, highContrast: $highContrastMode, minTouchTarget: $minimumTouchTarget)
        case .backup:
            BuildBackupSection(autoBackup: $autoBackupEnabled, frequencyHours: $backupFrequencyHours, maxCount: $maxBackupCount, encryption: $backupEncryption, lastBackup: lastBackupDate)
        case .logging:
            BuildLoggingSection(logLevel: $logLevel, remoteLogging: $enableRemoteLogging, retentionDays: $logRetentionDays, dataMasking: $sensitiveDataMasking, structured: $structuredLogging)
        case .pipeline:
            BuildPipelineSection(stages: $buildPipelineStages, ciEnabled: $enableContinuousIntegration, autoTests: $autoRunTestsOnBuild, linting: $enableLinting, minification: $enableMinification)
        case .release:
            BuildReleaseSection(version: $version, releaseNotes: $releaseNotes, endpointsCount: endpoints.count, uiExtensionsCount: uiExtensions.count, plugin: currentPluginSnapshot, releaseChannel: $releaseChannel, rolloutPercentage: $rolloutPercentage, deprecationNotice: $deprecationNotice, migrationGuide: $migrationGuide, signRelease: $signRelease, previousVersions: $previousVersions)
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
    @Binding var homepage: String
    @Binding var license: String
    @Binding var category: PluginMarketCategory
    @Binding var tags: [String]
    @Binding var minPlatformVersion: String
    @Binding var supportEmail: String
    let onLockedTap: () -> Void

    @State private var newTag = ""

    private let licenseOptions = ["MIT", "Apache-2.0", "GPL-3.0", "BSD-2-Clause", "ISC", "Proprietary", "Custom"]

    var body: some View {
        Section {
            TextField("Name", text: $name)
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
            TextField("Author", text: $author)
            TextField("Version (semver)", text: $version)

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

        Section {
            Picker("Category", selection: $category) {
                ForEach(PluginMarketCategory.allCases) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.menu)

            Picker("License", selection: $license) {
                ForEach(licenseOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)

            TextField("Homepage URL", text: $homepage)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            TextField("Support Email", text: $supportEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            TextField("Min Platform Version", text: $minPlatformVersion)
                .keyboardType(.decimalPad)
        } header: {
            Label("Metadata & Distribution", systemImage: "tag.fill")
        }

        Section {
            if tags.isEmpty {
                Text("No tags added.").font(.caption).foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag).font(.caption2.bold())
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").font(.caption2)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
                    tags.append(trimmed)
                    newTag = ""
                }.disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Label("Tags", systemImage: "number")
        } footer: {
            Text("Tags help users discover your plugin in the marketplace.")
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
                        if isSelected {
                            selectedCapabilities.insert(cap)
                        } else {
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

        if selectedCapabilities.isEmpty {
            Section {
                ContentUnavailableView("No Capabilities", systemImage: "shield.slash", description: Text("Select capabilities above to enable specific action scopes."))
                    .scaleEffect(0.8)
            } header: {
                Label("Action Scopes", systemImage: "target")
            }
        } else {
            Section {
                ForEach(Array(PluginAction.allCases.filter { selectedCapabilities.contains($0.parentCapability) }), id: \.self) { action in
                    Toggle(
                        isOn: Binding(
                            get: { selectedActions.contains(action) },
                            set: { isSelected in
                                if isSelected {
                                    selectedActions.insert(action)
                                } else {
                                    selectedActions.remove(action)
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading) {
                            Text(action.rawValue).font(.subheadline.bold())
                            Text(action.description).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Action Scopes", systemImage: "target")
            }
        }
    }
}

private struct BuildSecuritySection: View {
    let selectedCapabilities: Set<PluginCapability>
    let apiKey: String?
    let privacyNote: String?
    let plugin: PluginDefinition
    @Binding var sandboxMode: SandboxExecutionMode
    @Binding var ipAllowlist: [String]
    @Binding var rateLimitPerMinute: Int
    @Binding var signatureVerification: Bool
    @Binding var contentSecurityPolicy: String
    let onUpdate: (PluginDefinition) -> Void

    @State private var newIP = ""

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

        Section {
            Picker("Sandbox Mode", selection: $sandboxMode) {
                ForEach(SandboxExecutionMode.allCases) { mode in
                    VStack(alignment: .leading) {
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 4) {
                Text(sandboxMode.description)
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Toggle(isOn: $signatureVerification) {
                Label("Request Signature Verification", systemImage: "signature")
            }

            VStack(alignment: .leading) {
                HStack {
                    Label("Rate Limit", systemImage: "speedometer")
                    Spacer()
                    Text("\(rateLimitPerMinute) req/min").bold().font(.caption)
                }
                Slider(value: Binding(get: { Double(rateLimitPerMinute) }, set: { rateLimitPerMinute = Int($0) }), in: 1...1000, step: 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("Content Security Policy", systemImage: "shield.lefthalf.filled").font(.caption.bold()).foregroundStyle(.secondary)
                TextField("CSP directive", text: $contentSecurityPolicy)
                    .font(.system(.caption, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
            }
        } header: {
            Label("Execution Sandbox", systemImage: "lock.rectangle.stack.fill")
        } footer: {
            Text("Sandbox mode controls the level of isolation for plugin execution.")
        }

        Section {
            if ipAllowlist.isEmpty {
                Text("No IP restrictions (all IPs allowed).").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(ipAllowlist, id: \.self) { ip in
                    HStack {
                        Text(ip).font(.caption.monospaced())
                        Spacer()
                        Button { ipAllowlist.removeAll { $0 == ip } } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                    }
                }
            }
            HStack {
                TextField("IP or CIDR (e.g. 10.0.0.0/8)", text: $newIP)
                    .font(.caption.monospaced())
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    guard !newIP.isEmpty else { return }
                    ipAllowlist.append(newIP)
                    newIP = ""
                }.disabled(newIP.isEmpty)
            }
        } header: {
            Label("Network Allowlist", systemImage: "network.badge.shield.half.filled")
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
    @Binding var healthChecks: Bool
    @Binding var timeoutMs: Int
    @Binding var circuitBreakerThreshold: Int
    @Binding var cacheTTL: Int
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

        Section {
            Toggle(isOn: $healthChecks) {
                Label("Health Check Monitoring", systemImage: "heart.text.square")
            }

            VStack(alignment: .leading) {
                HStack {
                    Label("Request Timeout", systemImage: "timer")
                    Spacer()
                    Text("\(timeoutMs) ms").bold().font(.caption)
                }
                Slider(value: Binding(get: { Double(timeoutMs) }, set: { timeoutMs = Int($0) }), in: 500...30000, step: 500)
            }

            Stepper(value: $circuitBreakerThreshold, in: 1...50) {
                HStack {
                    Label("Circuit Breaker", systemImage: "bolt.trianglebadge.exclamationmark")
                    Spacer()
                    Text("\(circuitBreakerThreshold) failures").bold().font(.caption)
                }
            }

            VStack(alignment: .leading) {
                HStack {
                    Label("Response Cache TTL", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Text(cacheTTL == 0 ? "Disabled" : "\(cacheTTL)s").bold().font(.caption)
                }
                Slider(value: Binding(get: { Double(cacheTTL) }, set: { cacheTTL = Int($0) }), in: 0...3600, step: 30)
            }
        } header: {
            Label("Endpoint Resilience", systemImage: "arrow.triangle.2.circlepath")
        } footer: {
            Text("Circuit breaker opens after consecutive failures, preventing cascading errors.")
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
                    MappingRow(mapping: $mapping)
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

private struct MappingRow: View {
    @Binding var mapping: DataMapping

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Source (e.g. event.note.content)", text: $mapping.sourceField).font(.caption.monospaced())
            TextField("Target (e.g. payload.body.text)", text: $mapping.targetField).font(.caption.monospaced())
            if mapping.transformer != nil {
                TextField("Transformer Logic", text: Binding(
                    get: { mapping.transformer ?? "" },
                    set: { mapping.transformer = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
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
                    ExecutionRuleRow(rule: $rule)
                }
                .onDelete { executionRules.remove(atOffsets: $0) }
            }
            Button("Add Rule", systemImage: "checklist") {
                executionRules.append(ExecutionRule(type: .eventFilter, condition: "true"))
            }
        }
    }
}

private struct ExecutionRuleRow: View {
    @Binding var rule: ExecutionRule

    var body: some View {
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
                UIExtensionRow(ext: $ext)
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

private struct UIExtensionRow: View {
    @Binding var ext: UIExtension

    var body: some View {
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
}

private struct BuildToolkitSection: View {
    @Binding var toolkitTools: [PluginToolkitTool]
    var body: some View {
        Section("Plugin Toolkit") {
            if toolkitTools.isEmpty {
                Text("No Tools Selected").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach($toolkitTools) { $tool in
                    ToolkitToolRow(tool: $tool)
                }
                .onDelete { toolkitTools.remove(atOffsets: $0) }
            }
            Button("Add ToolKit Tool", systemImage: "hammer.fill") {
                toolkitTools.append(PluginToolkitTool(name: "AI Text Summarizer", category: .ai, config: [:]))
            }
        }
    }
}

private struct ToolkitToolRow: View {
    @Binding var tool: PluginToolkitTool

    var body: some View {
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
    @Binding var testSuites: [PluginTestSuite]
    @Binding var coverageTarget: Double
    @Binding var enableLoadTesting: Bool
    @Binding var loadTestConcurrency: Int
    @Binding var loadTestDuration: Int
    @Binding var mockResponses: [String: String]
    let onSimulate: () -> Void

    @State private var newMockKey = ""
    @State private var newMockValue = ""

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

        Section {
            VStack(alignment: .leading) {
                HStack {
                    Label("Coverage Target", systemImage: "percent")
                    Spacer()
                    Text("\(Int(coverageTarget))%").bold().font(.caption)
                        .foregroundStyle(coverageTarget >= 80 ? .green : (coverageTarget >= 50 ? .orange : .red))
                }
                Slider(value: $coverageTarget, in: 0...100, step: 5)
            }

            if testSuites.isEmpty {
                Text("No test suites defined.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach($testSuites) { $suite in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(suite.name).font(.subheadline.bold())
                            Spacer()
                            if let rate = suite.passRate {
                                Text("\(Int(rate))% pass")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(rate >= 80 ? Color.green.opacity(0.12) : Color.red.opacity(0.12), in: Capsule())
                                    .foregroundStyle(rate >= 80 ? .green : .red)
                            }
                        }
                        Text("\(suite.testCases.count) test case(s)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .onDelete { testSuites.remove(atOffsets: $0) }
            }

            Button("Add Test Suite", systemImage: "testtube.2") {
                testSuites.append(PluginTestSuite(name: "Suite \(testSuites.count + 1)", testCases: [
                    PluginTestCase(name: "Default Test", input: "{}", expectedOutput: "{\"ok\":true}")
                ]))
            }
        } header: {
            Label("Test Suites & Coverage", systemImage: "checkmark.circle.trianglebadge.exclamationmark")
        }

        Section {
            Toggle(isOn: $enableLoadTesting) {
                Label("Enable Load Testing", systemImage: "bolt.horizontal.fill")
            }

            if enableLoadTesting {
                Stepper(value: $loadTestConcurrency, in: 1...100) {
                    HStack {
                        Label("Concurrency", systemImage: "person.3.sequence")
                        Spacer()
                        Text("\(loadTestConcurrency) threads").bold().font(.caption)
                    }
                }

                Stepper(value: $loadTestDuration, in: 5...300, step: 5) {
                    HStack {
                        Label("Duration", systemImage: "timer")
                        Spacer()
                        Text("\(loadTestDuration)s").bold().font(.caption)
                    }
                }
            }
        } header: {
            Label("Performance Testing", systemImage: "gauge.with.needle.fill")
        }

        Section {
            if mockResponses.isEmpty {
                Text("No mock responses configured.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(mockResponses.keys.sorted()), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(key).font(.caption.monospaced().bold())
                        Text(mockResponses[key] ?? "").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
            }
            HStack {
                TextField("Endpoint path", text: $newMockKey).font(.caption.monospaced())
                TextField("JSON response", text: $newMockValue).font(.caption.monospaced())
                Button("Add") {
                    mockResponses[newMockKey] = newMockValue
                    newMockKey = ""; newMockValue = ""
                }.disabled(newMockKey.isEmpty)
            }
        } header: {
            Label("Mock Responses", systemImage: "doc.badge.gearshape")
        } footer: {
            Text("Define mock API responses for testing without live endpoints.")
        }
    }
}

private struct BuildReleaseSection: View {
    @Binding var version: String
    @Binding var releaseNotes: String
    let endpointsCount: Int
    let uiExtensionsCount: Int
    let plugin: PluginDefinition
    @Binding var releaseChannel: ReleaseChannel
    @Binding var rolloutPercentage: Double
    @Binding var deprecationNotice: String
    @Binding var migrationGuide: String
    @Binding var signRelease: Bool
    @Binding var previousVersions: [String]

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

        Section {
            Picker("Release Channel", selection: $releaseChannel) {
                ForEach(ReleaseChannel.allCases) { channel in
                    Label(channel.rawValue.capitalized, systemImage: channel.icon).tag(channel)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Image(systemName: releaseChannel.icon)
                    .foregroundStyle(releaseChannel.color)
                Text(releaseChannel.rawValue.capitalized)
                    .font(.caption.bold())
                    .foregroundStyle(releaseChannel.color)
                Spacer()
            }
            .padding(8)
            .background(releaseChannel.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                HStack {
                    Label("Rollout Percentage", systemImage: "chart.bar.fill")
                    Spacer()
                    Text("\(Int(rolloutPercentage))%").bold().font(.caption)
                }
                Slider(value: $rolloutPercentage, in: 1...100, step: 1)
            }

            Toggle(isOn: $signRelease) {
                Label("Code Sign Release", systemImage: "signature")
            }
        } header: {
            Label("Distribution Strategy", systemImage: "shippingbox.and.arrow.backward")
        } footer: {
            Text("Canary and nightly channels auto-expire after 72 hours.")
        }

        Section {
            VStack(alignment: .leading, spacing: 4) {
                Label("Deprecation Notice", systemImage: "exclamationmark.triangle").font(.caption.bold()).foregroundStyle(.secondary)
                TextField("Explain what's deprecated and why...", text: $deprecationNotice, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("Migration Guide", systemImage: "arrow.right.arrow.left").font(.caption.bold()).foregroundStyle(.secondary)
                TextEditor(text: $migrationGuide)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 60)
                    .padding(4)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            }
        } header: {
            Label("Lifecycle Management", systemImage: "arrow.triangle.branch")
        } footer: {
            Text("Provide migration instructions for breaking changes to ease user transitions.")
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

// MARK: - Webhooks Section

private struct BuildWebhooksSection: View {
    @Binding var webhooks: [PluginWebhookConfig]
    @Binding var retryCount: Int
    @Binding var deliveryTimeout: Int

    @State private var newWebhookURL = ""
    @State private var newWebhookSecret = ""
    @State private var newWebhookEvents: Set<String> = []

    private let eventTypes = ["plugin.installed", "plugin.enabled", "plugin.disabled", "plugin.error", "plugin.executed", "data.created", "data.updated", "data.deleted", "user.action", "system.alert"]

    var body: some View {
        Section {
            if webhooks.isEmpty {
                ContentUnavailableView("No Webhooks", systemImage: "antenna.radiowaves.left.and.right", description: Text("Add webhook endpoints to receive real-time event notifications."))
                    .scaleEffect(0.8)
            } else {
                ForEach(webhooks) { webhook in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: webhook.isActive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                                .foregroundStyle(webhook.isActive ? .green : .secondary)
                            Text(webhook.url).font(.caption.monospaced()).lineLimit(1)
                        }
                        Text("\(webhook.events.count) event(s) subscribed").font(.caption2).foregroundStyle(.secondary)
                        if webhook.hasSecret {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill").font(.system(size: 8))
                                Text("HMAC Signed").font(.system(size: 8, weight: .bold))
                            }.foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { webhooks.remove(atOffsets: $0) }
            }
        } header: {
            Label("Webhook Endpoints", systemImage: "arrow.up.right.and.arrow.down.left.rectangle.fill")
        }

        Section {
            TextField("Webhook URL", text: $newWebhookURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .font(.caption.monospaced())

            TextField("Signing Secret (optional)", text: $newWebhookSecret)
                .textInputAutocapitalization(.never)
                .font(.caption.monospaced())

            VStack(alignment: .leading, spacing: 6) {
                Text("Subscribe to Events").font(.caption.bold()).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 6) {
                    ForEach(eventTypes, id: \.self) { event in
                        Button {
                            if newWebhookEvents.contains(event) { newWebhookEvents.remove(event) }
                            else { newWebhookEvents.insert(event) }
                        } label: {
                            Text(event)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                                .background(newWebhookEvents.contains(event) ? Color.blue : Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(newWebhookEvents.contains(event) ? .white : .primary)
                        }
                    }
                }
            }

            Button("Add Webhook", systemImage: "plus.circle.fill") {
                guard !newWebhookURL.isEmpty else { return }
                webhooks.append(PluginWebhookConfig(url: newWebhookURL, secret: newWebhookSecret.isEmpty ? nil : newWebhookSecret, events: Array(newWebhookEvents), isActive: true))
                newWebhookURL = ""; newWebhookSecret = ""; newWebhookEvents = []
            }
            .disabled(newWebhookURL.isEmpty || newWebhookEvents.isEmpty)
        } header: {
            Label("Add Webhook", systemImage: "plus.app")
        }

        Section {
            Stepper(value: $retryCount, in: 0...10) {
                HStack {
                    Label("Retry Attempts", systemImage: "arrow.counterclockwise")
                    Spacer()
                    Text("\(retryCount)").bold().font(.caption)
                }
            }
            Stepper(value: $deliveryTimeout, in: 1...60) {
                HStack {
                    Label("Delivery Timeout", systemImage: "timer")
                    Spacer()
                    Text("\(deliveryTimeout)s").bold().font(.caption)
                }
            }
        } header: {
            Label("Webhook Delivery Settings", systemImage: "gear")
        } footer: {
            Text("Failed deliveries will be retried with exponential backoff.")
        }
    }
}

// MARK: - Localization Section

private struct BuildLocalizationSection: View {
    @Binding var supportedLocales: [PluginLocaleEntry]
    @Binding var defaultLocale: String
    @Binding var autoDetectLocale: Bool

    @State private var newLocaleCode = ""
    @State private var newLocaleLabel = ""

    private let commonLocales = ["en", "es", "fr", "de", "ja", "ko", "zh", "pt", "it", "ru", "ar", "hi"]

    var body: some View {
        Section {
            Picker("Default Locale", selection: $defaultLocale) {
                ForEach(commonLocales, id: \.self) { code in
                    Text(code.uppercased()).tag(code)
                }
            }
            .pickerStyle(.menu)

            Toggle(isOn: $autoDetectLocale) {
                Label("Auto-Detect User Locale", systemImage: "globe")
            }
        } header: {
            Label("Locale Settings", systemImage: "character.bubble.fill")
        }

        Section {
            if supportedLocales.isEmpty {
                Text("No locales configured. The default locale will be used.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(supportedLocales) { locale in
                    HStack {
                        Text(locale.code.uppercased())
                            .font(.caption.bold().monospaced())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                        Text(locale.displayLabel).font(.caption)
                        Spacer()
                        if locale.code == defaultLocale {
                            Text("Default").font(.system(size: 8, weight: .black)).foregroundStyle(.blue)
                        }
                        Text("\(locale.translatedKeys) keys").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .onDelete { supportedLocales.remove(atOffsets: $0) }
            }

            HStack {
                TextField("Code (e.g. es)", text: $newLocaleCode)
                    .textInputAutocapitalization(.never)
                    .font(.caption.monospaced())
                TextField("Label (e.g. Spanish)", text: $newLocaleLabel)
                    .font(.caption)
                Button("Add") {
                    guard !newLocaleCode.isEmpty else { return }
                    supportedLocales.append(PluginLocaleEntry(code: newLocaleCode.lowercased(), displayLabel: newLocaleLabel.isEmpty ? newLocaleCode.uppercased() : newLocaleLabel))
                    newLocaleCode = ""; newLocaleLabel = ""
                }.disabled(newLocaleCode.isEmpty)
            }
        } header: {
            Label("Supported Locales", systemImage: "textformat")
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add Common Locales").font(.caption.bold()).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(commonLocales, id: \.self) { locale in
                            let exists = supportedLocales.contains { $0.code == locale }
                            Button {
                                if !exists {
                                    supportedLocales.append(PluginLocaleEntry(code: locale, displayLabel: locale.uppercased()))
                                }
                            } label: {
                                Text(locale.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(exists ? Color.green.opacity(0.2) : Color(.tertiarySystemBackground), in: Capsule())
                                    .foregroundStyle(exists ? .green : .primary)
                            }
                            .disabled(exists)
                        }
                    }
                }
            }
        } header: {
            Label("Quick Add", systemImage: "bolt.fill")
        }
    }
}

// MARK: - Analytics Section

private struct BuildAnalyticsSection: View {
    @Binding var analyticsEnabled: Bool
    @Binding var trackUsageEvents: Bool
    @Binding var trackPerformanceMetrics: Bool
    @Binding var retentionDays: Int
    @Binding var customEvents: [String]

    @State private var newEvent = ""

    var body: some View {
        Section {
            Toggle(isOn: $analyticsEnabled) {
                Label("Enable Analytics", systemImage: "chart.xyaxis.line")
            }

            if analyticsEnabled {
                Toggle(isOn: $trackUsageEvents) {
                    Label("Track Usage Events", systemImage: "hand.tap.fill")
                }
                Toggle(isOn: $trackPerformanceMetrics) {
                    Label("Track Performance Metrics", systemImage: "gauge.with.needle.fill")
                }

                Stepper(value: $retentionDays, in: 7...365, step: 7) {
                    HStack {
                        Label("Data Retention", systemImage: "calendar")
                        Spacer()
                        Text("\(retentionDays) days").bold().font(.caption)
                    }
                }
            }
        } header: {
            Label("Analytics Configuration", systemImage: "chart.bar.fill")
        } footer: {
            Text("Analytics data is collected in compliance with your privacy policy and retention settings.")
        }

        if analyticsEnabled {
            Section {
                if customEvents.isEmpty {
                    Text("No custom analytics events defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(customEvents, id: \.self) { event in
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(.blue).font(.caption)
                            Text(event).font(.caption.monospaced())
                            Spacer()
                            Button { customEvents.removeAll { $0 == event } } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                }
                HStack {
                    TextField("Custom event name", text: $newEvent)
                        .textInputAutocapitalization(.never).font(.caption.monospaced())
                    Button("Add") {
                        guard !newEvent.isEmpty else { return }
                        customEvents.append(newEvent); newEvent = ""
                    }.disabled(newEvent.isEmpty)
                }
            } header: {
                Label("Custom Events", systemImage: "list.bullet.rectangle")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built-in Tracked Metrics").font(.caption.bold()).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        AnalyticsMetricChip(name: "Installs", icon: "arrow.down.circle")
                        AnalyticsMetricChip(name: "Executions", icon: "play.circle")
                        AnalyticsMetricChip(name: "Errors", icon: "exclamationmark.circle")
                    }
                    HStack(spacing: 12) {
                        AnalyticsMetricChip(name: "Latency", icon: "clock")
                        AnalyticsMetricChip(name: "Memory", icon: "memorychip")
                        AnalyticsMetricChip(name: "CPU", icon: "cpu")
                    }
                }
            } header: {
                Label("Built-in Metrics", systemImage: "speedometer")
            }
        }
    }
}

private struct AnalyticsMetricChip: View {
    let name: String
    let icon: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9))
            Text(name).font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.blue.opacity(0.1), in: Capsule())
        .foregroundStyle(.blue)
    }
}

// MARK: - Collaboration Section

private struct BuildCollaborationSection: View {
    @Binding var enabled: Bool
    @Binding var maxCollaborators: Int
    @Binding var collaboratorEmails: [String]
    @Binding var sharePermission: PluginSharePermission

    @State private var newEmail = ""

    var body: some View {
        Section {
            Toggle(isOn: $enabled) {
                Label("Enable Collaboration", systemImage: "person.2.fill")
            }

            if enabled {
                Picker("Default Permission", selection: $sharePermission) {
                    ForEach(PluginSharePermission.allCases, id: \.self) { perm in
                        Text(perm.rawValue).tag(perm)
                    }
                }
                .pickerStyle(.menu)

                Stepper(value: $maxCollaborators, in: 1...50) {
                    HStack {
                        Label("Max Collaborators", systemImage: "person.3.fill")
                        Spacer()
                        Text("\(maxCollaborators)").bold().font(.caption)
                    }
                }
            }
        } header: {
            Label("Collaboration Settings", systemImage: "person.2.badge.gearshape.fill")
        }

        if enabled {
            Section {
                if collaboratorEmails.isEmpty {
                    Text("No collaborators added.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(collaboratorEmails, id: \.self) { email in
                        HStack {
                            Image(systemName: "person.crop.circle").foregroundStyle(.blue).font(.caption)
                            Text(email).font(.caption)
                            Spacer()
                            Button { collaboratorEmails.removeAll { $0 == email } } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                }
                HStack {
                    TextField("Collaborator email", text: $newEmail)
                        .textInputAutocapitalization(.never).keyboardType(.emailAddress).font(.caption)
                    Button("Invite") {
                        guard !newEmail.isEmpty else { return }
                        collaboratorEmails.append(newEmail); newEmail = ""
                    }.disabled(newEmail.isEmpty)
                }
            } header: {
                Label("Collaborators", systemImage: "person.badge.plus")
            } footer: {
                Text("Collaborators will receive an invitation to co-develop this plugin.")
            }
        }
    }
}

// MARK: - Scheduling Section

private struct BuildSchedulingSection: View {
    @Binding var scheduledTasks: [PluginScheduledTask]
    @Binding var enableBackgroundExecution: Bool
    @Binding var maxConcurrent: Int

    @State private var newTaskName = ""
    @State private var newCronExpression = ""
    @State private var newTaskAction = ""

    var body: some View {
        Section {
            Toggle(isOn: $enableBackgroundExecution) {
                Label("Background Execution", systemImage: "clock.arrow.2.circlepath")
            }

            if enableBackgroundExecution {
                Stepper(value: $maxConcurrent, in: 1...20) {
                    HStack {
                        Label("Max Concurrent Tasks", systemImage: "rectangle.3.group")
                        Spacer()
                        Text("\(maxConcurrent)").bold().font(.caption)
                    }
                }
            }
        } header: {
            Label("Scheduling Settings", systemImage: "calendar.badge.clock")
        }

        Section {
            if scheduledTasks.isEmpty {
                ContentUnavailableView("No Scheduled Tasks", systemImage: "clock.badge.questionmark", description: Text("Add scheduled tasks to run plugin logic on a recurring basis."))
                    .scaleEffect(0.8)
            } else {
                ForEach(scheduledTasks) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: task.isEnabled ? "clock.fill" : "clock")
                                .foregroundStyle(task.isEnabled ? .blue : .secondary)
                            Text(task.name).font(.subheadline.bold())
                            Spacer()
                            Text(task.isEnabled ? "Active" : "Paused")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(task.isEnabled ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12), in: Capsule())
                                .foregroundStyle(task.isEnabled ? .green : .secondary)
                        }
                        Text(task.cronExpression).font(.caption2.monospaced()).foregroundStyle(.secondary)
                        Text(task.action).font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { scheduledTasks.remove(atOffsets: $0) }
            }
        } header: {
            Label("Scheduled Tasks", systemImage: "list.bullet.below.rectangle")
        }

        Section {
            TextField("Task Name", text: $newTaskName).font(.caption)
            TextField("Cron Expression (e.g. */5 * * * *)", text: $newCronExpression).font(.caption.monospaced())
            TextField("Action (function name)", text: $newTaskAction).font(.caption.monospaced())
            Button("Add Scheduled Task", systemImage: "plus.circle.fill") {
                guard !newTaskName.isEmpty, !newCronExpression.isEmpty else { return }
                scheduledTasks.append(PluginScheduledTask(name: newTaskName, cronExpression: newCronExpression, action: newTaskAction.isEmpty ? "onSchedule" : newTaskAction))
                newTaskName = ""; newCronExpression = ""; newTaskAction = ""
            }
            .disabled(newTaskName.isEmpty || newCronExpression.isEmpty)
        } header: {
            Label("Add Task", systemImage: "plus.app")
        } footer: {
            Text("Cron expressions follow the standard 5-field format: minute hour day month weekday.")
        }
    }
}

// MARK: - Notifications Section

private struct BuildNotificationsSection: View {
    @Binding var rules: [PluginNotificationRule]
    @Binding var enablePush: Bool
    @Binding var enableEmail: Bool
    @Binding var throttleSeconds: Int

    @State private var newRuleName = ""
    @State private var newRuleCondition = ""
    @State private var newRuleChannel: NotificationChannel = .inApp

    var body: some View {
        Section {
            Toggle(isOn: $enablePush) {
                Label("Push Notifications", systemImage: "bell.badge.fill")
            }
            Toggle(isOn: $enableEmail) {
                Label("Email Notifications", systemImage: "envelope.badge.fill")
            }

            Stepper(value: $throttleSeconds, in: 0...3600, step: 15) {
                HStack {
                    Label("Throttle Interval", systemImage: "timer")
                    Spacer()
                    Text(throttleSeconds == 0 ? "None" : "\(throttleSeconds)s").bold().font(.caption)
                }
            }
        } header: {
            Label("Notification Channels", systemImage: "bell.and.waves.left.and.right")
        }

        Section {
            if rules.isEmpty {
                Text("No notification rules defined.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(rules) { rule in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: rule.channel.icon).foregroundStyle(.blue).font(.caption)
                            Text(rule.name).font(.subheadline.bold())
                            Spacer()
                            Text(rule.channel.rawValue)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                        Text(rule.condition).font(.caption2.monospaced()).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { rules.remove(atOffsets: $0) }
            }

            VStack(spacing: 8) {
                TextField("Rule Name", text: $newRuleName).font(.caption)
                TextField("Condition (e.g. event.type == 'error')", text: $newRuleCondition).font(.caption.monospaced())
                Picker("Channel", selection: $newRuleChannel) {
                    ForEach(NotificationChannel.allCases, id: \.self) { ch in
                        Text(ch.rawValue).tag(ch)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button("Add Rule", systemImage: "plus.circle.fill") {
                guard !newRuleName.isEmpty, !newRuleCondition.isEmpty else { return }
                rules.append(PluginNotificationRule(name: newRuleName, condition: newRuleCondition, channel: newRuleChannel))
                newRuleName = ""; newRuleCondition = ""
            }
            .disabled(newRuleName.isEmpty || newRuleCondition.isEmpty)
        } header: {
            Label("Notification Rules", systemImage: "bell.badge.waveform.fill")
        } footer: {
            Text("Rules determine when and how notifications are sent based on plugin events.")
        }
    }
}

// MARK: - Feature Flags Section

private struct BuildFeatureFlagsSection: View {
    @Binding var featureFlags: [PluginFeatureFlag]
    @Binding var enableRemoteConfig: Bool

    @State private var newFlagKey = ""
    @State private var newFlagDescription = ""

    var body: some View {
        Section {
            Toggle(isOn: $enableRemoteConfig) {
                Label("Remote Config", systemImage: "icloud.and.arrow.down")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Remote config allows toggling feature flags without redeploying the plugin.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        } header: {
            Label("Feature Flag Settings", systemImage: "flag.2.crossed.fill")
        }

        Section {
            if featureFlags.isEmpty {
                ContentUnavailableView("No Feature Flags", systemImage: "flag.slash", description: Text("Add feature flags to gradually roll out new functionality."))
                    .scaleEffect(0.8)
            } else {
                ForEach($featureFlags) { $flag in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Toggle(isOn: $flag.isEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flag.key).font(.caption.bold().monospaced())
                                    if !flag.flagDescription.isEmpty {
                                        Text(flag.flagDescription).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        HStack(spacing: 8) {
                            Text("Rollout: \(Int(flag.rolloutPercentage))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(flag.rolloutPercentage >= 100 ? .green : .orange)
                            if flag.expiresAt != nil {
                                Text("Has Expiry").font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { featureFlags.remove(atOffsets: $0) }
            }

            VStack(spacing: 8) {
                TextField("Flag key (e.g. enable_new_ui)", text: $newFlagKey)
                    .textInputAutocapitalization(.never).font(.caption.monospaced())
                TextField("Description (optional)", text: $newFlagDescription).font(.caption)
            }

            Button("Add Feature Flag", systemImage: "flag.fill") {
                guard !newFlagKey.isEmpty else { return }
                featureFlags.append(PluginFeatureFlag(key: newFlagKey, flagDescription: newFlagDescription))
                newFlagKey = ""; newFlagDescription = ""
            }
            .disabled(newFlagKey.isEmpty)
        } header: {
            Label("Flags", systemImage: "flag.badge.ellipsis")
        } footer: {
            Text("Feature flags can be toggled at runtime to enable or disable functionality.")
        }
    }
}

// MARK: - Accessibility Section

private struct BuildAccessibilitySection: View {
    @Binding var labelsEnabled: Bool
    @Binding var dynamicType: Bool
    @Binding var reduceMotion: Bool
    @Binding var voiceOver: Bool
    @Binding var highContrast: Bool
    @Binding var minTouchTarget: Int

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessibility ensures your plugin is usable by everyone, including those with disabilities.")
                    .font(.caption).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    AccessibilityScoreCircle(
                        score: accessibilityScore,
                        label: "Score"
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(accessibilityGrade).font(.title3.bold()).foregroundStyle(accessibilityColor)
                        Text("\(enabledFeaturesCount)/6 features enabled").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("Accessibility Overview", systemImage: "accessibility")
        }

        Section {
            Toggle(isOn: $labelsEnabled) {
                Label("Accessibility Labels", systemImage: "text.badge.checkmark")
            }
            Toggle(isOn: $dynamicType) {
                Label("Dynamic Type Support", systemImage: "textformat.size")
            }
            Toggle(isOn: $reduceMotion) {
                Label("Reduce Motion Support", systemImage: "figure.walk.motion")
            }
            Toggle(isOn: $voiceOver) {
                Label("VoiceOver Optimization", systemImage: "speaker.wave.3.fill")
            }
            Toggle(isOn: $highContrast) {
                Label("High Contrast Mode", systemImage: "circle.lefthalf.filled")
            }

            Stepper(value: $minTouchTarget, in: 24...64, step: 4) {
                HStack {
                    Label("Min Touch Target", systemImage: "hand.point.up.left.fill")
                    Spacer()
                    Text("\(minTouchTarget)pt").bold().font(.caption)
                        .foregroundStyle(minTouchTarget >= 44 ? .green : .orange)
                }
            }
        } header: {
            Label("Accessibility Features", systemImage: "accessibility.fill")
        } footer: {
            Text("Apple recommends a minimum touch target of 44pt for optimal accessibility.")
        }
    }

    private var enabledFeaturesCount: Int {
        [labelsEnabled, dynamicType, reduceMotion, voiceOver, highContrast, minTouchTarget >= 44].filter { $0 }.count
    }

    private var accessibilityScore: Double {
        Double(enabledFeaturesCount) / 6.0 * 100
    }

    private var accessibilityGrade: String {
        switch enabledFeaturesCount {
        case 6: return "Excellent"
        case 5: return "Very Good"
        case 4: return "Good"
        case 3: return "Fair"
        default: return "Needs Improvement"
        }
    }

    private var accessibilityColor: Color {
        switch enabledFeaturesCount {
        case 5...6: return .green
        case 3...4: return .orange
        default: return .red
        }
    }
}

private struct AccessibilityScoreCircle: View {
    let score: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                .frame(width: 52, height: 52)
            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(score >= 80 ? Color.green : (score >= 50 ? Color.orange : Color.red), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))
            Text("\(Int(score))")
                .font(.system(size: 14, weight: .black, design: .rounded))
        }
    }
}

// MARK: - Backup Section

private struct BuildBackupSection: View {
    @Binding var autoBackup: Bool
    @Binding var frequencyHours: Int
    @Binding var maxCount: Int
    @Binding var encryption: Bool
    let lastBackup: Date?

    var body: some View {
        Section {
            if let lastBackup {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Backup").font(.caption.bold())
                        Text(lastBackup.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("No backups found").font(.caption).foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $autoBackup) {
                Label("Auto-Backup", systemImage: "arrow.clockwise.icloud")
            }

            if autoBackup {
                Stepper(value: $frequencyHours, in: 1...168, step: 1) {
                    HStack {
                        Label("Frequency", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Text(frequencyHours == 1 ? "Every hour" : "Every \(frequencyHours)h").bold().font(.caption)
                    }
                }

                Stepper(value: $maxCount, in: 1...50) {
                    HStack {
                        Label("Max Backups", systemImage: "square.stack.3d.up")
                        Spacer()
                        Text("\(maxCount)").bold().font(.caption)
                    }
                }

                Toggle(isOn: $encryption) {
                    Label("Encrypt Backups", systemImage: "lock.shield.fill")
                }
            }
        } header: {
            Label("Backup & Restore", systemImage: "externaldrive.fill.badge.timemachine")
        } footer: {
            Text("Backups include plugin configuration, source code, and all settings. Encrypted backups use AES-256.")
        }

        Section {
            Button {
                // Simulated manual backup trigger
            } label: {
                Label("Create Backup Now", systemImage: "arrow.down.doc.fill").frame(maxWidth: .infinity).bold()
            }
            .buttonStyle(.bordered)

            Button {
                // Simulated restore
            } label: {
                Label("Restore from Backup", systemImage: "arrow.uturn.backward.circle.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                // Simulated cleanup
            } label: {
                Label("Delete All Backups", systemImage: "trash.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } header: {
            Label("Backup Actions", systemImage: "gearshape.2.fill")
        }
    }
}

// MARK: - Logging Section

private struct BuildLoggingSection: View {
    @Binding var logLevel: PluginLogLevel
    @Binding var remoteLogging: Bool
    @Binding var retentionDays: Int
    @Binding var dataMasking: Bool
    @Binding var structured: Bool

    var body: some View {
        Section {
            Picker("Log Level", selection: $logLevel) {
                ForEach(PluginLogLevel.allCases, id: \.self) { level in
                    HStack {
                        Circle().fill(level.color).frame(width: 8, height: 8)
                        Text(level.rawValue.capitalized)
                    }.tag(level)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 6) {
                ForEach(PluginLogLevel.allCases, id: \.self) { level in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(logLevel.severity >= level.severity ? level.color : Color.secondary.opacity(0.2))
                            .frame(width: 12, height: 12)
                        Text(level.rawValue.prefix(3).uppercased())
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(logLevel.severity >= level.severity ? level.color : .secondary)
                    }
                    if level != PluginLogLevel.allCases.last {
                        Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1).frame(maxWidth: 20)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Label("Log Level", systemImage: "doc.text.fill")
        } footer: {
            Text("Messages below the selected level will be suppressed.")
        }

        Section {
            Toggle(isOn: $remoteLogging) {
                Label("Remote Logging", systemImage: "icloud.fill")
            }
            Toggle(isOn: $dataMasking) {
                Label("Sensitive Data Masking", systemImage: "eye.slash.fill")
            }
            Toggle(isOn: $structured) {
                Label("Structured Logging (JSON)", systemImage: "curlybraces")
            }

            Stepper(value: $retentionDays, in: 1...365) {
                HStack {
                    Label("Log Retention", systemImage: "calendar")
                    Spacer()
                    Text("\(retentionDays) days").bold().font(.caption)
                }
            }
        } header: {
            Label("Logging Options", systemImage: "text.alignleft")
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Log Output Preview").font(.caption.bold()).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    if structured {
                        Text("{\"level\":\"\(logLevel.rawValue)\",\"msg\":\"Plugin started\",\"ts\":\"\(Date().ISO8601Format())\"}")
                            .font(.system(size: 9, design: .monospaced)).foregroundStyle(.green)
                    } else {
                        Text("[\(logLevel.rawValue.uppercased())] \(Date().formatted()) - Plugin started")
                            .font(.system(size: 9, design: .monospaced)).foregroundStyle(.green)
                    }
                }
                .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
            }
        } header: {
            Label("Preview", systemImage: "eye")
        }
    }
}

// MARK: - Build Pipeline Section

private struct BuildPipelineSection: View {
    @Binding var stages: [PluginBuildStage]
    @Binding var ciEnabled: Bool
    @Binding var autoTests: Bool
    @Binding var linting: Bool
    @Binding var minification: Bool

    var body: some View {
        Section {
            Toggle(isOn: $ciEnabled) {
                Label("Continuous Integration", systemImage: "arrow.triangle.2.circlepath.circle.fill")
            }
            Toggle(isOn: $autoTests) {
                Label("Auto-Run Tests on Build", systemImage: "testtube.2")
            }
            Toggle(isOn: $linting) {
                Label("Code Linting", systemImage: "checkmark.diamond.fill")
            }
            Toggle(isOn: $minification) {
                Label("Code Minification", systemImage: "rectangle.compress.vertical")
            }
        } header: {
            Label("Build Configuration", systemImage: "hammer.fill")
        }

        Section {
            if stages.isEmpty {
                ContentUnavailableView("No Pipeline Stages", systemImage: "arrow.right.arrow.left", description: Text("Add build pipeline stages to automate your build process."))
                    .scaleEffect(0.8)
            } else {
                ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .frame(width: 24, height: 24)
                            .background(stage.status.color.opacity(0.12), in: Circle())
                            .foregroundStyle(stage.status.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.name).font(.subheadline.bold())
                            Text(stage.command).font(.caption2.monospaced()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: stage.status.icon)
                            .foregroundStyle(stage.status.color)
                            .font(.caption)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { stages.remove(atOffsets: $0) }
                .onMove { stages.move(fromOffsets: $0, toOffset: $1) }
            }

            Button("Add Stage", systemImage: "plus.circle.fill") {
                stages.append(PluginBuildStage(name: "Stage \(stages.count + 1)", command: "echo 'Running stage...'"))
            }
        } header: {
            Label("Pipeline Stages", systemImage: "arrow.right.square.fill")
        } footer: {
            Text("Stages execute sequentially. Drag to reorder. A failing stage halts the pipeline.")
        }

        Section {
            Button {
                for i in stages.indices {
                    stages[i].status = .success
                }
            } label: {
                Label("Simulate Pipeline Run", systemImage: "play.fill").frame(maxWidth: .infinity).bold()
            }
            .buttonStyle(.bordered)
        } header: {
            Label("Pipeline Actions", systemImage: "bolt.fill")
        }
    }
}

// MARK: - New Supporting Types

struct PluginWebhookConfig: Identifiable {
    let id = UUID()
    var url: String
    var secret: String?
    var events: [String]
    var isActive: Bool
    var hasSecret: Bool { secret != nil }
}

struct PluginLocaleEntry: Identifiable {
    let id = UUID()
    var code: String
    var displayLabel: String
    var translatedKeys: Int = 0
}

enum PluginSharePermission: String, CaseIterable {
    case readOnly = "Read Only"
    case readWrite = "Read & Write"
    case admin = "Admin"
}

struct PluginScheduledTask: Identifiable {
    let id = UUID()
    var name: String
    var cronExpression: String
    var action: String
    var isEnabled: Bool = true
    var lastRunAt: Date?
}

struct PluginNotificationRule: Identifiable {
    let id = UUID()
    var name: String
    var condition: String
    var channel: NotificationChannel
}

enum NotificationChannel: String, CaseIterable {
    case inApp = "In-App"
    case push = "Push"
    case email = "Email"
    case webhook = "Webhook"

    var icon: String {
        switch self {
        case .inApp: return "bell.fill"
        case .push: return "iphone.radiowaves.left.and.right"
        case .email: return "envelope.fill"
        case .webhook: return "arrow.up.right.square"
        }
    }
}

struct PluginFeatureFlag: Identifiable {
    let id = UUID()
    var key: String
    var flagDescription: String
    var isEnabled: Bool = false
    var rolloutPercentage: Double = 100
    var expiresAt: Date?
}

enum PluginLogLevel: String, CaseIterable {
    case verbose, debug, info, warning, error, critical

    var severity: Int {
        switch self {
        case .verbose: return 0
        case .debug: return 1
        case .info: return 2
        case .warning: return 3
        case .error: return 4
        case .critical: return 5
        }
    }

    var color: Color {
        switch self {
        case .verbose: return .secondary
        case .debug: return .blue
        case .info: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

struct PluginBuildStage: Identifiable {
    let id = UUID()
    var name: String
    var command: String
    var status: BuildStageStatus = .pending
    var duration: TimeInterval?
}

enum BuildStageStatus: String, CaseIterable {
    case pending, running, success, failed, skipped

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .running: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "minus.circle"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .secondary
        case .running: return .blue
        case .success: return .green
        case .failed: return .red
        case .skipped: return .orange
        }
    }
}

// MARK: - Strict Plugin Key Generator

enum PluginKeyPattern {
    /// Generates a strict-pattern key: `tk-{region}-{timestamp_hex}-{entropy_block}-{checksum}`
    /// Pattern: `tk-{2 char region}-{8 hex timestamp}-{16 hex entropy}-{4 hex crc}`
    static func generate(region: String = "us") -> String {
        let regionCode = String(region.lowercased().prefix(2)).padding(toLength: 2, withPad: "x", startingAt: 0)
        let timestamp = String(format: "%08x", UInt32(Date().timeIntervalSince1970))
        let entropy = (0..<16).map { _ in String(format: "%x", Int.random(in: 0...15)) }.joined()
        let raw = "\(regionCode)\(timestamp)\(entropy)"
        let checksum = String(format: "%04x", raw.utf8.reduce(0) { ($0 &+ UInt32($1)) & 0xFFFF })
        return "tk-\(regionCode)-\(timestamp)-\(entropy)-\(checksum)"
    }

    static func validate(_ key: String) -> Bool {
        let pattern = #"^tk-[a-z]{2}-[0-9a-f]{8}-[0-9a-f]{16}-[0-9a-f]{4}$"#
        return key.range(of: pattern, options: .regularExpression) != nil
    }

    static func decode(_ key: String) -> (region: String, timestamp: Date, entropy: String, checksum: String)? {
        guard validate(key) else { return nil }
        let parts = key.split(separator: "-")
        guard parts.count == 5 else { return nil }
        let region = String(parts[1])
        let ts = UInt32(parts[2], radix: 16) ?? 0
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        return (region, date, String(parts[3]), String(parts[4]))
    }
}

// MARK: - Supporting Types

enum SandboxExecutionMode: String, CaseIterable, Identifiable {
    case strict = "Strict"
    case standard = "Standard"
    case permissive = "Permissive"
    var id: String { rawValue }
    var description: String {
        switch self {
        case .strict: return "No network, no filesystem, isolated memory"
        case .standard: return "Allowlisted network, read-only filesystem"
        case .permissive: return "Full network, scoped filesystem access"
        }
    }
}



enum PluginMarketCategory: String, CaseIterable, Identifiable {
    case utility = "Utility"
    case productivity = "Productivity"
    case integration = "Integration"
    case analytics = "Analytics"
    case security = "Security"
    case ai = "AI / ML"
    case developer = "Developer Tools"
    case communication = "Communication"
    var id: String { rawValue }
}

struct PluginTestSuite: Identifiable {
    let id = UUID()
    var name: String
    var testCases: [PluginTestCase]
    var lastRun: Date?
    var passRate: Double?
}

struct PluginTestCase: Identifiable {
    let id = UUID()
    var name: String
    var input: String
    var expectedOutput: String
    var status: TestCaseStatus = .pending

    enum TestCaseStatus: String {
        case pending = "Pending"
        case passed = "Passed"
        case failed = "Failed"
        case skipped = "Skipped"

        var color: Color {
            switch self {
            case .pending: return .secondary
            case .passed: return .green
            case .failed: return .red
            case .skipped: return .orange
            }
        }
    }
}
