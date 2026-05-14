import SwiftUI

struct SDKSupportView: View {
    @State private var appDescription = ""
    @State private var generatedPlan: GenerationPlan?
    @State private var isGenerating = false
    @State private var generationPhase: GenerationPhase = .idle
    @State private var errorMessage: String?
    @State private var showingPlanDetail = false
    @State private var selectedTemplate: AppTemplate?
    @State private var includePlugins = true
    @State private var includeConnectors = true
    @State private var includeAutomation = true

    enum GenerationPhase: String {
        case idle, analyzing, scaffolding, modules, connectors, plugins, finalizing, complete
        var displayName: String {
            switch self {
            case .idle: return "Ready"
            case .analyzing: return "Analyzing requirements..."
            case .scaffolding: return "Scaffolding project..."
            case .modules: return "Generating SDK modules..."
            case .connectors: return "Configuring connectors..."
            case .plugins: return "Setting up plugins..."
            case .finalizing: return "Finalizing..."
            case .complete: return "Complete"
            }
        }
    }

    struct GenerationPlan: Identifiable {
        let id = UUID()
        var appName: String
        var description: String
        var modules: [PlannedModule]
        var connectors: [PlannedConnector]
        var plugins: [PlannedPlugin]
        var automationRules: [String]
        var estimatedComplexity: String
        var generatedAt: Date
    }

    struct PlannedModule: Identifiable {
        let id = UUID()
        var name: String
        var capabilities: [String]
        var description: String
    }

    struct PlannedConnector: Identifiable {
        let id = UUID()
        var name: String
        var type: String
        var purpose: String
    }

    struct PlannedPlugin: Identifiable {
        let id = UUID()
        var name: String
        var category: String
        var hooks: [String]
    }

    enum AppTemplate: String, CaseIterable, Identifiable {
        case taskManager = "Task Manager"
        case chatApp = "Chat Application"
        case dashboard = "Analytics Dashboard"
        case noteApp = "Note-Taking App"
        case ecommerce = "E-Commerce Store"
        case iotMonitor = "IoT Monitor"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .taskManager: return "Project & task management with collaboration"
            case .chatApp: return "Real-time messaging with channels and DMs"
            case .dashboard: return "Data visualization with live connectors"
            case .noteApp: return "Rich text notes with versioning and sync"
            case .ecommerce: return "Product catalog, cart, and checkout flow"
            case .iotMonitor: return "Device monitoring with MQTT/WebSocket feeds"
            }
        }

        var icon: String {
            switch self {
            case .taskManager: return "checklist"
            case .chatApp: return "bubble.left.and.bubble.right"
            case .dashboard: return "chart.bar.xaxis"
            case .noteApp: return "note.text"
            case .ecommerce: return "cart"
            case .iotMonitor: return "sensor.tag.radiowaves.forward"
            }
        }

        var prompt: String {
            switch self {
            case .taskManager: return "Build a task management app with projects, tasks, due dates, priorities, assignees, and real-time collaboration."
            case .chatApp: return "Build a chat application with channels, direct messages, typing indicators, and push notifications."
            case .dashboard: return "Build an analytics dashboard with live data feeds, charts, KPI widgets, and configurable data sources."
            case .noteApp: return "Build a note-taking app with rich text editing, version history, tags, search, and cloud sync."
            case .ecommerce: return "Build an e-commerce app with product browsing, cart management, checkout, and order tracking."
            case .iotMonitor: return "Build an IoT monitoring dashboard with device status, live sensor data, alerts, and MQTT integration."
            }
        }
    }

    var body: some View {
        List {
            inputSection
            templateSection
            optionsSection
            if isGenerating { progressSection }
            if let plan = generatedPlan { planSection(plan) }

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("AI App Builder")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "wand.and.stars.inverse")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .sheet(isPresented: $showingPlanDetail) {
            if let plan = generatedPlan {
                NavigationStack { planDetailSheet(plan) }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var inputSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles").font(.title2).foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text("AI App Generation").font(.headline)
                        Text("Describe your app in natural language").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)

            TextField("Describe the app you want to build...", text: $appDescription, axis: .vertical)
                .lineLimit(3...8)

            Button(action: startGeneration) {
                HStack {
                    Label(isGenerating ? generationPhase.displayName : "Generate App", systemImage: isGenerating ? "gearshape.2" : "sparkles")
                    Spacer()
                    if isGenerating { ProgressView().controlSize(.small) }
                }
            }
            .disabled(appDescription.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)
        } header: {
            Text("Natural Language Input")
        }
    }

    private var templateSection: some View {
        Section {
            ForEach(AppTemplate.allCases) { template in
                Button {
                    selectedTemplate = template
                    appDescription = template.prompt
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.rawValue).font(.subheadline.bold())
                                Text(template.description).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: template.icon)
                                .foregroundStyle(Color.accentColor)
                        }
                        Spacer()
                        if selectedTemplate == template {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Templates")
        }
    }

    private var optionsSection: some View {
        Section {
            Toggle("Include Plugins", isOn: $includePlugins)
            Toggle("Include Connectors", isOn: $includeConnectors)
            Toggle("Include Automation Rules", isOn: $includeAutomation)
        } header: {
            Text("Generation Options")
        }
    }

    private var progressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(GenerationPhase.allCases.enumerated()), id: \.offset) { index, phase in
                    if phase != .idle {
                        HStack(spacing: 8) {
                            if phaseIndex(generationPhase) > index {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                            } else if phaseIndex(generationPhase) == index {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "circle").foregroundStyle(.tertiary).font(.caption)
                            }
                            Text(phase.displayName).font(.caption)
                                .foregroundStyle(phaseIndex(generationPhase) >= index ? .primary : .tertiary)
                        }
                    }
                }
            }
        } header: {
            Text("Generation Progress")
        }
    }

    @ViewBuilder
    private func planSection(_ plan: GenerationPlan) -> some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.appName).font(.headline)
                    Text(plan.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                Button("Details") { showingPlanDetail = true }
                    .buttonStyle(.bordered).controlSize(.small)
            }

            HStack(spacing: 16) {
                Label("\(plan.modules.count) modules", systemImage: "cpu").font(.caption)
                Label("\(plan.connectors.count) connectors", systemImage: "link").font(.caption)
                Label("\(plan.plugins.count) plugins", systemImage: "puzzlepiece").font(.caption)
            }
            .foregroundStyle(.secondary)

            LabeledContent("Complexity", value: plan.estimatedComplexity)

            Button(action: applyPlan) {
                Label("Apply to Current Project", systemImage: "arrow.right.circle.fill")
            }
            .disabled(projectManager.currentProject == nil)
        } header: {
            Text("Generated Plan")
        }
    }

    @ViewBuilder
    private func planDetailSheet(_ plan: GenerationPlan) -> some View {
        List {
            Section("Overview") {
                LabeledContent("App Name", value: plan.appName)
                Text(plan.description).font(.subheadline).foregroundStyle(.secondary)
                LabeledContent("Complexity", value: plan.estimatedComplexity)
                LabeledContent("Generated", value: plan.generatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            Section("Modules (\(plan.modules.count))") {
                ForEach(plan.modules) { mod in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mod.name).font(.subheadline.bold())
                        Text(mod.description).font(.caption).foregroundStyle(.secondary)
                        Text(mod.capabilities.joined(separator: ", "))
                            .font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
            Section("Connectors (\(plan.connectors.count))") {
                ForEach(plan.connectors) { conn in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(conn.name).font(.subheadline.bold())
                            Text(conn.purpose).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(conn.type).font(.caption.monospaced()).foregroundStyle(Color.accentColor)
                    }
                }
            }
            Section("Plugins (\(plan.plugins.count))") {
                ForEach(plan.plugins) { plugin in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.name).font(.subheadline.bold())
                        Text("Category: \(plugin.category)").font(.caption).foregroundStyle(.secondary)
                        Text("Hooks: \(plugin.hooks.joined(separator: ", "))").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            if !plan.automationRules.isEmpty {
                Section("Automation Rules") {
                    ForEach(plan.automationRules, id: \.self) { rule in
                        Text(rule).font(.caption)
                    }
                }
            }
        }
        .aiAnimationLoading(isGenerating)
        .navigationTitle("Generation Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { showingPlanDetail = false }
            }
        }
    }

    @StateObject private var projectManager = SDKProjectManager.shared

    private func phaseIndex(_ phase: GenerationPhase) -> Int {
        GenerationPhase.allCases.firstIndex(of: phase) ?? 0
    }

    private func startGeneration() {
        isGenerating = true
        errorMessage = nil
        generatedPlan = nil

        Task {
            do {
                let phases: [GenerationPhase] = [.analyzing, .scaffolding, .modules, .connectors, .plugins, .finalizing, .complete]
                for phase in phases {
                    await MainActor.run { generationPhase = phase }
                    try await Task.sleep(nanoseconds: 400_000_000)
                }

                let contextDocument = try await Task.detached(priority: .userInitiated) {
                    SDKAIContextProvider.loadContext()
                }.value
                let systemPrompt = SDKAIContextProvider.supportSystemPrompt(context: contextDocument)

                let response = try await AIService.shared.processText(
                    prompt: """
                    You are generating a production-ready SDK app plan that will be implemented in JavaScript with the SDK.
                    Fully analyze and follow the system training prompt context. Return strict JSON only.
                    User requirements: \(appDescription)
                    """,
                    systemPrompt: systemPrompt
                )

                let plan = parseGenerationResponse(response)
                await MainActor.run {
                    generatedPlan = plan
                    isGenerating = false
                    generationPhase = .idle
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                    generationPhase = .idle
                    generatedPlan = fallbackPlan()
                }
            }
        }
    }

    private func parseGenerationResponse(_ response: String) -> GenerationPlan {
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return fallbackPlan()
        }

        let appName = json["appName"] as? String ?? "Generated App"
        let desc = json["description"] as? String ?? appDescription
        let complexity = json["complexity"] as? String ?? "Medium"

        var modules: [PlannedModule] = []
        if let mods = json["modules"] as? [[String: Any]] {
            modules = mods.map {
                PlannedModule(
                    name: $0["name"] as? String ?? "Module",
                    capabilities: $0["capabilities"] as? [String] ?? [],
                    description: $0["description"] as? String ?? ""
                )
            }
        }

        var connectors: [PlannedConnector] = []
        if includeConnectors, let conns = json["connectors"] as? [[String: Any]] {
            connectors = conns.map {
                PlannedConnector(
                    name: $0["name"] as? String ?? "Connector",
                    type: $0["type"] as? String ?? "webhook",
                    purpose: $0["purpose"] as? String ?? ""
                )
            }
        }

        var plugins: [PlannedPlugin] = []
        if includePlugins, let plugs = json["plugins"] as? [[String: Any]] {
            plugins = plugs.map {
                PlannedPlugin(
                    name: $0["name"] as? String ?? "Plugin",
                    category: $0["category"] as? String ?? "utility",
                    hooks: $0["hooks"] as? [String] ?? []
                )
            }
        }

        let rules = includeAutomation ? (json["automationRules"] as? [String] ?? []) : []

        return GenerationPlan(
            appName: appName,
            description: desc,
            modules: modules,
            connectors: connectors,
            plugins: plugins,
            automationRules: rules,
            estimatedComplexity: complexity,
            generatedAt: Date()
        )
    }

    private func fallbackPlan() -> GenerationPlan {
        GenerationPlan(
            appName: "Generated App",
            description: appDescription,
            modules: [
                PlannedModule(name: "CoreData", capabilities: ["dataAccess", "storage"], description: "Primary data management module"),
                PlannedModule(name: "UI", capabilities: ["rendering"], description: "View composition module"),
            ],
            connectors: includeConnectors ? [
                PlannedConnector(name: "API", type: "REST", purpose: "Backend communication")
            ] : [],
            plugins: includePlugins ? [
                PlannedPlugin(name: "Analytics", category: "analytics", hooks: ["onEvent", "onLoad"])
            ] : [],
            automationRules: includeAutomation ? ["Sync data on app launch"] : [],
            estimatedComplexity: "Medium",
            generatedAt: Date()
        )
    }

    private func applyPlan() {
        guard let plan = generatedPlan, var project = projectManager.currentProject else { return }
        project.name = plan.appName
        project.description = plan.description
        project.updatedAt = Date()
        projectManager.updateProject(project)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.plan.applied",
            data: ["name": plan.appName, "modules": "\(plan.modules.count)"]
        ))
    }
}

extension SDKSupportView.GenerationPhase: CaseIterable {
    static var allCases: [SDKSupportView.GenerationPhase] {
        [.idle, .analyzing, .scaffolding, .modules, .connectors, .plugins, .finalizing, .complete]
    }
}
