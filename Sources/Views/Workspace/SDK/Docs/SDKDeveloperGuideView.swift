

import SwiftUI

struct SDKDeveloperGuideView: View {
    @State private var selectedCategory: GuideCategory = .introduction

    enum GuideCategory: String, CaseIterable, Identifiable {
        case introduction = "Introduction"
        case core = "Core SDK"
        case modules = "Module System"
        case plugins = "Plugins"
        case connectors = "Connectors"
        case dependencies = "Dependencies"
        case security = "Security"
        case packaging = "Packaging"
        case deployment = "Deployment"
        case bestPractices = "Best Practices"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .introduction: return "hand.wave"
            case .core: return "cpu"
            case .modules: return "square.grid.3x3.fill"
            case .plugins: return "puzzlepiece"
            case .connectors: return "link"
            case .dependencies: return "point.3.connected.trianglepath.dotted"
            case .security: return "shield.checkered"
            case .packaging: return "shippingbox"
            case .deployment: return "cloud.arrow.up"
            case .bestPractices: return "star"
            }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GuideCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                SDKSectionHeader("Developer Documentation", subtitle: "Architecture and Integration Guide", alignment: .leading)
            }

            switch selectedCategory {
            case .introduction: IntroductionSection()
            case .core: CoreSDKSection()
            case .modules: ModuleSystemSection()
            case .plugins: PluginsSection()
            case .connectors: ConnectorsSection()
            case .dependencies: DependenciesSection()
            case .security: SecuritySection()
            case .packaging: PackagingSection()
            case .deployment: DeploymentSection()
            case .bestPractices: BestPracticesSection()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dev Guide")
    }
}

// MARK: - Private Sections

private struct IntroductionSection: View {
    var body: some View {
        Section("Introduction") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workspace SDK Platform").font(.headline)
                Text("ToolsKit provides a comprehensive, production-grade SDK for building and extending the Workspace OS. The platform is built on a modular kernel that manages data, security, and execution environments.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }.padding(.vertical, 4)
        }
        Section("Key Concepts") {
            DocRow(title: "Kernel", description: "The central orchestration layer for all SDK services.", icon: "gearshape.2")
            DocRow(title: "Data Store", description: "Atomic, concurrent-safe storage for persistent application state.", icon: "database")
            DocRow(title: "Event Bus", description: "Asynchronous pub/sub system for inter-module communication.", icon: "antenna.radiowaves.left.and.right")
        }
    }
}

private struct CoreSDKSection: View {
    var body: some View {
        Section("Core Modules") {
            DocRow(title: "SDKRouter", description: "Standardized internal API routing and endpoint management.", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            DocRow(title: "ServiceRegistry", description: "Protocol-driven dependency injection container.", icon: "tray.full")
            DocRow(title: "WorkspaceState", description: "Reactive management of runtime environment diagnostics.", icon: "activitylog")
        }
        Section("Implementation Example") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Registering a Service").font(.caption.bold())
                Text("let service = MyService()\nServiceRegistry.shared.register(service, for: .mail)")
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

private struct PluginsSection: View {
    var body: some View {
        Section("Plugin Architecture") {
            Text("Plugins are event-driven modules executing in an isolated JavaScriptCore sandbox. They interact with the workspace via a scoped context SDK.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Lifecycle Hooks") {
            DocRow(title: "onEvent", description: "Primary entry point for reacting to workspace triggers.", icon: "bolt")
            DocRow(title: "onLoad", description: "Initialization hook for setting up internal plugin state.", icon: "power")
        }
        Section("Runtime Context") {
            Text("ctx.notes, ctx.mail, ctx.ai, ctx.integrations").font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
    }
}

private struct SecuritySection: View {
    var body: some View {
        Section("Security Model") {
            Text("Hierarchical permission scopes ensure that modules only access necessary data. High-risk scopes require explicit user justification.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Access Scopes") {
            DocRow(title: "mail.read", description: "Allows reading subject and metadata of emails.", icon: "envelope")
            DocRow(title: "workspace.write", description: "Allows modifying notes and project structure.", icon: "pencil")
        }
    }
}

private struct ModuleSystemSection: View {
    var body: some View {
        Section("Module Architecture") {
            Text("SDK modules are self-contained units that expose capabilities and features to the runtime. Modules register dynamically through SDKModuleRegistry and declare their dependencies, capabilities, and exported services.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Registration") {
            DocRow(title: "SDKModuleDescriptor", description: "Defines a module's identifier, version, capabilities, dependencies, and load priority.", icon: "rectangle.badge.plus")
            DocRow(title: "SDKModuleRegistry", description: "Central registry for dynamic module registration, activation, and discovery.", icon: "square.grid.3x3.fill")
            VStack(alignment: .leading, spacing: 8) {
                Text("Registering a Module").font(.caption.bold())
                Text("""
                let descriptor = SDKModuleDescriptor(
                    identifier: "com.app.analytics",
                    displayName: "Analytics",
                    capabilities: [.analytics, .eventPublishing]
                )
                try SDKModuleRegistry.shared.register(descriptor)
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section("Composition") {
            DocRow(title: "Feature Exposure", description: "Modules expose features via SDKFeatureExposureManager with typed parameter schemas.", icon: "rectangle.and.text.magnifyingglass")
            DocRow(title: "Dependency Resolution", description: "SDKDependencyGraph performs topological sort with cycle detection.", icon: "point.3.connected.trianglepath.dotted")
            DocRow(title: "Capability Discovery", description: "Query available modules by capability type for dynamic composition.", icon: "magnifyingglass")
        }
    }
}

private struct ConnectorsSection: View {
    var body: some View {
        Section("Connector System") {
            Text("Connectors bridge external services with the SDK runtime. Each connector implements BaseConnector protocol providing authentication, synchronization, and health monitoring.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Built-in Connectors") {
            DocRow(title: "Gmail", description: "OAuth2 email integration with message sync.", icon: "envelope")
            DocRow(title: "GitHub", description: "Personal Access Token auth with repository sync.", icon: "chevron.left.forwardslash.chevron.right")
            DocRow(title: "Webhook", description: "Generic HTTP endpoint for event-driven integrations.", icon: "arrow.up.forward.app")
            DocRow(title: "Calendar", description: "Calendar event synchronization.", icon: "calendar")
            DocRow(title: "Local File System", description: "File-based data import/export.", icon: "folder")
        }
        Section("Runtime Binding") {
            DocRow(title: "ConnectorBinding", description: "Links connectors to SDK modules as data sources, sinks, or event triggers.", icon: "link")
            DocRow(title: "Live Streaming", description: "Real-time data feeds using timer-based polling with event bus integration.", icon: "bolt.horizontal")
            DocRow(title: "Templates", description: "Pre-configured connector blueprints for REST, GraphQL, WebSocket, Firebase, Slack, MQTT.", icon: "doc.on.doc")
        }
        Section("Authentication") {
            DocRow(title: "ConnectorAuthMethod", description: "Supports none, apiKey, oauth2, bearer, basic, certificate, and webhook auth.", icon: "lock")
        }
    }
}

private struct DependenciesSection: View {
    var body: some View {
        Section("Dependency Management") {
            Text("The SDK dependency system manages libraries, modules, and their interconnections. Dependencies are represented as directed graphs with conflict detection and resolution.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Library System") {
            DocRow(title: "SDKLibraryDefinition", description: "Defines reusable libraries with version, scopes, exported functions, and pipeline stages.", icon: "books.vertical")
            DocRow(title: "SDKLibraryVersionResolver", description: "Resolves preferred versions using semantic version comparison.", icon: "arrow.triangle.2.circlepath")
            DocRow(title: "SDKLibraryDependencyBridge", description: "Converts library definitions into dependency graph nodes.", icon: "arrow.triangle.branch")
        }
        Section("Dependency Graph") {
            DocRow(title: "SDKDependencyNode", description: "Graph node with kind (library/connector/plugin/sdkApp), version, links, hooks, and conditions.", icon: "point.3.connected.trianglepath.dotted")
            DocRow(title: "Conflict Resolution", description: "Detects version mismatches, circular dependencies, and capability collisions.", icon: "exclamationmark.triangle")
            VStack(alignment: .leading, spacing: 8) {
                Text("Dependency Node Types").font(.caption.bold())
                Text("library | connector | plugin | sdkApp")
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

private struct PackagingSection: View {
    var body: some View {
        Section("SDK Export") {
            Text("SDK projects can be packaged as versioned .zip bundles containing modules, plugins, connectors, tools, automation rules, and runtime definitions.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Export Pipeline") {
            DocRow(title: "SDKExportService", description: "Creates temp directory structure, encodes config.json, organizes all project assets.", icon: "square.and.arrow.up")
            DocRow(title: "SDKDownloadView", description: "Version selection, bundle download, and export configuration interface.", icon: "arrow.down.circle")
        }
        Section("Import Pipeline") {
            DocRow(title: "CustomAppSDKView", description: "Import .zip bundles, validate structure and compatibility, register into runtime.", icon: "arrow.down.doc")
            DocRow(title: "Validation", description: "SDK version match, module integrity, plugin compatibility, connector support checks.", icon: "checkmark.shield")
        }
        Section("Bundle Structure") {
            VStack(alignment: .leading, spacing: 8) {
                Text("SDK Bundle Layout").font(.caption.bold())
                Text("""
                ToolsKit-SDK-v2.1.0/
                ├── config.json
                ├── Plugins/
                ├── Tools/
                ├── Connectors/
                └── Automations/
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

private struct DeploymentSection: View {
    var body: some View {
        Section("Release Pipeline") {
            DocRow(title: "Versioning", description: "Semantic versioning (SemVer) required for all SDK modules.", icon: "number")
            DocRow(title: "Validation", description: "Automated verification of capability and action schemas.", icon: "checkmark.shield")
        }
        Section("Build Configuration") {
            DocRow(title: "Build Modes", description: "Debug, Release, and Profile modes with platform targeting (iOS, macOS, watchOS, tvOS).", icon: "hammer")
            DocRow(title: "Integration Tests", description: "Automated testing of module integrations and connector health.", icon: "testtube.2")
            DocRow(title: "SDKDeploymentView", description: "Project export, provisioning, and distribution management.", icon: "cloud.arrow.up")
        }
    }
}

private struct BestPracticesSection: View {
    var body: some View {
        Section("Architecture") {
            DocRow(title: "Mobile-First", description: "All interactions must be gesture-driven, contextual, and use NavigationStack/sheets/overlays.", icon: "iphone")
            DocRow(title: "Reactive State", description: "Use @Published properties and Combine for all state management.", icon: "arrow.triangle.2.circlepath")
            DocRow(title: "Offline-First", description: "Design all data operations to work without network connectivity.", icon: "wifi.slash")
        }
        Section("Module Design") {
            DocRow(title: "Single Responsibility", description: "Each module should own one well-defined capability domain.", icon: "1.circle")
            DocRow(title: "Explicit Dependencies", description: "Always declare module dependencies in the descriptor.", icon: "list.bullet")
            DocRow(title: "Feature Exposure", description: "Expose features with typed parameter schemas for runtime discovery.", icon: "rectangle.and.text.magnifyingglass")
        }
        Section("Plugin Development") {
            DocRow(title: "Lifecycle Awareness", description: "Handle all lifecycle phases (loading, active, paused, updating, migrating).", icon: "arrow.triangle.2.circlepath")
            DocRow(title: "Sandboxed Execution", description: "Plugins run in isolated contexts with scoped permissions.", icon: "shield.lefthalf.filled")
            DocRow(title: "Manifest-Driven", description: "Declare all capabilities, permissions, and hooks in the plugin manifest.", icon: "doc.text")
        }
        Section("Connector Integration") {
            DocRow(title: "Auth Abstraction", description: "Use ConnectorAuthMethod enum for consistent authentication patterns.", icon: "lock")
            DocRow(title: "Error Handling", description: "Implement robust retry logic and health monitoring.", icon: "exclamationmark.triangle")
            DocRow(title: "Runtime Binding", description: "Bind connectors to modules for declarative data flow.", icon: "link")
        }
    }
}

private struct DocRow: View {
    let title: String; let description: String; let icon: String
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption2).foregroundStyle(.secondary)
            }
        } icon: { Image(systemName: icon).foregroundStyle(Color.accentColor) }
    }
}
