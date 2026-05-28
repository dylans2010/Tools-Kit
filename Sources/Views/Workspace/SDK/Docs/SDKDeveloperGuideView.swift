import SwiftUI

struct SDKDeveloperGuideView: View {
    @State private var selectedCategory: GuideCategory = .tableOfContents
    @State private var searchText = ""

    enum GuideCategory: String, CaseIterable, Identifiable {
        case tableOfContents = "Table of Contents"
        case introduction = "Introduction"
        case kernelLifecycle = "Kernel & Lifecycle"
        case moduleSystem = "Module System"
        case pluginArchitecture = "Plugin Architecture"
        case connectorSystem = "Connector System"
        case dependencyManagement = "Dependencies"
        case runtimeExecution = "Runtime & Execution"
        case dataLayer = "Data Layer"
        case eventSystem = "Event System"
        case security = "Security & Permissions"
        case diContainer = "DI Container"
        case routerAPI = "Router & API"
        case automationEngine = "Automation"
        case swiftUIIntegration = "SwiftUI Integration"
        case packaging = "Packaging & Export"
        case deployment = "Deployment"
        case constraints = "Constraints & Rules"
        case bestPractices = "Best Practices"
        case definitionsReference = "Definitions Reference"
        case featureModules = "Feature Modules"
        case caching = "Caching & Performance"
        case migration = "Migration & Versioning"
        case localization = "Localization"
        case featureFlags = "Feature Flags"
        case realtimeSync = "Realtime Sync"
        case aiIntegration = "AI & Slides"
        case toolSystem = "Tool System"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .tableOfContents: return "list.bullet.rectangle"
            case .introduction: return "hand.wave"
            case .kernelLifecycle: return "power"
            case .moduleSystem: return "square.grid.3x3.fill"
            case .pluginArchitecture: return "puzzlepiece"
            case .connectorSystem: return "link"
            case .dependencyManagement: return "point.3.connected.trianglepath.dotted"
            case .runtimeExecution: return "play.rectangle"
            case .dataLayer: return "database"
            case .eventSystem: return "antenna.radiowaves.left.and.right"
            case .security: return "shield.checkered"
            case .diContainer: return "tray.full"
            case .routerAPI: return "arrow.up.right.and.arrow.down.left.rectangle"
            case .automationEngine: return "gearshape.2"
            case .swiftUIIntegration: return "swift"
            case .packaging: return "shippingbox"
            case .deployment: return "cloud.arrow.up"
            case .constraints: return "exclamationmark.shield"
            case .bestPractices: return "star"
            case .definitionsReference: return "doc.text.magnifyingglass"
            case .featureModules: return "app.badge"
            case .caching: return "memorychip"
            case .migration: return "arrow.up.doc"
            case .localization: return "globe"
            case .featureFlags: return "flag"
            case .realtimeSync: return "arrow.triangle.2.circlepath.circle"
            case .aiIntegration: return "brain.head.profile"
            case .toolSystem: return "wrench.and.screwdriver"
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
                SDKSectionHeader("Developer Documentation", subtitle: "Complete SDK Architecture & Integration Reference", alignment: .leading)
            }

            switch selectedCategory {
            case .tableOfContents: TableOfContentsSection(onSelect: { selectedCategory = $0 })
            case .introduction: IntroductionSection()
            case .kernelLifecycle: KernelLifecycleSection()
            case .moduleSystem: ModuleSystemSection()
            case .pluginArchitecture: PluginArchitectureSection()
            case .connectorSystem: ConnectorsSection()
            case .dependencyManagement: DependenciesSection()
            case .runtimeExecution: RuntimeExecutionSection()
            case .dataLayer: DataLayerSection()
            case .eventSystem: EventSystemSection()
            case .security: SecuritySection()
            case .diContainer: DIContainerSection()
            case .routerAPI: RouterAPISection()
            case .automationEngine: AutomationSection()
            case .swiftUIIntegration: SwiftUIIntegrationSection()
            case .packaging: PackagingSection()
            case .deployment: DeploymentSection()
            case .constraints: ConstraintsSection()
            case .bestPractices: BestPracticesSection()
            case .definitionsReference: DefinitionsReferenceSection()
            case .featureModules: FeatureModulesSection()
            case .caching: CachingSection()
            case .migration: MigrationSection()
            case .localization: LocalizationSection()
            case .featureFlags: FeatureFlagsSection()
            case .realtimeSync: RealtimeSyncSection()
            case .aiIntegration: AIIntegrationSection()
            case .toolSystem: ToolSystemSection()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dev Guide")
    }
}

// MARK: - Table of Contents

private struct TableOfContentsSection: View {
    let onSelect: (SDKDeveloperGuideView.GuideCategory) -> Void

    var body: some View {
        Section(header: Text("SDK Platform Architecture")) {
            tocRow(.introduction, "Platform overview, key technologies, and system layers")
            tocRow(.kernelLifecycle, "Boot sequence, shutdown, state machine, health checks")
        }
        Section(header: Text("Core Systems")) {
            tocRow(.moduleSystem, "Module registration, activation, capabilities, feature exposure")
            tocRow(.pluginArchitecture, "Plugin lifecycle, manifests, sandboxing, app runtime")
            tocRow(.connectorSystem, "External service bridges, auth methods, runtime binding")
            tocRow(.dependencyManagement, "Dependency graph, topological sort, conflict resolution")
        }
        Section(header: Text("Runtime & Data")) {
            tocRow(.runtimeExecution, "Execution pipeline, contexts, scopes, governed operations")
            tocRow(.dataLayer, "SDKModel, offline-first persistence, indexing, batch ops")
            tocRow(.eventSystem, "Event bus, channels, subscriptions, history, bridging")
        }
        Section(header: Text("Infrastructure")) {
            tocRow(.security, "Permissions, policies, rate limiting, audit, sandboxing")
            tocRow(.diContainer, "ServiceContainer, ServiceRegistry, protocol-based resolution")
            tocRow(.routerAPI, "Internal API routing, endpoint registration, default routes")
            tocRow(.automationEngine, "Trigger/condition/action rules, automation execution")
        }
        Section(header: Text("UI & Integration")) {
            tocRow(.swiftUIIntegration, "Observable patterns, singleton access, view architecture")
            tocRow(.packaging, "SDK export, bundle structure, import validation")
            tocRow(.deployment, "Versioning, build configuration, integration tests")
        }
        Section(header: Text("Feature Modules")) {
            tocRow(.featureModules, "Mail, Meet, Notebooks, Articles — domain service APIs")
            tocRow(.aiIntegration, "AI slide generation, image providers, prompt pipelines")
            tocRow(.toolSystem, "Tool runtime, DevTool protocol, tool registration")
        }
        Section(header: Text("Platform Services")) {
            tocRow(.caching, "Cache management, memory policies, eviction strategies")
            tocRow(.migration, "Schema migration, version management, data upgrades")
            tocRow(.localization, "Internationalization, locale management, string catalogs")
            tocRow(.featureFlags, "Feature flag service, A/B testing, progressive rollouts")
            tocRow(.realtimeSync, "Real-time synchronization, conflict resolution, sync engine")
        }
        Section(header: Text("Reference")) {
            tocRow(.constraints, "System constraints, prohibited interactions, security boundaries")
            tocRow(.bestPractices, "Architecture, module design, plugin dev, connector integration")
            tocRow(.definitionsReference, "50+ structured type definitions for all SDK systems")
        }
    }

    private func tocRow(_ category: SDKDeveloperGuideView.GuideCategory, _ description: String) -> some View {
        Button {
            onSelect(category)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue).font(.subheadline.bold())
                    Text(description).font(.caption2).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: category.icon).foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Introduction

private struct IntroductionSection: View {
    var body: some View {
        Section(header: Text("Platform Overview")) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workspace SDK Platform").font(.headline)
                Text("ToolsKit provides a comprehensive, production-grade SDK for building and extending the Workspace OS. The platform is built on a modular kernel that manages data, security, and execution environments. All code is native Swift/SwiftUI targeting iOS, macOS, watchOS, and tvOS.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }.padding(.vertical, 4)
        }
        Section(header: Text("Key Technologies")) {
            GuideDefRow(name: "Swift & SwiftUI", description: "Primary language and UI framework for all SDK components", icon: "swift")
            GuideDefRow(name: "Combine", description: "Reactive framework powering event streams and state propagation", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Foundation", description: "Core data types, networking, file I/O, and concurrency", icon: "cube.box")
            GuideDefRow(name: "UserDefaults", description: "Lightweight key-value persistence for configuration and feature flags", icon: "gearshape")
            GuideDefRow(name: "FileManager", description: "File-based JSON storage for data store and event history", icon: "folder")
        }
        Section(header: Text("System Layers")) {
            GuideDefRow(name: "Kernel", description: "Bootstrap, lifecycle, health monitoring, uptime tracking", icon: "power")
            GuideDefRow(name: "Services", description: "Domain-specific business logic (Mail, Notebooks, Meet, Articles)", icon: "tray.full")
            GuideDefRow(name: "Data", description: "Offline-first JSON persistence with indexing and versioning", icon: "database")
            GuideDefRow(name: "Events", description: "Pub/sub real-time communication across all modules", icon: "antenna.radiowaves.left.and.right")
            GuideDefRow(name: "Security", description: "Permissions, policies, rate limiting, audit logging", icon: "shield.checkered")
            GuideDefRow(name: "Router", description: "On-device internal API endpoints and request handling", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            GuideDefRow(name: "DI", description: "Protocol-based dependency injection and service resolution", icon: "tray.full")
            GuideDefRow(name: "Modules", description: "Dynamic module registration, capability exposure, feature discovery", icon: "square.grid.3x3.fill")
            GuideDefRow(name: "Plugins", description: "App/plugin lifecycle, manifests, sandboxed execution", icon: "puzzlepiece")
            GuideDefRow(name: "Connectors", description: "External service bridges with auth, sync, and binding", icon: "link")
        }
        Section(header: Text("Public API Facade")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessing the SDK").font(.caption.bold())
                Text("""
                let sdk = WorkspaceSDK.shared
                await sdk.initialize()

                // Access subsystems
                sdk.mail        // Email operations
                sdk.notebooks   // Notebook CRUD
                sdk.meet        // Meeting sessions
                sdk.articles    // Article publishing
                sdk.plugins     // Plugin runtime
                sdk.storage     // Data persistence
                sdk.events      // Event bus
                sdk.router      // API routing
                sdk.security    // Permissions
                sdk.kernel      // Lifecycle
                sdk.environment // Configuration
                sdk.services    // DI container
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Kernel & Lifecycle

private struct KernelLifecycleSection: View {
    var body: some View {
        Section(header: Text("Kernel State Machine")) {
            Text("WorkspaceSDKKernel manages the entire SDK lifecycle through a strict state machine. Boot is only permitted from idle or error states.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "idle", description: "SDK not started. Initial state and post-shutdown state.", icon: "stop.circle")
            GuideDefRow(name: "booting", description: "Boot sequence in progress. Services initializing.", icon: "arrow.clockwise")
            GuideDefRow(name: "ready", description: "All services initialized. SDK fully operational.", icon: "checkmark.circle")
            GuideDefRow(name: "error", description: "Boot failed. Can retry boot from this state.", icon: "exclamationmark.triangle")
            GuideDefRow(name: "shuttingDown", description: "Graceful shutdown in progress.", icon: "power")
        }
        Section(header: Text("Boot Sequence")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sequential initialization order").font(.caption.bold())
                Text("""
                1. SDKEnvironment.shared.load()
                2. ServiceContainer.shared.registerDefaults()
                3. SDKDataStore.shared.initialize()
                4. SDKEventBus.shared.start()
                5. SDKRouter.shared.registerDefaultRoutes()
                6. SDKPermissionManager.shared init
                7. PluginRuntimeEngine.shared.initialize()
                8. Feature modules: Mail, Notebook, Meet, Articles
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Shutdown Sequence")) {
            GuideDefRow(name: "Step 1", description: "Publish kernel.shutdown event on sdk.lifecycle channel", icon: "1.circle")
            GuideDefRow(name: "Step 2", description: "PluginRuntimeEngine.shared.stopAll() — stop all running apps", icon: "2.circle")
            GuideDefRow(name: "Step 3", description: "SDKDataStore.shared.flush() — persist all collections to disk", icon: "3.circle")
            GuideDefRow(name: "Step 4", description: "SDKEventBus.shared.stop() — persist history, stop bus", icon: "4.circle")
            GuideDefRow(name: "Step 5", description: "Reset state to idle, clear boot time and uptime", icon: "5.circle")
        }
        Section(header: Text("Health Monitoring")) {
            GuideDefRow(name: "KernelHealth", description: "Reports state, uptime, registered services, loaded plugins, data store and event bus health", icon: "heart.text.square")
            GuideDefRow(name: "isHealthy", description: "True when state == .ready AND dataStore AND eventBus are healthy", icon: "checkmark.shield")
            GuideDefRow(name: "Uptime Timer", description: "1-second interval timer tracking seconds since boot", icon: "timer")
        }
    }
}

// MARK: - Module System

private struct ModuleSystemSection: View {
    var body: some View {
        Section(header: Text("Module Architecture")) {
            Text("SDK modules are self-contained units that expose capabilities and features to the runtime. Modules register dynamically through SDKModuleRegistry and declare their dependencies, capabilities, and exported services.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Module Descriptor")) {
            GuideDefRow(name: "identifier", description: "Unique reverse-domain string (e.g., com.app.analytics). Must be globally unique.", icon: "textformat")
            GuideDefRow(name: "displayName", description: "Human-readable name shown in UI", icon: "text.badge.star")
            GuideDefRow(name: "version", description: "Semantic version string (e.g., 1.0.0)", icon: "number")
            GuideDefRow(name: "minimumSDKVersion", description: "Minimum SDK version required (default: 2.0.0)", icon: "arrow.up.circle")
            GuideDefRow(name: "capabilities", description: "Array of SDKModuleCapability values this module provides", icon: "square.stack.3d.up")
            GuideDefRow(name: "dependencies", description: "Array of module identifiers this module requires", icon: "point.3.connected.trianglepath.dotted")
            GuideDefRow(name: "exportedServices", description: "Service keys this module provides to the DI container", icon: "tray.and.arrow.up")
            GuideDefRow(name: "loadPriority", description: "Integer load order — lower values load first (default: 100)", icon: "arrow.up.arrow.down")
        }
        Section(header: Text("14 Module Capabilities")) {
            Text("dataAccess, networking, storage, rendering, automation, authentication, analytics, messaging, fileSystem, aiProcessing, connectorBinding, pluginHosting, eventPublishing, backgroundExecution")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
        Section(header: Text("Registration Flow")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Registering a Module").font(.caption.bold())
                Text("""
                let descriptor = SDKModuleDescriptor(
                    identifier: "com.app.analytics",
                    displayName: "Analytics",
                    capabilities: [.analytics, .eventPublishing],
                    dependencies: ["com.app.core"],
                    loadPriority: 50
                )
                try SDKModuleRegistry.shared.register(descriptor)
                try await SDKModuleRegistry.shared.activate(
                    identifier: "com.app.analytics"
                )
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Feature Exposure")) {
            GuideDefRow(name: "SDKExposedFeature", description: "Feature with typed input schema, output type, required capabilities", icon: "rectangle.and.text.magnifyingglass")
            GuideDefRow(name: "SDKFeatureParameter", description: "Typed parameter with name, type, isRequired, defaultValue", icon: "slider.horizontal.3")
            GuideDefRow(name: "SDKFeatureExposureManager", description: "Expose, retract, invoke, search features across modules", icon: "magnifyingglass")
        }
        Section(header: Text("Module Provider Protocol")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Implementing a Module Provider").font(.caption.bold())
                Text("""
                protocol SDKModuleProvider {
                    var descriptor: SDKModuleDescriptor { get }
                    func activate(context: SDKContext) async throws
                    func deactivate() async
                    func healthCheck() -> Bool
                }
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Plugin Architecture

private struct PluginArchitectureSection: View {
    var body: some View {
        Section(header: Text("Plugin System Overview")) {
            Text("Two plugin systems coexist: SDKPlugin (lightweight, tool-based) and SDKPluginManifest (full lifecycle). Both enforce permission boundaries and support automation hooks.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Plugin Lifecycle Phases")) {
            GuideDefRow(name: "unloaded", description: "Plugin installed but not loaded into memory", icon: "arrow.down.circle")
            GuideDefRow(name: "loading", description: "Plugin being loaded, dependencies resolving", icon: "arrow.clockwise")
            GuideDefRow(name: "active", description: "Plugin fully operational, handling events", icon: "checkmark.circle.fill")
            GuideDefRow(name: "paused", description: "Plugin temporarily suspended, state preserved", icon: "pause.circle")
            GuideDefRow(name: "updating", description: "Plugin being updated to new version", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "migrating", description: "Plugin data being migrated between versions", icon: "arrow.right.arrow.left")
            GuideDefRow(name: "errored", description: "Plugin encountered unrecoverable error", icon: "exclamationmark.triangle")
            GuideDefRow(name: "disabled", description: "Plugin explicitly disabled by user or system", icon: "xmark.circle")
        }
        Section(header: Text("Plugin Permissions")) {
            GuideDefRow(name: "readData", description: "Read workspace data within allowed scopes", icon: "eye")
            GuideDefRow(name: "writeData", description: "Write/modify workspace data within allowed scopes", icon: "pencil")
            GuideDefRow(name: "network", description: "Make outbound network requests", icon: "network")
            GuideDefRow(name: "notifications", description: "Send push notifications to the user", icon: "bell")
            GuideDefRow(name: "fileAccess", description: "Access the local file system", icon: "folder")
        }
        Section(header: Text("Plugin Categories")) {
            Text("productivity, communication, development, analytics, automation, integration, utility, ai")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
        Section(header: Text("Plugin Capability")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Defining Plugin Capabilities").font(.caption.bold())
                Text("""
                struct SDKPluginCapability {
                    var name: String
                    var description: String
                    var requiredPermissions: [PluginPermission]
                    var injectedServiceKey: String?
                }
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("App Runtime Engine")) {
            GuideDefRow(name: "register(app)", description: "Validate uniqueness, check all permissions authorized, persist", icon: "plus.circle")
            GuideDefRow(name: "start(appId)", description: "Verify sandbox permissions, call onStart(), mark running", icon: "play.circle")
            GuideDefRow(name: "stop(appId)", description: "Call onStop(), remove from running set, persist", icon: "stop.circle")
            GuideDefRow(name: "unregister(appId)", description: "Stop, remove lifecycle handler, remove from loaded apps", icon: "minus.circle")
        }
    }
}

// MARK: - Connector System

private struct ConnectorsSection: View {
    var body: some View {
        Section(header: Text("Connector System")) {
            Text("Connectors bridge external services with the SDK runtime. Each connector implements BaseConnector protocol providing authentication, synchronization, and health monitoring.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("BaseConnector Protocol")) {
            GuideDefRow(name: "authenticate(credentials:)", description: "Establish connection with external service using provided credentials", icon: "lock.open")
            GuideDefRow(name: "sync()", description: "Synchronize data between external service and SDK data store", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "testConnection()", description: "Verify connectivity and return health status", icon: "checkmark.icloud")
            GuideDefRow(name: "disconnect()", description: "Tear down connection and clean up resources", icon: "xmark.icloud")
        }
        Section(header: Text("Built-in Connectors")) {
            GuideDefRow(name: "Gmail", description: "OAuth2 email integration with message sync", icon: "envelope")
            GuideDefRow(name: "GitHub", description: "Personal Access Token auth with repository sync", icon: "chevron.left.forwardslash.chevron.right")
            GuideDefRow(name: "Webhook", description: "Generic HTTP endpoint for event-driven integrations", icon: "arrow.up.forward.app")
            GuideDefRow(name: "Calendar", description: "Calendar event synchronization via OAuth2", icon: "calendar")
            GuideDefRow(name: "Local File System", description: "File-based data import/export with no auth", icon: "folder")
        }
        Section(header: Text("Authentication Methods")) {
            Text("none, apiKey, oauth2, bearer, basic, certificate, webhook")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
        Section(header: Text("Runtime Binding")) {
            GuideDefRow(name: "dataSource", description: "Connector provides data to the bound module", icon: "arrow.right")
            GuideDefRow(name: "dataSink", description: "Module sends data to the connector for external storage", icon: "arrow.left")
            GuideDefRow(name: "eventTrigger", description: "Connector events trigger module actions", icon: "bolt")
            GuideDefRow(name: "authProvider", description: "Connector provides authentication to the module", icon: "lock")
            GuideDefRow(name: "configSource", description: "Connector provides configuration to the module", icon: "gearshape")
        }
        Section(header: Text("Connector Templates")) {
            GuideDefRow(name: "REST API", description: "Pre-configured template for RESTful API integration", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            GuideDefRow(name: "GraphQL", description: "Template for GraphQL endpoint integration", icon: "circle.grid.cross")
            GuideDefRow(name: "WebSocket", description: "Real-time bidirectional communication template", icon: "bolt.horizontal")
            GuideDefRow(name: "Firebase", description: "Firebase Realtime Database/Firestore template", icon: "flame")
            GuideDefRow(name: "Slack", description: "Slack API integration template", icon: "number")
            GuideDefRow(name: "MQTT", description: "IoT message broker template", icon: "sensor.tag.radiowaves.forward")
        }
        Section(header: Text("Live Streaming")) {
            GuideDefRow(name: "startLiveStream()", description: "Begin timer-based polling at configurable intervals", icon: "play.fill")
            GuideDefRow(name: "stopLiveStream()", description: "Cancel polling timer and stop data streaming", icon: "stop.fill")
            GuideDefRow(name: "Event Channel", description: "Events published to sdk.connectors.stream channel", icon: "antenna.radiowaves.left.and.right")
        }
    }
}

// MARK: - Dependencies

private struct DependenciesSection: View {
    var body: some View {
        Section(header: Text("Dependency Management")) {
            Text("The SDK dependency system manages libraries, modules, and their interconnections. Dependencies are represented as directed graphs with conflict detection and resolution.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Dependency Graph Resolution")) {
            GuideDefRow(name: "Topological Sort", description: "Modules sorted by loadPriority, then depth-first traversal resolves order", icon: "arrow.triangle.branch")
            GuideDefRow(name: "Cycle Detection", description: "Circular dependencies detected during traversal and reported as conflicts", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Missing Dependencies", description: "Required modules not in registry flagged as missingDependency conflicts", icon: "exclamationmark.triangle")
            GuideDefRow(name: "Version Conflicts", description: "Incompatible version requirements between dependent modules detected", icon: "arrow.left.arrow.right")
            GuideDefRow(name: "Capability Collisions", description: "Exclusive capabilities (authentication, connectorBinding) checked for duplicates", icon: "exclamationmark.2")
        }
        Section(header: Text("Library System")) {
            GuideDefRow(name: "SDKLibraryDefinition", description: "Reusable libraries with version, scopes, exported functions, pipeline stages", icon: "books.vertical")
            GuideDefRow(name: "SDKLibraryVersionResolver", description: "Semantic version comparison and preferred version resolution", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "SDKLibraryDependencyBridge", description: "Converts library definitions into dependency graph nodes", icon: "arrow.triangle.branch")
            GuideDefRow(name: "SDKLibraryScopeBinder", description: "Binds library capabilities to specific SDK scopes", icon: "link.badge.plus")
        }
        Section(header: Text("Dependency Node Types")) {
            Text("library | connector | plugin | sdkApp")
                .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        }
        Section(header: Text("Resolution Output")) {
            GuideDefRow(name: "orderedModules", description: "Topologically sorted array of modules in load order", icon: "list.number")
            GuideDefRow(name: "conflicts", description: "All detected DependencyConflict instances", icon: "exclamationmark.triangle")
            GuideDefRow(name: "warnings", description: "Non-fatal issues (e.g., graph > 50 modules)", icon: "info.circle")
            GuideDefRow(name: "isClean", description: "True only when zero conflicts exist", icon: "checkmark.circle")
        }
    }
}

// MARK: - Runtime & Execution

private struct RuntimeExecutionSection: View {
    var body: some View {
        Section(header: Text("Execution Pipeline")) {
            Text("Every governed operation in ToolsKitSDK follows a strict 8-stage pipeline ensuring security, auditing, and rate limiting on every call.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Pipeline Stages")) {
            GuideDefRow(name: "1. Scope Validation", description: "SDKScopeManager.validateAccess() checks operation is within allowed scope", icon: "1.circle")
            GuideDefRow(name: "2. Policy Evaluation", description: "SDKPolicyEngine.evaluate() returns scope definition and rate rule", icon: "2.circle")
            GuideDefRow(name: "3. Rate Limiting", description: "SDKRateLimiter.enforce() with token bucket algorithm", icon: "3.circle")
            GuideDefRow(name: "4. Security Enforcement", description: "SDKSecurityManager.enforce() checks permissions, denied scopes, API keys", icon: "4.circle")
            GuideDefRow(name: "5. Privacy Filtering", description: "SDKPrivacyManager.redactRestrictedFields() strips sensitive data", icon: "5.circle")
            GuideDefRow(name: "6. Audit Logging", description: "SDKAuditLogger.log() records operation details", icon: "6.circle")
            GuideDefRow(name: "7. Execution", description: "Actual operation runs against data engine or external service", icon: "7.circle")
            GuideDefRow(name: "8. Event Emission", description: "Results published via SDKEventBridge to notify subscribers", icon: "8.circle")
        }
        Section(header: Text("SDKContext")) {
            GuideDefRow(name: "Scopes", description: "global, workspace, feature, plugin, request", icon: "rectangle.3.group")
            GuideDefRow(name: "Permissions", description: "Set of string tokens, wildcard '*' grants all", icon: "key")
            GuideDefRow(name: "Hierarchy", description: "Parent context chain for permission inheritance", icon: "arrow.up.forward")
            GuideDefRow(name: "Metadata", description: "Key-value pairs carrying request-scoped data", icon: "tag")
        }
        Section(header: Text("Data Scopes (SDKScope)")) {
            Text("all, tasks, notes, calendar, files, emails, whiteboards, plugins, slides, media, meet, repos, automations, intelligence, persona, custom(query:)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Data Layer

private struct DataLayerSection: View {
    var body: some View {
        Section(header: Text("Data Store Architecture")) {
            Text("SDKDataStore provides unified offline-first persistence using file-based JSON storage. All models implement the SDKModel protocol for consistent CRUD, indexing, and versioning.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("SDKModel Protocol")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Required Conformance").font(.caption.bold())
                Text("""
                protocol SDKModel: Identifiable, Codable {
                    var id: UUID { get }
                    var createdAt: Date { get }
                    var updatedAt: Date { get }
                    var modelVersion: Int { get }  // default: 1
                }
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Built-in Models")) {
            GuideDefRow(name: "SDKMailMessage", description: "Email with from, to, cc, bcc, subject, body, labels, thread", icon: "envelope")
            GuideDefRow(name: "SDKNotebook", description: "Notebook with pages, tags, pinning, version history", icon: "book")
            GuideDefRow(name: "SDKMeetSession", description: "Meeting with participants, status, room URL, notes", icon: "video")
            GuideDefRow(name: "SDKArticle", description: "Article with content, author, tags, publish state, word count", icon: "doc.text")
            GuideDefRow(name: "SDKAppDefinition", description: "Plugin/app with version, permissions, sandbox flag, scopes", icon: "app")
        }
        Section(header: Text("Data Operations")) {
            GuideDefRow(name: "save(model)", description: "Persist any SDKModel to file-based JSON storage", icon: "square.and.arrow.down")
            GuideDefRow(name: "fetch(type, id)", description: "Retrieve single model by UUID", icon: "magnifyingglass")
            GuideDefRow(name: "fetchAll(type)", description: "Retrieve all models of a type, sorted by updatedAt descending", icon: "list.bullet")
            GuideDefRow(name: "delete(type, id)", description: "Remove model from collection and persist", icon: "trash")
            GuideDefRow(name: "query(type, predicate)", description: "Filter models using a Swift predicate closure", icon: "line.3.horizontal.decrease")
            GuideDefRow(name: "batchSave(models)", description: "Save multiple models in sequence", icon: "square.stack")
            GuideDefRow(name: "fetchByIndex(type, key, value)", description: "Query using pre-built indices for fast lookup", icon: "bolt.circle")
        }
    }
}

// MARK: - Event System

private struct EventSystemSection: View {
    var body: some View {
        Section(header: Text("Event Bus")) {
            Text("SDKEventBus is the unified pub/sub system for real-time communication across all SDK modules. Events are persisted to disk and bridged to legacy systems.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Event Channels")) {
            GuideDefRow(name: "sdk.lifecycle", description: "Kernel boot/shutdown events", icon: "power")
            GuideDefRow(name: "sdk.modules", description: "Module registration and activation events", icon: "square.grid.3x3.fill")
            GuideDefRow(name: "sdk.plugins", description: "Plugin phase transition events", icon: "puzzlepiece")
            GuideDefRow(name: "sdk.apps", description: "App registration, start, stop events", icon: "app")
            GuideDefRow(name: "sdk.connectors", description: "Connector binding events", icon: "link")
            GuideDefRow(name: "sdk.connectors.stream", description: "Live data streaming tick events", icon: "bolt.horizontal")
            GuideDefRow(name: "sdk.features", description: "Feature exposure and retraction events", icon: "rectangle.and.text.magnifyingglass")
        }
        Section(header: Text("SDKBusEvent Structure")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Payload").font(.caption.bold())
                Text("""
                struct SDKBusEvent: Identifiable, Codable {
                    let id: UUID
                    let channel: String
                    let name: String
                    let data: [String: String]
                    let source: String
                    let timestamp: Date
                }
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Subscription Patterns")) {
            GuideDefRow(name: "subscribe(channel:)", description: "Receive events matching a specific channel", icon: "antenna.radiowaves.left.and.right")
            GuideDefRow(name: "subscribe(name:)", description: "Receive events matching a specific event name", icon: "text.magnifyingglass")
            GuideDefRow(name: "subscribeAll()", description: "Receive all events from all channels", icon: "tray.full")
        }
        Section(header: Text("History & Persistence")) {
            GuideDefRow(name: "History Limit", description: "500 events retained in memory, oldest evicted", icon: "clock.arrow.circlepath")
            GuideDefRow(name: "Persistence", description: "History saved to event_history.json on stop, loaded on start", icon: "externaldrive")
            GuideDefRow(name: "Query", description: "Filter by channel, date range, or get recent N events", icon: "magnifyingglass")
        }
    }
}

// MARK: - Security

private struct SecuritySection: View {
    var body: some View {
        Section(header: Text("Security Model")) {
            Text("Hierarchical permission scopes ensure that modules only access necessary data. High-risk scopes require explicit user justification. All operations are rate-limited and audited.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Permission Hierarchy")) {
            GuideDefRow(name: "Wildcard '*'", description: "Grants unrestricted access to all scopes", icon: "asterisk")
            GuideDefRow(name: "SDKContext Chain", description: "Permissions inherited from parent contexts up the hierarchy", icon: "arrow.up.forward")
            GuideDefRow(name: "App Boundaries", description: "Per-app permission sets enforced by SDKSecurityManager", icon: "rectangle.badge.person.crop")
            GuideDefRow(name: "Global Denied Scopes", description: "Denied scopes override all grants, including wildcard", icon: "xmark.shield")
        }
        Section(header: Text("Security Scope Definitions")) {
            GuideDefRow(name: "riskLevel", description: "low, medium, high, critical — determines rate limits", icon: "gauge.with.dots.needle.33percent")
            GuideDefRow(name: "requiresJustification", description: "High-risk scopes require explicit justification string", icon: "text.bubble")
            GuideDefRow(name: "runtimeValidationHook", description: "Optional callback for additional runtime checks", icon: "function")
        }
        Section(header: Text("Rate Limiting")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Token Bucket Algorithm").font(.caption.bold())
                Text("""
                Low:      180 req/min, 5000 fetch, 180 exec
                Medium:   120 req/min, 2500 fetch, 120 exec
                High:      60 req/min, 1000 fetch,  60 exec
                Critical:  30 req/min,  500 fetch,  30 exec
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Audit Logging")) {
            GuideDefRow(name: "Event Types", description: "dataAccess, scopeUsage, externalAPICall, execution, privacy, security", icon: "list.clipboard")
            GuideDefRow(name: "Capacity", description: "5000 events max with automatic oldest-first eviction", icon: "externaldrive")
            GuideDefRow(name: "Query", description: "Filter by projectID, eventType, date range", icon: "magnifyingglass")
        }
        Section(header: Text("Sandbox Enforcement")) {
            GuideDefRow(name: "isSandboxed", description: "Sandboxed plugins have permissions re-verified at every start", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "No-Sandbox Mode", description: "Development toggle via SDKRuntimeEngine for testing", icon: "shield.slash")
        }
    }
}

// MARK: - DI Container

private struct DIContainerSection: View {
    var body: some View {
        Section(header: Text("Dependency Injection")) {
            Text("ServiceContainer and ServiceRegistry provide protocol-based dependency injection. Services are registered as singletons by default with factory closures for lazy initialization.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Default Registrations")) {
            GuideDefRow(name: "SDKDataStoreProtocol", description: "→ SDKDataStore.shared", icon: "database")
            GuideDefRow(name: "SDKEventBusProtocol", description: "→ SDKEventBus.shared", icon: "antenna.radiowaves.left.and.right")
            GuideDefRow(name: "SDKRouterProtocol", description: "→ SDKRouter.shared", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            GuideDefRow(name: "SDKPermissionManagerProtocol", description: "→ SDKPermissionManager.shared", icon: "lock.shield")
            GuideDefRow(name: "PluginRuntimeProtocol", description: "→ PluginRuntimeEngine.shared", icon: "puzzlepiece")
            GuideDefRow(name: "Feature Services", description: "Mail, Notebook, Meet, Article services", icon: "tray.full")
        }
        Section(header: Text("Service Scopes")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Resolution Example").font(.caption.bold())
                Text("""
                // Resolve a service
                let store = ServiceContainer.shared.resolve(
                    SDKDataStoreProtocol.self
                )

                // Register custom
                ServiceContainer.shared.register(
                    MyProtocol.self,
                    scope: .singleton
                ) { MyImplementation() }
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Router & API

private struct RouterAPISection: View {
    var body: some View {
        Section(header: Text("Internal API Router")) {
            Text("SDKRouter provides on-device API routing with standardized request/response handling. Routes are registered with path patterns, HTTP methods, and async handlers.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Default Routes")) {
            GuideDefRow(name: "GET /sdk/health", description: "Returns { status: healthy, version: 2.0.0 }", icon: "heart")
            GuideDefRow(name: "GET /sdk/info", description: "Returns SDK version, build number, environment", icon: "info.circle")
            GuideDefRow(name: "GET /sdk/services", description: "Lists all registered service names", icon: "list.bullet")
            GuideDefRow(name: "POST /mail/send", description: "Send email with to, subject, body parameters", icon: "envelope")
            GuideDefRow(name: "GET /mail/list", description: "List all email messages with count", icon: "tray")
            GuideDefRow(name: "POST /notebooks/create", description: "Create notebook with title parameter", icon: "book")
            GuideDefRow(name: "POST /meet/create", description: "Create meeting session with title", icon: "video")
            GuideDefRow(name: "POST /articles/create", description: "Create article with title and content", icon: "doc.text")
        }
        Section(header: Text("Request/Response")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Call Example").font(.caption.bold())
                Text("""
                let response = try await WorkspaceSDK.shared.api(
                    "/sdk/health",
                    method: .get
                )
                // response.status == .success
                // response.data["status"] == "healthy"
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Automation

private struct AutomationSection: View {
    var body: some View {
        Section(header: Text("Automation Engine")) {
            Text("SDKAutomationEngine evaluates rules in a trigger → condition → action pipeline. Rules are persisted via SDKProjectManager and execute tools, sync connectors, or send notifications.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Triggers")) {
            GuideDefRow(name: "dataUpdated(scope:)", description: "Fires when data in the specified scope changes", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "connectorEvent(id, name)", description: "Fires when a connector emits a specific event", icon: "link")
            GuideDefRow(name: "timeBased(interval:)", description: "Fires at a recurring time interval", icon: "timer")
        }
        Section(header: Text("Conditions")) {
            GuideDefRow(name: "fieldEquals(key, value)", description: "Check if a context field matches expected value", icon: "equal")
            GuideDefRow(name: "countExceeds(count)", description: "Check if context 'count' field exceeds threshold", icon: "greaterthan")
        }
        Section(header: Text("Actions")) {
            GuideDefRow(name: "runTool(toolID, input)", description: "Execute a registered SDK tool with input parameters", icon: "wrench")
            GuideDefRow(name: "syncConnector(connectorID)", description: "Trigger sync on a specific connector", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "sendNotification(title, body)", description: "Send a local push notification", icon: "bell")
            GuideDefRow(name: "exportData(scope)", description: "Export data from a specific scope as SDK bundle", icon: "square.and.arrow.up")
        }
    }
}

// MARK: - SwiftUI Integration

private struct SwiftUIIntegrationSection: View {
    var body: some View {
        Section(header: Text("Observable Architecture")) {
            Text("All SDK managers use @MainActor and ObservableObject to drive SwiftUI view updates through @Published properties. Combine provides reactive data flow for event streaming.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("State Management Patterns")) {
            GuideDefRow(name: "@Published", description: "Properties on ObservableObject that trigger view updates", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "@StateObject", description: "View-owned observable objects created once per view lifecycle", icon: "rectangle.badge.plus")
            GuideDefRow(name: "@ObservedObject", description: "Injected observable objects from parent views", icon: "arrow.right.circle")
            GuideDefRow(name: "@State", description: "View-local state for simple values", icon: "square.and.pencil")
            GuideDefRow(name: "Combine", description: "PassthroughSubject for event streaming, AnyCancellable for subscriptions", icon: "arrow.triangle.merge")
        }
        Section(header: Text("Singleton Access")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("All core services are singletons").font(.caption.bold())
                Text("""
                WorkspaceSDK.shared
                WorkspaceSDKKernel.shared
                SDKModuleRegistry.shared
                SDKPluginManager.shared
                SDKConnectorManager.shared
                SDKEventBus.shared
                SDKDataStore.shared
                SDKRouter.shared
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Navigation Patterns")) {
            GuideDefRow(name: "NavigationStack", description: "Primary navigation container for all SDK views", icon: "sidebar.leading")
            GuideDefRow(name: ".navigationTitle()", description: "Standard title modifier on all views", icon: "textformat")
            GuideDefRow(name: ".sheet()", description: "Modal presentation with .presentationDetents() for adaptive sizing", icon: "rectangle.portrait.and.arrow.right")
            GuideDefRow(name: "Toolbar", description: "ToolbarItem placement for actions and controls", icon: "rectangle.topthird.inset.filled")
        }
    }
}

// MARK: - Packaging

private struct PackagingSection: View {
    var body: some View {
        Section(header: Text("SDK Export")) {
            Text("SDK projects can be packaged as versioned .zip bundles containing modules, plugins, connectors, tools, automation rules, and runtime definitions.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Export Pipeline")) {
            GuideDefRow(name: "SDKExportService", description: "Creates temp directory structure, encodes config.json, organizes all project assets", icon: "square.and.arrow.up")
            GuideDefRow(name: "SDKDownloadView", description: "Version selection, bundle download, and export configuration interface", icon: "arrow.down.circle")
        }
        Section(header: Text("Import Pipeline")) {
            GuideDefRow(name: "CustomAppSDKView", description: "Import .zip bundles, validate structure and compatibility, register into runtime", icon: "arrow.down.doc")
            GuideDefRow(name: "Validation", description: "SDK version match, module integrity, plugin compatibility, connector support checks", icon: "checkmark.shield")
        }
        Section(header: Text("Bundle Structure")) {
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

// MARK: - Deployment

private struct DeploymentSection: View {
    var body: some View {
        Section(header: Text("Release Pipeline")) {
            GuideDefRow(name: "Versioning", description: "Semantic versioning (SemVer) required for all SDK modules", icon: "number")
            GuideDefRow(name: "Validation", description: "Automated verification of capability and action schemas", icon: "checkmark.shield")
        }
        Section(header: Text("Build Configuration")) {
            GuideDefRow(name: "Build Modes", description: "Debug, Release, and Profile modes with platform targeting (iOS, macOS, watchOS, tvOS)", icon: "hammer")
            GuideDefRow(name: "Integration Tests", description: "Automated testing of module integrations and connector health", icon: "testtube.2")
            GuideDefRow(name: "SDKDeploymentView", description: "Project export, provisioning, and distribution management", icon: "cloud.arrow.up")
        }
        Section(header: Text("Environment Configuration")) {
            GuideDefRow(name: "development", description: "Local development with debug logging and sandbox bypass", icon: "ladybug")
            GuideDefRow(name: "staging", description: "Pre-production testing with production-like constraints", icon: "arrow.clockwise")
            GuideDefRow(name: "production", description: "Full security enforcement, analytics enabled, encrypted storage", icon: "lock.shield")
        }
    }
}

// MARK: - Constraints & Rules

private struct ConstraintsSection: View {
    var body: some View {
        Section(header: Text("System Constraints")) {
            Text("These constraints are enforced at runtime and must not be circumvented by any SDK consumer, plugin, or module.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section(header: Text("Prohibited Interactions")) {
            GuideDefRow(name: "No External Knowledge", description: "AI features must derive all context from SDK_AI_System.md only", icon: "xmark.circle")
            GuideDefRow(name: "No Hardcoded Prompts", description: "System prompts must be constructed from SDK documentation at runtime", icon: "xmark.circle")
            GuideDefRow(name: "No Unscoped Data Access", description: "All data operations must go through the governed execution pipeline", icon: "xmark.circle")
            GuideDefRow(name: "No Direct File System", description: "Use SDKDataStore or SDKStorageManager for all persistence", icon: "xmark.circle")
            GuideDefRow(name: "No Unaudited Operations", description: "All sensitive operations must be logged via SDKAuditLogger", icon: "xmark.circle")
            GuideDefRow(name: "No Permission Escalation", description: "Apps cannot grant themselves permissions beyond their manifest", icon: "xmark.circle")
            GuideDefRow(name: "No Rate Limit Bypass", description: "All operations subject to rate limiting based on scope risk level", icon: "xmark.circle")
            GuideDefRow(name: "No Cross-Scope Leakage", description: "Data from one scope must not leak to another without explicit permission", icon: "xmark.circle")
        }
        Section(header: Text("Security Boundaries")) {
            GuideDefRow(name: "Kernel Access", description: "Only WorkspaceSDK.shared.initialize() may trigger kernel boot", icon: "lock")
            GuideDefRow(name: "Plugin Sandbox", description: "Sandboxed plugins re-verified at every start, cannot escalate", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "API Key Validation", description: "Project-scoped API keys validated on every governed call", icon: "key")
            GuideDefRow(name: "Privacy Redaction", description: "Sensitive fields automatically stripped before data return", icon: "eye.slash")
        }
        Section(header: Text("Error Types")) {
            GuideDefRow(name: "validationError(reason:)", description: "Input validation failure — bad parameters, duplicate entries", icon: "exclamationmark.triangle")
            GuideDefRow(name: "executionFailed(reason:)", description: "Runtime execution failure — rate limits, missing handlers", icon: "xmark.octagon")
            GuideDefRow(name: "permissionDenied(scope:)", description: "Authorization failure — insufficient permissions for scope", icon: "lock.slash")
        }
    }
}

// MARK: - Best Practices

private struct BestPracticesSection: View {
    var body: some View {
        Section(header: Text("Architecture")) {
            GuideDefRow(name: "Mobile-First", description: "All interactions must be gesture-driven, contextual, and use NavigationStack/sheets/overlays", icon: "iphone")
            GuideDefRow(name: "Reactive State", description: "Use @Published properties and Combine for all state management", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Offline-First", description: "Design all data operations to work without network connectivity", icon: "wifi.slash")
        }
        Section(header: Text("Module Design")) {
            GuideDefRow(name: "Single Responsibility", description: "Each module should own one well-defined capability domain", icon: "1.circle")
            GuideDefRow(name: "Explicit Dependencies", description: "Always declare module dependencies in the descriptor", icon: "list.bullet")
            GuideDefRow(name: "Feature Exposure", description: "Expose features with typed parameter schemas for runtime discovery", icon: "rectangle.and.text.magnifyingglass")
            GuideDefRow(name: "Versioning", description: "Use semantic versioning and set minimumSDKVersion correctly", icon: "number")
        }
        Section(header: Text("Plugin Development")) {
            GuideDefRow(name: "Lifecycle Awareness", description: "Handle all lifecycle phases (loading, active, paused, updating, migrating)", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Sandboxed Execution", description: "Plugins run in isolated contexts with scoped permissions", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "Manifest-Driven", description: "Declare all capabilities, permissions, and hooks in the plugin manifest", icon: "doc.text")
            GuideDefRow(name: "Error Recovery", description: "Implement graceful degradation for errored phase transitions", icon: "arrow.uturn.backward")
        }
        Section(header: Text("Connector Integration")) {
            GuideDefRow(name: "Auth Abstraction", description: "Use ConnectorAuthMethod enum for consistent authentication patterns", icon: "lock")
            GuideDefRow(name: "Error Handling", description: "Implement robust retry logic and health monitoring", icon: "exclamationmark.triangle")
            GuideDefRow(name: "Runtime Binding", description: "Bind connectors to modules for declarative data flow", icon: "link")
            GuideDefRow(name: "Concurrent Sync", description: "Use TaskGroup for parallel connector synchronization", icon: "arrow.triangle.merge")
        }
    }
}

// MARK: - Definitions Reference (50+ Structured Definitions)

private struct DefinitionsReferenceSection: View {
    var body: some View {
        Section(header: Text("Kernel & Lifecycle Definitions")) {
            StructDef(name: "WorkspaceSDKKernel", fields: [
                ("state", "KernelState", "Current kernel lifecycle state"),
                ("bootTime", "Date?", "Timestamp of last successful boot"),
                ("uptimeSeconds", "TimeInterval", "Seconds since last boot"),
            ], notes: "Singleton via .shared. @MainActor. Boot from idle/error only.")
            StructDef(name: "KernelState", fields: [
                ("idle", "case", "Not started or fully shut down"),
                ("booting", "case", "Boot sequence in progress"),
                ("ready", "case", "Fully operational"),
                ("error", "case", "Boot failed, can retry"),
                ("shuttingDown", "case", "Graceful shutdown in progress"),
            ], notes: "Codable enum. CaseIterable.")
            StructDef(name: "KernelHealth", fields: [
                ("state", "KernelState", "Current kernel state"),
                ("uptime", "TimeInterval", "Seconds since boot"),
                ("registeredServices", "Int", "Count of DI-registered services"),
                ("loadedPlugins", "Int", "Count of loaded app definitions"),
                ("dataStoreHealthy", "Bool", "Data store initialization status"),
                ("eventBusHealthy", "Bool", "Event bus running status"),
            ], notes: "isHealthy = state == .ready && dataStore && eventBus healthy")
        }

        Section(header: Text("Environment & Configuration Definitions")) {
            StructDef(name: "SDKConfiguration", fields: [
                ("sdkVersion", "String", "Semantic version of SDK (e.g., 2.0.0)"),
                ("buildNumber", "Int", "Incremental build number"),
                ("environment", "Environment", "development | staging | production"),
                ("logLevel", "LogLevel", "debug | info | warning | error"),
                ("maxCacheSizeMB", "Int", "Maximum cache size in megabytes"),
                ("eventHistoryLimit", "Int", "Max events retained in bus history"),
                ("pluginSandboxEnabled", "Bool", "Whether plugin sandbox is enforced"),
                ("offlineMode", "Bool", "Force offline-only operation"),
                ("dataEncryptionEnabled", "Bool", "Enable data-at-rest encryption"),
                ("analyticsEnabled", "Bool", "Enable anonymous usage analytics"),
            ], notes: "Persisted to UserDefaults. Codable.")
        }

        Section(header: Text("Context & Scope Definitions")) {
            StructDef(name: "SDKContext", fields: [
                ("id", "UUID", "Unique context identifier"),
                ("scope", "ContextScope", "global | workspace | feature | plugin | request"),
                ("metadata", "[String: String]", "Key-value request-scoped data"),
                ("permissions", "Set<String>", "Permission tokens, '*' = wildcard"),
                ("parentContext", "SDKContext?", "Parent for permission inheritance"),
            ], notes: "hasPermission() traverses parent chain. Wildcard grants all.")
            StructDef(name: "SDKScope", fields: [
                ("all", "case", "Access all workspace data"),
                ("tasks", "case", "Task management data"),
                ("notes", "case", "Note and document data"),
                ("calendar", "case", "Calendar event data"),
                ("files", "case", "File system data"),
                ("emails", "case", "Email message data"),
                ("plugins", "case", "Plugin configuration data"),
                ("custom(query:)", "case", "User-defined query scope"),
            ], notes: "16 total cases including whiteboards, slides, media, meet, repos, automations, intelligence, persona")
        }

        Section(header: Text("Module System Definitions")) {
            StructDef(name: "SDKModuleDescriptor", fields: [
                ("id", "UUID", "Auto-generated unique identifier"),
                ("identifier", "String", "Reverse-domain unique string"),
                ("displayName", "String", "Human-readable name"),
                ("version", "String", "Semantic version string"),
                ("minimumSDKVersion", "String", "Minimum SDK version required"),
                ("capabilities", "[SDKModuleCapability]", "Declared capability set"),
                ("dependencies", "[String]", "Required module identifiers"),
                ("exportedServices", "[String]", "DI service keys provided"),
                ("isEnabled", "Bool", "Active state"),
                ("loadPriority", "Int", "Load order (lower = earlier)"),
            ], notes: "Codable, Hashable, Identifiable. Sorted by loadPriority in registry.")
            StructDef(name: "SDKModuleCapability", fields: [
                ("dataAccess", "case", "Read/write workspace data"),
                ("networking", "case", "Network request capability"),
                ("storage", "case", "Persistent storage access"),
                ("rendering", "case", "UI rendering capability"),
                ("automation", "case", "Automation rule execution"),
                ("authentication", "case", "Auth provider (exclusive)"),
                ("analytics", "case", "Analytics data collection"),
                ("messaging", "case", "Inter-module messaging"),
                ("fileSystem", "case", "File system access"),
                ("aiProcessing", "case", "AI/ML processing capability"),
                ("connectorBinding", "case", "Connector binding (exclusive)"),
                ("pluginHosting", "case", "Plugin host capability"),
                ("eventPublishing", "case", "Event bus publishing"),
                ("backgroundExecution", "case", "Background task execution"),
            ], notes: "authentication and connectorBinding are exclusive — only one module may claim each.")
            StructDef(name: "SDKExposedFeature", fields: [
                ("moduleIdentifier", "String", "Owning module identifier"),
                ("featureName", "String", "Feature name for discovery"),
                ("inputSchema", "[SDKFeatureParameter]", "Typed input parameters"),
                ("outputType", "String", "Return type description"),
                ("isAsync", "Bool", "Whether invocation is async"),
                ("requiredCapabilities", "[SDKModuleCapability]", "Capabilities needed"),
            ], notes: "Exposed via SDKFeatureExposureManager. Invokable by ID.")
            StructDef(name: "SDKDependencyResolution", fields: [
                ("orderedModules", "[SDKModuleDescriptor]", "Topologically sorted load order"),
                ("conflicts", "[DependencyConflict]", "All detected conflicts"),
                ("warnings", "[String]", "Non-fatal issues"),
                ("isClean", "Bool", "True when zero conflicts"),
            ], notes: "Generated by SDKDependencyGraph.resolve()")
            StructDef(name: "DependencyConflict", fields: [
                ("moduleA", "String", "First module in conflict"),
                ("moduleB", "String", "Second module in conflict"),
                ("conflictType", "ConflictType", "versionMismatch | circularDependency | capabilityCollision | missingDependency"),
                ("description", "String", "Human-readable conflict description"),
            ], notes: "Identifiable with auto-generated UUID")
        }

        Section(header: Text("Plugin System Definitions")) {
            StructDef(name: "SDKPlugin", fields: [
                ("id", "UUID", "Plugin identifier"),
                ("name", "String", "Plugin display name"),
                ("version", "String", "Plugin version"),
                ("permissions", "[PluginPermission]", "readData | writeData | network | notifications | fileAccess"),
                ("isEnabled", "Bool", "Whether plugin is active"),
                ("tools", "[UUID]", "Associated tool IDs"),
                ("automationHooks", "[String]", "Event hooks this plugin responds to"),
            ], notes: "Managed by SDKPluginManager. Persisted to UserDefaults.")
            StructDef(name: "SDKPluginManifest", fields: [
                ("identifier", "String", "Reverse-domain unique identifier"),
                ("displayName", "String", "Human-readable name"),
                ("version", "String", "Semantic version"),
                ("author", "String", "Plugin author"),
                ("capabilities", "[SDKPluginCapability]", "Declared capability set"),
                ("dependencies", "[String]", "Required plugin identifiers"),
                ("permissions", "[PluginPermission]", "Required permission set"),
                ("hooks", "[String]", "Automation hook names"),
                ("category", "PluginCategory", "productivity | communication | development | analytics | automation | integration | utility | ai"),
            ], notes: "Full lifecycle via SDKPluginLifecycleManager.")
            StructDef(name: "SDKPluginPhase", fields: [
                ("unloaded", "case", "Installed but not loaded"),
                ("loading", "case", "Being loaded, deps resolving"),
                ("active", "case", "Fully operational"),
                ("paused", "case", "Temporarily suspended"),
                ("updating", "case", "Being updated"),
                ("migrating", "case", "Data migration in progress"),
                ("errored", "case", "Unrecoverable error"),
                ("disabled", "case", "Explicitly disabled"),
            ], notes: "Transitions validated by isTransitionValid(from:to:)")
            StructDef(name: "SDKAppDefinition", fields: [
                ("name", "String", "App display name"),
                ("version", "String", "Semantic version"),
                ("permissions", "[String]", "Required scope strings"),
                ("isSandboxed", "Bool", "Whether sandbox enforcement applies"),
                ("isEnabled", "Bool", "Current running state"),
                ("scopes", "[SDKScope]", "Accessible data scopes"),
            ], notes: "Managed by PluginRuntimeEngine. SDKModel conformant.")
        }

        Section(header: Text("Connector System Definitions")) {
            StructDef(name: "ConnectorType", fields: [
                ("gmail", "case", "Gmail email integration"),
                ("webhook", "case", "Generic HTTP webhook"),
                ("github", "case", "GitHub repository integration"),
                ("localFileSystem", "case", "Local file I/O"),
                ("calendar", "case", "Calendar event sync"),
            ], notes: "CaseIterable, Codable")
            StructDef(name: "ConnectorBinding", fields: [
                ("connectorID", "UUID", "Bound connector identifier"),
                ("moduleIdentifier", "String", "Bound module identifier"),
                ("bindingType", "BindingType", "dataSource | dataSink | eventTrigger | authProvider | configSource"),
                ("configuration", "[String: String]", "Binding-specific configuration"),
                ("isActive", "Bool", "Whether binding is active"),
            ], notes: "Managed by SDKConnectorRuntimeBinder")
            StructDef(name: "ConnectorAuthMethod", fields: [
                ("none", "case", "No authentication required"),
                ("apiKey", "case", "API key in header/query"),
                ("oauth2", "case", "OAuth 2.0 flow"),
                ("bearer", "case", "Bearer token auth"),
                ("basic", "case", "HTTP Basic auth"),
                ("certificate", "case", "Client certificate auth"),
                ("webhook", "case", "Webhook-specific auth"),
            ], notes: "CaseIterable, Codable")
            StructDef(name: "ConnectorTemplate", fields: [
                ("name", "String", "Template display name"),
                ("type", "ConnectorType", "Connector type"),
                ("authMethod", "ConnectorAuthMethod", "Default auth method"),
                ("defaultEndpoints", "[ConnectorEndpointTemplate]", "Pre-configured endpoints"),
                ("requiredFields", "[AuthField]", "Auth credential fields"),
            ], notes: "6 built-in templates: REST, GraphQL, WebSocket, Firebase, Slack, MQTT")
        }

        Section(header: Text("Security Definitions")) {
            StructDef(name: "SDKSecurityScopeDefinition", fields: [
                ("name", "String", "Scope identifier"),
                ("description", "String", "Human-readable description"),
                ("riskLevel", "RiskLevel", "low | medium | high | critical"),
                ("requiresJustification", "Bool", "Must provide reason for access"),
                ("runtimeValidationHook", "String?", "Optional validation callback"),
            ], notes: "Registered in SDKPolicyEngine. Drives rate limiting rules.")
            StructDef(name: "SDKPolicyRequest", fields: [
                ("operationName", "String", "Name of the operation being performed"),
                ("scope", "String", "Scope being accessed"),
                ("projectID", "UUID?", "Associated project"),
                ("appID", "UUID?", "Requesting app identifier"),
                ("apiKey", "String?", "API key for validation"),
                ("allowedScopes", "Set<String>", "Scopes the caller is allowed"),
                ("justification", "String?", "Reason for high-risk access"),
            ], notes: "Evaluated by SDKPolicyEngine.evaluate()")
            StructDef(name: "SDKRateLimiter.Rule", fields: [
                ("requestsPerMinute", "Int", "Max requests per 60-second window"),
                ("dataFetchLimit", "Int", "Max data fetch units per window"),
                ("executionFrequencyCap", "Int", "Max executions per window"),
            ], notes: "Enforced via token bucket algorithm with per-second refill")
        }

        Section(header: Text("Event System Definitions")) {
            StructDef(name: "SDKBusEvent", fields: [
                ("id", "UUID", "Unique event identifier"),
                ("channel", "String", "Event channel (e.g., sdk.lifecycle)"),
                ("name", "String", "Event name (e.g., kernel.ready)"),
                ("data", "[String: String]", "Event payload key-value pairs"),
                ("source", "String", "Event source identifier"),
                ("timestamp", "Date", "Event creation timestamp"),
            ], notes: "Codable, Identifiable. Published via SDKEventBus.publish()")
        }

        Section(header: Text("Data Model Definitions")) {
            StructDef(name: "SDKDataItem", fields: [
                ("id", "UUID", "Item identifier"),
                ("scope", "SDKScope", "Data scope category"),
                ("title", "String", "Item title"),
                ("codablePayload", "[String: String]", "Serializable payload"),
                ("timestamp", "Date", "Creation timestamp"),
            ], notes: "Used by ToolsKitSDK for governed data access")
            StructDef(name: "SDKQuery", fields: [
                ("scope", "SDKScope", "Query scope filter"),
                ("filters", "[SDKFilter]", "Array of filter conditions"),
                ("pagination", "SDKPagination?", "Optional page/pageSize"),
                ("streaming", "Bool", "Enable streaming results"),
                ("partialDataset", "Bool", "Allow partial results"),
            ], notes: "Used with fetchData(query:) for advanced queries")
        }

        Section(header: Text("Automation Definitions")) {
            StructDef(name: "SDKAutomationRule", fields: [
                ("name", "String", "Rule display name"),
                ("trigger", "AutomationTrigger", "dataUpdated | connectorEvent | timeBased"),
                ("condition", "AutomationCondition?", "Optional guard condition"),
                ("action", "AutomationAction", "runTool | syncConnector | sendNotification | exportData"),
                ("isEnabled", "Bool", "Whether rule is active"),
                ("lastRunAt", "Date?", "Last execution timestamp"),
                ("runCount", "Int", "Total execution count"),
            ], notes: "Persisted via SDKProjectManager. Evaluated by SDKAutomationEngine.")
        }

        Section(header: Text("Router Definitions")) {
            StructDef(name: "SDKRequest", fields: [
                ("id", "UUID", "Request identifier"),
                ("path", "String", "Route path (e.g., /sdk/health)"),
                ("method", "Method", "get | post | put | delete | patch"),
                ("parameters", "[String: String]", "Request parameters"),
            ], notes: "Handled by SDKRouter registered handlers")
            StructDef(name: "SDKResponse", fields: [
                ("requestId", "UUID", "Originating request ID"),
                ("status", "Status", "success | error | notFound | unauthorized"),
                ("data", "[String: String]", "Response payload"),
                ("error", "String?", "Error message if failed"),
                ("latency", "TimeInterval", "Request processing time"),
            ], notes: "Returned by all router handlers")
        }
    }
}

// MARK: - Feature Modules

private struct FeatureModulesSection: View {
    var body: some View {
        Section(header: Text("Mail Service")) {
            Text("SDKMailService provides a full email management system with sending, receiving, folder organization, and draft management.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "sendEmail(to:subject:body:)", description: "Compose and send emails with HTML body support", icon: "envelope")
            GuideDefRow(name: "fetchInbox()", description: "Retrieve all inbox emails with pagination support", icon: "tray")
            GuideDefRow(name: "moveTo(folder:)", description: "Move emails between folders (inbox, archive, trash)", icon: "folder")
            GuideDefRow(name: "createDraft()", description: "Save email drafts for later editing and sending", icon: "square.and.pencil")
        }
        Section(header: Text("Mail Code Example")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let mail = WorkspaceSDK.shared.mail
                let email = SDKEmail(
                    to: "user@example.com",
                    subject: "Hello",
                    body: "<h1>Welcome</h1>",
                    isHTML: true
                )
                await mail.send(email)
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Notebooks Service")) {
            Text("SDKNotebookService handles rich notebook documents with sections, blocks, and collaborative editing support.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "createNotebook(title:)", description: "Create a new notebook with a title", icon: "book")
            GuideDefRow(name: "addSection(to:)", description: "Add sections to organize notebook content", icon: "rectangle.split.3x1")
            GuideDefRow(name: "addBlock(type:content:)", description: "Add text, code, image, or checklist blocks", icon: "plus.rectangle")
            GuideDefRow(name: "exportAsPDF()", description: "Export notebook as formatted PDF document", icon: "doc.richtext")
        }
        Section(header: Text("Meet Service")) {
            Text("SDKMeetService manages video and audio meeting sessions with participant tracking and scheduling.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "createMeeting(title:date:)", description: "Schedule a new meeting with title and time", icon: "video")
            GuideDefRow(name: "joinMeeting(id:)", description: "Join an existing meeting session by ID", icon: "person.2")
            GuideDefRow(name: "addParticipant(user:)", description: "Invite participants to a meeting", icon: "person.badge.plus")
            GuideDefRow(name: "recordSession()", description: "Start recording the active meeting session", icon: "record.circle")
            GuideDefRow(name: "endMeeting()", description: "End the active meeting and clean up resources", icon: "phone.down")
        }
        Section(header: Text("Articles Service")) {
            Text("SDKArticlesService provides content publishing with drafts, categories, and rich media support.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "createArticle(title:body:)", description: "Create a new article with rich text content", icon: "doc.text")
            GuideDefRow(name: "publish(article:)", description: "Publish a draft article to make it public", icon: "arrow.up.circle")
            GuideDefRow(name: "setCategory(_:for:)", description: "Assign categories and tags to articles", icon: "tag")
            GuideDefRow(name: "addMedia(image:to:)", description: "Attach images and media to article content", icon: "photo.on.rectangle")
        }
    }
}

// MARK: - Caching

private struct CachingSection: View {
    var body: some View {
        Section(header: Text("Cache Architecture")) {
            Text("SDKCacheManager provides a multi-tier caching system with memory and disk storage, automatic eviction policies, and TTL-based expiration.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "MemoryCache", description: "Fast in-memory NSCache-backed storage with size limits", icon: "memorychip")
            GuideDefRow(name: "DiskCache", description: "Persistent file-based cache with automatic cleanup", icon: "internaldrive")
            GuideDefRow(name: "CachePolicy", description: "LRU, LFU, FIFO, and TTL eviction strategies", icon: "arrow.counterclockwise")
        }
        Section(header: Text("Cache API")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let cache = SDKCacheManager.shared

                // Store with TTL
                cache.set("key", value: data, ttl: 3600)

                // Retrieve
                if let cached: Data = cache.get("key") {
                    // Use cached data
                }

                // Invalidate
                cache.remove("key")
                cache.clearAll()

                // Statistics
                let stats = cache.statistics
                print("Hit rate: \\(stats.hitRate)%")
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Cancellation Manager")) {
            Text("SDKCancellationManager tracks and manages cancellable async operations, preventing resource leaks.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "track(operation:)", description: "Register a cancellable operation for lifecycle tracking", icon: "xmark.circle")
            GuideDefRow(name: "cancelAll()", description: "Cancel all tracked operations at once", icon: "xmark.octagon")
            GuideDefRow(name: "cancelGroup(_:)", description: "Cancel operations by group identifier", icon: "folder.badge.minus")
        }
    }
}

// MARK: - Migration

private struct MigrationSection: View {
    var body: some View {
        Section(header: Text("Migration System")) {
            Text("SDKMigrationManager handles data schema migrations when the SDK version changes, ensuring backward compatibility and data integrity.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "checkPendingMigrations()", description: "Scan for schema changes requiring migration", icon: "magnifyingglass")
            GuideDefRow(name: "migrate(from:to:)", description: "Run migrations between specific versions", icon: "arrow.right")
            GuideDefRow(name: "rollback(to:)", description: "Revert to a previous schema version", icon: "arrow.uturn.left")
        }
        Section(header: Text("Version Management")) {
            Text("SDKVersionManager tracks SDK versions, build numbers, and compatibility matrices.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "currentVersion", description: "The currently running SDK version string", icon: "number")
            GuideDefRow(name: "buildNumber", description: "Incremental build number for tracking releases", icon: "hammer")
            GuideDefRow(name: "isCompatible(with:)", description: "Check if a plugin/module is compatible with current SDK", icon: "checkmark.circle")
            GuideDefRow(name: "changelog", description: "Access the version changelog and release notes", icon: "doc.text")
        }
        Section(header: Text("Migration Code Example")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let migrator = SDKMigrationManager.shared

                // Check and run pending migrations
                if migrator.hasPendingMigrations {
                    try await migrator.runAll()
                }

                // Register custom migration
                migrator.register(
                    from: "1.0",
                    to: "2.0"
                ) { store in
                    // Transform data as needed
                    store.renameField("old", to: "new")
                }
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Localization

private struct LocalizationSection: View {
    var body: some View {
        Section(header: Text("Localization System")) {
            Text("SDKLocalizationManager provides internationalization support with dynamic locale switching, string catalogs, and pluralization rules.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "currentLocale", description: "The active locale used for formatting and translations", icon: "globe")
            GuideDefRow(name: "setLocale(_:)", description: "Switch the active locale at runtime", icon: "arrow.left.arrow.right")
            GuideDefRow(name: "supportedLocales", description: "List of all available locale identifiers", icon: "list.bullet")
        }
        Section(header: Text("String Resolution")) {
            GuideDefRow(name: "localized(_:)", description: "Look up a localized string by key", icon: "text.magnifyingglass")
            GuideDefRow(name: "localized(_:args:)", description: "Look up with format arguments for interpolation", icon: "textformat.abc.dottedunderline")
            GuideDefRow(name: "pluralized(_:count:)", description: "Handle pluralization rules per locale", icon: "textformat.123")
        }
        Section(header: Text("Localization Code Example")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let l10n = SDKLocalizationManager.shared

                // Get localized string
                let title = l10n.localized("welcome_title")

                // With arguments
                let greeting = l10n.localized(
                    "hello_user",
                    args: userName
                )

                // Pluralization
                let items = l10n.pluralized(
                    "item_count",
                    count: 5
                ) // "5 items"

                // Switch locale
                l10n.setLocale("fr_FR")
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Feature Flags

private struct FeatureFlagsSection: View {
    var body: some View {
        Section(header: Text("Feature Flag Service")) {
            Text("SDKFeatureFlagService manages feature toggles with support for progressive rollouts, A/B testing, and environment-based configuration.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "isEnabled(_:)", description: "Check if a feature flag is currently enabled", icon: "flag")
            GuideDefRow(name: "setFlag(_:enabled:)", description: "Enable or disable a feature flag at runtime", icon: "flag.fill")
            GuideDefRow(name: "registerFlag(_:default:)", description: "Register a new flag with a default value", icon: "flag.badge.ellipsis")
            GuideDefRow(name: "allFlags", description: "Dictionary of all registered flags and their states", icon: "list.clipboard")
        }
        Section(header: Text("Flag Types")) {
            GuideDefRow(name: "Boolean Flag", description: "Simple on/off toggle for features", icon: "switch.2")
            GuideDefRow(name: "Percentage Flag", description: "Enable for a percentage of users (rollout)", icon: "percent")
            GuideDefRow(name: "Variant Flag", description: "A/B testing with multiple variants", icon: "rectangle.split.2x1")
            GuideDefRow(name: "Environment Flag", description: "Different values per environment (dev/staging/prod)", icon: "globe.americas")
        }
        Section(header: Text("Feature Flag Code Example")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let flags = SDKFeatureFlagService.shared

                // Check flag
                if flags.isEnabled("new_editor") {
                    showNewEditor()
                }

                // Register with default
                flags.registerFlag(
                    "dark_mode",
                    default: true
                )

                // Toggle at runtime
                flags.setFlag("beta_features",
                    enabled: true)
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - Realtime Sync

private struct RealtimeSyncSection: View {
    var body: some View {
        Section(header: Text("Sync Engine")) {
            Text("SDKRealtimeSync enables real-time data synchronization across devices with conflict resolution and offline support.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "startSync()", description: "Begin real-time synchronization for all collections", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "pauseSync()", description: "Temporarily pause synchronization", icon: "pause.circle")
            GuideDefRow(name: "syncStatus", description: "Current sync state (syncing, synced, error, offline)", icon: "wifi")
        }
        Section(header: Text("Conflict Resolution")) {
            Text("SDKConflictResolver handles data conflicts when multiple devices modify the same record.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "lastWriteWins", description: "Latest timestamp overwrites earlier changes", icon: "clock.arrow.circlepath")
            GuideDefRow(name: "mergeFields", description: "Merge non-conflicting fields from both versions", icon: "arrow.triangle.merge")
            GuideDefRow(name: "manual", description: "Flag conflict for user resolution", icon: "hand.raised")
        }
        Section(header: Text("Sync Code Example")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let sync = SDKRealtimeSync.shared

                // Start syncing
                await sync.startSync()

                // Monitor status
                sync.onStatusChange { status in
                    switch status {
                    case .synced: print("Up to date")
                    case .syncing: print("Syncing...")
                    case .offline: print("Working offline")
                    case .error(let e): print(e)
                    }
                }

                // Configure conflict resolution
                let resolver = SDKConflictResolver.shared
                resolver.strategy = .mergeFields
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

// MARK: - AI Integration

private struct AIIntegrationSection: View {
    var body: some View {
        Section(header: Text("AI Slides System")) {
            Text("The AI Slides system in Sources/Core/SDK/AI/Slides provides AI-powered presentation generation with multiple image providers and customizable themes.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "AISlidesGenerator", description: "Core engine that generates slide decks from text prompts", icon: "wand.and.stars")
            GuideDefRow(name: "SlideModel", description: "Data model for individual slides (title, body, images, layout)", icon: "rectangle.on.rectangle")
            GuideDefRow(name: "SlideTheme", description: "Visual theme configuration (colors, fonts, spacing)", icon: "paintpalette")
        }
        Section(header: Text("Image Providers")) {
            Text("Pluggable image provider architecture in AISlidesImageProviders allows different sources for slide visuals.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "UnsplashProvider", description: "Fetch high-quality photos from Unsplash API", icon: "photo")
            GuideDefRow(name: "SFSymbolProvider", description: "Use system SF Symbols as slide graphics", icon: "star.square")
            GuideDefRow(name: "AIGeneratedProvider", description: "Generate custom images using AI models", icon: "brain")
            GuideDefRow(name: "LocalAssetProvider", description: "Use locally bundled image assets", icon: "folder.fill")
        }
        Section(header: Text("AI Slides Code Example")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let generator = AISlidesGenerator()

                // Generate from prompt
                let slides = try await generator.generate(
                    prompt: "Quarterly business review",
                    slideCount: 10,
                    theme: .corporate,
                    imageProvider: .unsplash
                )

                // Customize individual slides
                slides[0].layout = .titleOnly
                slides[1].layout = .twoColumn
                slides[2].addImage(from: .sfSymbol("chart.bar"))

                // Export
                let pdfData = slides.exportAsPDF()
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Slides Extensions")) {
            GuideDefRow(name: "MarkdownParser", description: "Parse markdown content into slide blocks", icon: "text.badge.checkmark")
            GuideDefRow(name: "AnimationEngine", description: "Add transitions and animations between slides", icon: "wind")
            GuideDefRow(name: "PresenterMode", description: "Full-screen presentation with speaker notes", icon: "play.rectangle")
            GuideDefRow(name: "CollaborativeEditing", description: "Multiple users editing slides simultaneously", icon: "person.2.fill")
        }
    }
}

// MARK: - Tool System

private struct ToolSystemSection: View {
    var body: some View {
        Section(header: Text("Tool Architecture")) {
            Text("The SDK Tool system provides a plugin-based architecture for developer tools. Each tool conforms to the DevTool protocol and is registered through SDKToolManager.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "DevTool Protocol", description: "Base protocol requiring id, name, category, icon, description, render()", icon: "wrench")
            GuideDefRow(name: "SDKToolManager", description: "Central registry for discovering and launching tools", icon: "tray.2")
            GuideDefRow(name: "SDKToolRuntime", description: "Execution environment for tools with state management", icon: "play.rectangle")
            GuideDefRow(name: "DevToolCategory", description: "Categorization system: data, encoding, security, utilities, etc.", icon: "square.grid.3x3")
        }
        Section(header: Text("Creating a Custom Tool")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                struct MyCustomTool: DevTool {
                    let id = "my-custom-tool"
                    let name = "My Tool"
                    let category = DevToolCategory.utilities
                    let icon = "star"
                    let description = "My custom tool"

                    func render() -> some View {
                        MyCustomToolView()
                    }
                }

                // Register with the SDK
                SDKToolManager.shared.register(MyCustomTool())
                """)
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
        Section(header: Text("Built-in Tool Categories")) {
            GuideDefRow(name: "Data Tools", description: "JSON Formatter, CSV Parser, Date Formatter, Number Formatter, UUID Generator", icon: "cylinder.split.1x2")
            GuideDefRow(name: "Encoding Tools", description: "Base64 Encoder/Decoder, URL Encoder/Decoder, HTML Entity tools", icon: "lock.rectangle")
            GuideDefRow(name: "Security Tools", description: "Hash Generator, JWT Decoder, Encryption Tool, Password Generator", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "Utility Tools", description: "Text Case Converter, Lorem Ipsum Generator, Markdown Preview, Regex Tester", icon: "ellipsis.rectangle")
            GuideDefRow(name: "Networking Tools", description: "HTTP Request Tester, Timezone Converter, IP Address Info", icon: "network")
            GuideDefRow(name: "Visual Tools", description: "Color Converter, Image Converter, QR Code Generator, Text Diff", icon: "paintbrush")
        }
        Section(header: Text("Tool Lifecycle")) {
            GuideDefRow(name: "Registration", description: "Tool registers via SDKToolManager.register() at SDK boot", icon: "1.circle")
            GuideDefRow(name: "Discovery", description: "Users browse tools by category or search by name", icon: "2.circle")
            GuideDefRow(name: "Rendering", description: "Tool's render() returns SwiftUI view displayed in workspace", icon: "3.circle")
            GuideDefRow(name: "State", description: "Each tool manages its own @StateObject view model", icon: "4.circle")
            GuideDefRow(name: "Cleanup", description: "Tool views are deallocated when navigating away", icon: "5.circle")
        }
    }
}

// MARK: - Reusable Components

private struct GuideDefRow: View {
    let name: String
    let description: String
    let icon: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text(description).font(.caption2).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon).foregroundStyle(Color.accentColor)
        }
    }
}

private struct StructDef: View {
    let name: String
    let fields: [(String, String, String)]
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(Color.accentColor)
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                HStack(alignment: .top, spacing: 4) {
                    Text(field.0)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 60, alignment: .leading)
                    Text(field.1)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 50, alignment: .leading)
                    Text(field.2)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            if !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
