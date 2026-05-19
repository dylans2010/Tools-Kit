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
        case analyticsEngine = "Analytics & Metrics"
        case healthMonitoring = "Health & Diagnostics"
        case workflowEngine = "Workflow Engine"
        case projectManagement = "Project & Config"
        case librarySystem = "Library & Versioning"
        case localizationAccessibility = "Localize & Access"
        case swiftUIIntegration = "SwiftUI Integration"
        case packaging = "Packaging & Export"
        case deployment = "Deployment"
        case constraints = "Constraints & Rules"
        case bestPractices = "Best Practices"
        case advancedServices = "Advanced Services"
        case definitionsReference = "Definitions Reference"

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
            case .analyticsEngine: return "chart.bar.xaxis"
            case .healthMonitoring: return "heart.text.square"
            case .workflowEngine: return "point.topleft.down.curvedto.point.bottomright.up"
            case .projectManagement: return "folder.badge.gearshape"
            case .librarySystem: return "books.vertical"
            case .localizationAccessibility: return "text.bubble"
            case .swiftUIIntegration: return "swift"
            case .packaging: return "shippingbox"
            case .deployment: return "cloud.arrow.up"
            case .constraints: return "exclamationmark.shield"
            case .bestPractices: return "star"
            case .advancedServices: return "wand.and.rays"
            case .definitionsReference: return "doc.text.magnifyingglass"
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
            case .analyticsEngine: AnalyticsSection()
            case .healthMonitoring: HealthSection()
            case .workflowEngine: WorkflowSection()
            case .projectManagement: ProjectManagementSection()
            case .librarySystem: LibrarySystemSection()
            case .localizationAccessibility: LocalizationAccessibilitySection()
            case .swiftUIIntegration: SwiftUIIntegrationSection()
            case .packaging: PackagingSection()
            case .deployment: DeploymentSection()
            case .constraints: ConstraintsSection()
            case .bestPractices: BestPracticesSection()
            case .advancedServices: AdvancedServicesSection()
            case .definitionsReference: DefinitionsReferenceSection()
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
        Section("SDK Platform Architecture") {
            tocRow(.introduction, "Platform overview, key technologies, and system layers")
            tocRow(.kernelLifecycle, "Boot sequence, shutdown, state machine, health checks")
        }
        Section("Core Systems") {
            tocRow(.moduleSystem, "Module registration, activation, capabilities, feature exposure")
            tocRow(.pluginArchitecture, "Plugin lifecycle, manifests, sandboxing, app runtime")
            tocRow(.connectorSystem, "External service bridges, auth methods, runtime binding")
            tocRow(.dependencyManagement, "Dependency graph, topological sort, conflict resolution")
        }
        Section("Runtime & Data") {
            tocRow(.runtimeExecution, "Execution pipeline, contexts, scopes, governed operations")
            tocRow(.dataLayer, "SDKModel, offline-first persistence, indexing, batch ops")
            tocRow(.eventSystem, "Event bus, channels, subscriptions, history, bridging")
        }
        Section("Infrastructure") {
            tocRow(.security, "Permissions, policies, rate limiting, audit, sandboxing")
            tocRow(.diContainer, "ServiceContainer, ServiceRegistry, protocol-based resolution")
            tocRow(.routerAPI, "Internal API routing, endpoint registration, default routes")
            tocRow(.automationEngine, "Trigger/condition/action rules, automation execution")
            tocRow(.analyticsEngine, "Telemetry, event tracking, metrics collection")
            tocRow(.healthMonitoring, "Service status, heartbeat, resource watching")
            tocRow(.workflowEngine, "Stateful process orchestration and task chaining")
            tocRow(.projectManagement, "SDKProject, configuration overrides, and state persistence")
            tocRow(.librarySystem, "Version resolving, scope binding, and dependency bridges")
            tocRow(.localizationAccessibility, "Multi-language support and system accessibility")
        }
        Section("UI & Integration") {
            tocRow(.swiftUIIntegration, "Observable patterns, singleton access, view architecture")
            tocRow(.packaging, "SDK export, bundle structure, import validation")
            tocRow(.deployment, "Versioning, build configuration, integration tests")
        }
        Section("Reference") {
            tocRow(.constraints, "System constraints, prohibited interactions, security boundaries")
            tocRow(.bestPractices, "Architecture, module design, plugin dev, connector integration")
            tocRow(.advancedServices, "Real-time sync, feature flags, and background execution")
            tocRow(.definitionsReference, "70+ structured type definitions for all SDK systems")
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
        Section("Platform Overview") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workspace SDK Platform").font(.headline)
                Text("ToolsKit provides a comprehensive, production-grade SDK for building and extending the Workspace OS. The platform is built on a modular kernel that manages data, security, and execution environments. All code is native Swift/SwiftUI targeting iOS, macOS, watchOS, and tvOS.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }.padding(.vertical, 4)
        }
        Section("Key Technologies") {
            GuideDefRow(name: "Swift & SwiftUI", description: "Primary language and UI framework for all SDK components", icon: "swift")
            GuideDefRow(name: "Combine", description: "Reactive framework powering event streams and state propagation", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Foundation", description: "Core data types, networking, file I/O, and concurrency", icon: "cube.box")
            GuideDefRow(name: "UserDefaults", description: "Lightweight key-value persistence for configuration and feature flags", icon: "gearshape")
            GuideDefRow(name: "FileManager", description: "File-based JSON storage for data store and event history", icon: "folder")
        }
        Section("System Layers") {
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
        Section("Public API Facade") {
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
        Section("Kernel State Machine") {
            Text("WorkspaceSDKKernel manages the entire SDK lifecycle through a strict state machine. Boot is only permitted from idle or error states.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "idle", description: "SDK not started. Initial state and post-shutdown state.", icon: "stop.circle")
            GuideDefRow(name: "booting", description: "Boot sequence in progress. Services initializing.", icon: "arrow.clockwise")
            GuideDefRow(name: "ready", description: "All services initialized. SDK fully operational.", icon: "checkmark.circle")
            GuideDefRow(name: "error", description: "Boot failed. Can retry boot from this state.", icon: "exclamationmark.triangle")
            GuideDefRow(name: "shuttingDown", description: "Graceful shutdown in progress.", icon: "power")
        }
        Section("Boot Sequence") {
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
        Section("Shutdown Sequence") {
            GuideDefRow(name: "Step 1", description: "Publish kernel.shutdown event on sdk.lifecycle channel", icon: "1.circle")
            GuideDefRow(name: "Step 2", description: "PluginRuntimeEngine.shared.stopAll() — stop all running apps", icon: "2.circle")
            GuideDefRow(name: "Step 3", description: "SDKDataStore.shared.flush() — persist all collections to disk", icon: "3.circle")
            GuideDefRow(name: "Step 4", description: "SDKEventBus.shared.stop() — persist history, stop bus", icon: "4.circle")
            GuideDefRow(name: "Step 5", description: "Reset state to idle, clear boot time and uptime", icon: "5.circle")
        }
        Section("Health Monitoring") {
            GuideDefRow(name: "KernelHealth", description: "Reports state, uptime, registered services, loaded plugins, data store and event bus health", icon: "heart.text.square")
            GuideDefRow(name: "isHealthy", description: "True when state == .ready AND dataStore AND eventBus are healthy", icon: "checkmark.shield")
            GuideDefRow(name: "Uptime Timer", description: "1-second interval timer tracking seconds since boot", icon: "timer")
        }
    }
}

// MARK: - Module System

private struct ModuleSystemSection: View {
    var body: some View {
        Section("Module Architecture") {
            Text("SDK modules are self-contained units that expose capabilities and features to the runtime. Modules register dynamically through SDKModuleRegistry and declare their dependencies, capabilities, and exported services.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Module Descriptor") {
            GuideDefRow(name: "identifier", description: "Unique reverse-domain string (e.g., com.app.analytics). Must be globally unique.", icon: "textformat")
            GuideDefRow(name: "displayName", description: "Human-readable name shown in UI", icon: "text.badge.star")
            GuideDefRow(name: "version", description: "Semantic version string (e.g., 1.0.0)", icon: "number")
            GuideDefRow(name: "minimumSDKVersion", description: "Minimum SDK version required (default: 2.0.0)", icon: "arrow.up.circle")
            GuideDefRow(name: "capabilities", description: "Array of SDKModuleCapability values this module provides", icon: "square.stack.3d.up")
            GuideDefRow(name: "dependencies", description: "Array of module identifiers this module requires", icon: "point.3.connected.trianglepath.dotted")
            GuideDefRow(name: "exportedServices", description: "Service keys this module provides to the DI container", icon: "tray.and.arrow.up")
            GuideDefRow(name: "loadPriority", description: "Integer load order — lower values load first (default: 100)", icon: "arrow.up.arrow.down")
        }
        Section("14 Module Capabilities") {
            Text("dataAccess, networking, storage, rendering, automation, authentication, analytics, messaging, fileSystem, aiProcessing, connectorBinding, pluginHosting, eventPublishing, backgroundExecution")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
        Section("Registration Flow") {
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
        Section("Feature Exposure") {
            GuideDefRow(name: "SDKExposedFeature", description: "Feature with typed input schema, output type, required capabilities", icon: "rectangle.and.text.magnifyingglass")
            GuideDefRow(name: "SDKFeatureParameter", description: "Typed parameter with name, type, isRequired, defaultValue", icon: "slider.horizontal.3")
            GuideDefRow(name: "SDKFeatureExposureManager", description: "Expose, retract, invoke, search features across modules", icon: "magnifyingglass")
        }
        Section("Module Provider Protocol") {
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
        Section("Plugin System Overview") {
            Text("Two plugin systems coexist: SDKPlugin (lightweight, tool-based) and SDKPluginManifest (full lifecycle). Both enforce permission boundaries and support automation hooks.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Plugin Lifecycle Phases") {
            GuideDefRow(name: "unloaded", description: "Plugin installed but not loaded into memory", icon: "arrow.down.circle")
            GuideDefRow(name: "loading", description: "Plugin being loaded, dependencies resolving", icon: "arrow.clockwise")
            GuideDefRow(name: "active", description: "Plugin fully operational, handling events", icon: "checkmark.circle.fill")
            GuideDefRow(name: "paused", description: "Plugin temporarily suspended, state preserved", icon: "pause.circle")
            GuideDefRow(name: "updating", description: "Plugin being updated to new version", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "migrating", description: "Plugin data being migrated between versions", icon: "arrow.right.arrow.left")
            GuideDefRow(name: "errored", description: "Plugin encountered unrecoverable error", icon: "exclamationmark.triangle")
            GuideDefRow(name: "disabled", description: "Plugin explicitly disabled by user or system", icon: "xmark.circle")
        }
        Section("Plugin Permissions") {
            GuideDefRow(name: "readData", description: "Read workspace data within allowed scopes", icon: "eye")
            GuideDefRow(name: "writeData", description: "Write/modify workspace data within allowed scopes", icon: "pencil")
            GuideDefRow(name: "network", description: "Make outbound network requests", icon: "network")
            GuideDefRow(name: "notifications", description: "Send push notifications to the user", icon: "bell")
            GuideDefRow(name: "fileAccess", description: "Access the local file system", icon: "folder")
        }
        Section("Plugin Categories") {
            Text("productivity, communication, development, analytics, automation, integration, utility, ai")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
        Section("Plugin Capability") {
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
        Section("App Runtime Engine") {
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
        Section("Connector System") {
            Text("Connectors bridge external services with the SDK runtime. Each connector implements BaseConnector protocol providing authentication, synchronization, and health monitoring.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("BaseConnector Protocol") {
            GuideDefRow(name: "authenticate(credentials:)", description: "Establish connection with external service using provided credentials", icon: "lock.open")
            GuideDefRow(name: "sync()", description: "Synchronize data between external service and SDK data store", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "testConnection()", description: "Verify connectivity and return health status", icon: "checkmark.icloud")
            GuideDefRow(name: "disconnect()", description: "Tear down connection and clean up resources", icon: "xmark.icloud")
        }
        Section("Built-in Connectors") {
            GuideDefRow(name: "Gmail", description: "OAuth2 email integration with message sync", icon: "envelope")
            GuideDefRow(name: "GitHub", description: "Personal Access Token auth with repository sync", icon: "chevron.left.forwardslash.chevron.right")
            GuideDefRow(name: "Webhook", description: "Generic HTTP endpoint for event-driven integrations", icon: "arrow.up.forward.app")
            GuideDefRow(name: "Calendar", description: "Calendar event synchronization via OAuth2", icon: "calendar")
            GuideDefRow(name: "Local File System", description: "File-based data import/export with no auth", icon: "folder")
        }
        Section("Authentication Methods") {
            Text("none, apiKey, oauth2, bearer, basic, certificate, webhook")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
        Section("Runtime Binding") {
            GuideDefRow(name: "dataSource", description: "Connector provides data to the bound module", icon: "arrow.right")
            GuideDefRow(name: "dataSink", description: "Module sends data to the connector for external storage", icon: "arrow.left")
            GuideDefRow(name: "eventTrigger", description: "Connector events trigger module actions", icon: "bolt")
            GuideDefRow(name: "authProvider", description: "Connector provides authentication to the module", icon: "lock")
            GuideDefRow(name: "configSource", description: "Connector provides configuration to the module", icon: "gearshape")
        }
        Section("Connector Templates") {
            GuideDefRow(name: "REST API", description: "Pre-configured template for RESTful API integration", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            GuideDefRow(name: "GraphQL", description: "Template for GraphQL endpoint integration", icon: "circle.grid.cross")
            GuideDefRow(name: "WebSocket", description: "Real-time bidirectional communication template", icon: "bolt.horizontal")
            GuideDefRow(name: "Firebase", description: "Firebase Realtime Database/Firestore template", icon: "flame")
            GuideDefRow(name: "Slack", description: "Slack API integration template", icon: "number")
            GuideDefRow(name: "MQTT", description: "IoT message broker template", icon: "sensor.tag.radiowaves.forward")
        }
        Section("Live Streaming") {
            GuideDefRow(name: "startLiveStream()", description: "Begin timer-based polling at configurable intervals", icon: "play.fill")
            GuideDefRow(name: "stopLiveStream()", description: "Cancel polling timer and stop data streaming", icon: "stop.fill")
            GuideDefRow(name: "Event Channel", description: "Events published to sdk.connectors.stream channel", icon: "antenna.radiowaves.left.and.right")
        }
    }
}

// MARK: - Dependencies

private struct DependenciesSection: View {
    var body: some View {
        Section("Dependency Management") {
            Text("The SDK dependency system manages libraries, modules, and their interconnections. Dependencies are represented as directed graphs with conflict detection and resolution.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Dependency Graph Resolution") {
            GuideDefRow(name: "Topological Sort", description: "Modules sorted by loadPriority, then depth-first traversal resolves order", icon: "arrow.triangle.branch")
            GuideDefRow(name: "Cycle Detection", description: "Circular dependencies detected during traversal and reported as conflicts", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Missing Dependencies", description: "Required modules not in registry flagged as missingDependency conflicts", icon: "exclamationmark.triangle")
            GuideDefRow(name: "Version Conflicts", description: "Incompatible version requirements between dependent modules detected", icon: "arrow.left.arrow.right")
            GuideDefRow(name: "Capability Collisions", description: "Exclusive capabilities (authentication, connectorBinding) checked for duplicates", icon: "exclamationmark.2")
        }
        Section("Library System") {
            GuideDefRow(name: "SDKLibraryDefinition", description: "Reusable libraries with version, scopes, exported functions, pipeline stages", icon: "books.vertical")
            GuideDefRow(name: "SDKLibraryVersionResolver", description: "Semantic version comparison and preferred version resolution", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "SDKLibraryDependencyBridge", description: "Converts library definitions into dependency graph nodes", icon: "arrow.triangle.branch")
            GuideDefRow(name: "SDKLibraryScopeBinder", description: "Binds library capabilities to specific SDK scopes", icon: "link.badge.plus")
        }
        Section("Dependency Node Types") {
            Text("library | connector | plugin | sdkApp")
                .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        }
        Section("Resolution Output") {
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
        Section("Execution Pipeline") {
            Text("Every governed operation in ToolsKitSDK follows a strict 8-stage pipeline ensuring security, auditing, and rate limiting on every call.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Pipeline Stages") {
            GuideDefRow(name: "1. Scope Validation", description: "SDKScopeManager.validateAccess() checks operation is within allowed scope", icon: "1.circle")
            GuideDefRow(name: "2. Policy Evaluation", description: "SDKPolicyEngine.evaluate() returns scope definition and rate rule", icon: "2.circle")
            GuideDefRow(name: "3. Rate Limiting", description: "SDKRateLimiter.enforce() with token bucket algorithm", icon: "3.circle")
            GuideDefRow(name: "4. Security Enforcement", description: "SDKSecurityManager.enforce() checks permissions, denied scopes, API keys", icon: "4.circle")
            GuideDefRow(name: "5. Privacy Filtering", description: "SDKPrivacyManager.redactRestrictedFields() strips sensitive data", icon: "5.circle")
            GuideDefRow(name: "6. Audit Logging", description: "SDKAuditLogger.log() records operation details", icon: "6.circle")
            GuideDefRow(name: "7. Execution", description: "Actual operation runs against data engine or external service", icon: "7.circle")
            GuideDefRow(name: "8. Event Emission", description: "Results published via SDKEventBridge to notify subscribers", icon: "8.circle")
        }
        Section("SDKContext") {
            GuideDefRow(name: "Scopes", description: "global, workspace, feature, plugin, request", icon: "rectangle.3.group")
            GuideDefRow(name: "Permissions", description: "Set of string tokens, wildcard '*' grants all", icon: "key")
            GuideDefRow(name: "Hierarchy", description: "Parent context chain for permission inheritance", icon: "arrow.up.forward")
            GuideDefRow(name: "Metadata", description: "Key-value pairs carrying request-scoped data", icon: "tag")
        }
        Section("Data Scopes (SDKScope)") {
            Text("all, tasks, notes, calendar, files, emails, whiteboards, plugins, slides, media, meet, repos, automations, intelligence, persona, custom(query:)")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Data Layer

private struct DataLayerSection: View {
    var body: some View {
        Section("Data Store Architecture") {
            Text("SDKDataStore provides unified offline-first persistence using file-based JSON storage. All models implement the SDKModel protocol for consistent CRUD, indexing, and versioning.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("SDKModel Protocol") {
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
        Section("Built-in Models") {
            GuideDefRow(name: "SDKMailMessage", description: "Email with from, to, cc, bcc, subject, body, labels, thread", icon: "envelope")
            GuideDefRow(name: "SDKNotebook", description: "Notebook with pages, tags, pinning, version history", icon: "book")
            GuideDefRow(name: "SDKMeetSession", description: "Meeting with participants, status, room URL, notes", icon: "video")
            GuideDefRow(name: "SDKArticle", description: "Article with content, author, tags, publish state, word count", icon: "doc.text")
            GuideDefRow(name: "SDKAppDefinition", description: "Plugin/app with version, permissions, sandbox flag, scopes", icon: "app")
        }
        Section("Data Operations") {
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
        Section("Event Bus") {
            Text("SDKEventBus is the unified pub/sub system for real-time communication across all SDK modules. Events are persisted to disk and bridged to legacy systems.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Event Channels") {
            GuideDefRow(name: "sdk.lifecycle", description: "Kernel boot/shutdown events", icon: "power")
            GuideDefRow(name: "sdk.modules", description: "Module registration and activation events", icon: "square.grid.3x3.fill")
            GuideDefRow(name: "sdk.plugins", description: "Plugin phase transition events", icon: "puzzlepiece")
            GuideDefRow(name: "sdk.apps", description: "App registration, start, stop events", icon: "app")
            GuideDefRow(name: "sdk.connectors", description: "Connector binding events", icon: "link")
            GuideDefRow(name: "sdk.connectors.stream", description: "Live data streaming tick events", icon: "bolt.horizontal")
            GuideDefRow(name: "sdk.features", description: "Feature exposure and retraction events", icon: "rectangle.and.text.magnifyingglass")
        }
        Section("SDKBusEvent Structure") {
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
        Section("Subscription Patterns") {
            GuideDefRow(name: "subscribe(channel:)", description: "Receive events matching a specific channel", icon: "antenna.radiowaves.left.and.right")
            GuideDefRow(name: "subscribe(name:)", description: "Receive events matching a specific event name", icon: "text.magnifyingglass")
            GuideDefRow(name: "subscribeAll()", description: "Receive all events from all channels", icon: "tray.full")
        }
        Section("History & Persistence") {
            GuideDefRow(name: "History Limit", description: "500 events retained in memory, oldest evicted", icon: "clock.arrow.circlepath")
            GuideDefRow(name: "Persistence", description: "History saved to event_history.json on stop, loaded on start", icon: "externaldrive")
            GuideDefRow(name: "Query", description: "Filter by channel, date range, or get recent N events", icon: "magnifyingglass")
        }
    }
}

// MARK: - Security

private struct SecuritySection: View {
    var body: some View {
        Section("Security Model") {
            Text("Hierarchical permission scopes ensure that modules only access necessary data. High-risk scopes require explicit user justification. All operations are rate-limited and audited.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Permission Hierarchy") {
            GuideDefRow(name: "Wildcard '*'", description: "Grants unrestricted access to all scopes", icon: "asterisk")
            GuideDefRow(name: "SDKContext Chain", description: "Permissions inherited from parent contexts up the hierarchy", icon: "arrow.up.forward")
            GuideDefRow(name: "App Boundaries", description: "Per-app permission sets enforced by SDKSecurityManager", icon: "rectangle.badge.person.crop")
            GuideDefRow(name: "Global Denied Scopes", description: "Denied scopes override all grants, including wildcard", icon: "xmark.shield")
        }
        Section("Security Scope Definitions") {
            GuideDefRow(name: "riskLevel", description: "low, medium, high, critical — determines rate limits", icon: "gauge.with.dots.needle.33percent")
            GuideDefRow(name: "requiresJustification", description: "High-risk scopes require explicit justification string", icon: "text.bubble")
            GuideDefRow(name: "runtimeValidationHook", description: "Optional callback for additional runtime checks", icon: "function")
        }
        Section("Rate Limiting") {
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
        Section("Audit Logging") {
            GuideDefRow(name: "Event Types", description: "dataAccess, scopeUsage, externalAPICall, execution, privacy, security", icon: "list.clipboard")
            GuideDefRow(name: "Capacity", description: "5000 events max with automatic oldest-first eviction", icon: "externaldrive")
            GuideDefRow(name: "Query", description: "Filter by projectID, eventType, date range", icon: "magnifyingglass")
        }
        Section("Sandbox Enforcement") {
            GuideDefRow(name: "isSandboxed", description: "Sandboxed plugins have permissions re-verified at every start", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "No-Sandbox Mode", description: "Development toggle via SDKRuntimeEngine for testing", icon: "shield.slash")
        }
    }
}

// MARK: - DI Container

private struct DIContainerSection: View {
    var body: some View {
        Section("Dependency Injection") {
            Text("ServiceContainer and ServiceRegistry provide protocol-based dependency injection. Services are registered as singletons by default with factory closures for lazy initialization.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Default Registrations") {
            GuideDefRow(name: "SDKDataStoreProtocol", description: "→ SDKDataStore.shared", icon: "database")
            GuideDefRow(name: "SDKEventBusProtocol", description: "→ SDKEventBus.shared", icon: "antenna.radiowaves.left.and.right")
            GuideDefRow(name: "SDKRouterProtocol", description: "→ SDKRouter.shared", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            GuideDefRow(name: "SDKPermissionManagerProtocol", description: "→ SDKPermissionManager.shared", icon: "lock.shield")
            GuideDefRow(name: "PluginRuntimeProtocol", description: "→ PluginRuntimeEngine.shared", icon: "puzzlepiece")
            GuideDefRow(name: "Feature Services", description: "Mail, Notebook, Meet, Article services", icon: "tray.full")
        }
        Section("Service Scopes") {
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
        Section("Internal API Router") {
            Text("SDKRouter provides on-device API routing with standardized request/response handling. Routes are registered with path patterns, HTTP methods, and async handlers.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Default Routes") {
            GuideDefRow(name: "GET /sdk/health", description: "Returns { status: healthy, version: 2.0.0 }", icon: "heart")
            GuideDefRow(name: "GET /sdk/info", description: "Returns SDK version, build number, environment", icon: "info.circle")
            GuideDefRow(name: "GET /sdk/services", description: "Lists all registered service names", icon: "list.bullet")
            GuideDefRow(name: "POST /mail/send", description: "Send email with to, subject, body parameters", icon: "envelope")
            GuideDefRow(name: "GET /mail/list", description: "List all email messages with count", icon: "tray")
            GuideDefRow(name: "POST /notebooks/create", description: "Create notebook with title parameter", icon: "book")
            GuideDefRow(name: "POST /meet/create", description: "Create meeting session with title", icon: "video")
            GuideDefRow(name: "POST /articles/create", description: "Create article with title and content", icon: "doc.text")
        }
        Section("Request/Response") {
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
        Section("Automation Engine") {
            Text("SDKAutomationEngine evaluates rules in a trigger → condition → action pipeline. Rules are persisted via SDKProjectManager and execute tools, sync connectors, or send notifications.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Triggers") {
            GuideDefRow(name: "dataUpdated(scope:)", description: "Fires when data in the specified scope changes", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "connectorEvent(id, name)", description: "Fires when a connector emits a specific event", icon: "link")
            GuideDefRow(name: "timeBased(interval:)", description: "Fires at a recurring time interval", icon: "timer")
        }
        Section("Conditions") {
            GuideDefRow(name: "fieldEquals(key, value)", description: "Check if a context field matches expected value", icon: "equal")
            GuideDefRow(name: "countExceeds(count)", description: "Check if context 'count' field exceeds threshold", icon: "greaterthan")
        }
        Section("Actions") {
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
        Section("Observable Architecture") {
            Text("All SDK managers use @MainActor and ObservableObject to drive SwiftUI view updates through @Published properties. Combine provides reactive data flow for event streaming.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("State Management Patterns") {
            GuideDefRow(name: "@Published", description: "Properties on ObservableObject that trigger view updates", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "@StateObject", description: "View-owned observable objects created once per view lifecycle", icon: "rectangle.badge.plus")
            GuideDefRow(name: "@ObservedObject", description: "Injected observable objects from parent views", icon: "arrow.right.circle")
            GuideDefRow(name: "@State", description: "View-local state for simple values", icon: "square.and.pencil")
            GuideDefRow(name: "Combine", description: "PassthroughSubject for event streaming, AnyCancellable for subscriptions", icon: "arrow.triangle.merge")
        }
        Section("Singleton Access") {
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
        Section("Navigation Patterns") {
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
        Section("SDK Export") {
            Text("SDK projects can be packaged as versioned .zip bundles containing modules, plugins, connectors, tools, automation rules, and runtime definitions.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Export Pipeline") {
            GuideDefRow(name: "SDKExportService", description: "Creates temp directory structure, encodes config.json, organizes all project assets", icon: "square.and.arrow.up")
            GuideDefRow(name: "SDKDownloadView", description: "Version selection, bundle download, and export configuration interface", icon: "arrow.down.circle")
        }
        Section("Import Pipeline") {
            GuideDefRow(name: "CustomAppSDKView", description: "Import .zip bundles, validate structure and compatibility, register into runtime", icon: "arrow.down.doc")
            GuideDefRow(name: "Validation", description: "SDK version match, module integrity, plugin compatibility, connector support checks", icon: "checkmark.shield")
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

// MARK: - Deployment

private struct DeploymentSection: View {
    var body: some View {
        Section("Release Pipeline") {
            GuideDefRow(name: "Versioning", description: "Semantic versioning (SemVer) required for all SDK modules", icon: "number")
            GuideDefRow(name: "Validation", description: "Automated verification of capability and action schemas", icon: "checkmark.shield")
        }
        Section("Build Configuration") {
            GuideDefRow(name: "Build Modes", description: "Debug, Release, and Profile modes with platform targeting (iOS, macOS, watchOS, tvOS)", icon: "hammer")
            GuideDefRow(name: "Integration Tests", description: "Automated testing of module integrations and connector health", icon: "testtube.2")
            GuideDefRow(name: "SDKDeploymentView", description: "Project export, provisioning, and distribution management", icon: "cloud.arrow.up")
        }
        Section("Environment Configuration") {
            GuideDefRow(name: "development", description: "Local development with debug logging and sandbox bypass", icon: "ladybug")
            GuideDefRow(name: "staging", description: "Pre-production testing with production-like constraints", icon: "arrow.clockwise")
            GuideDefRow(name: "production", description: "Full security enforcement, analytics enabled, encrypted storage", icon: "lock.shield")
        }
    }
}

// MARK: - Constraints & Rules

private struct ConstraintsSection: View {
    var body: some View {
        Section("System Constraints") {
            Text("These constraints are enforced at runtime and must not be circumvented by any SDK consumer, plugin, or module.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Prohibited Interactions") {
            GuideDefRow(name: "No External Knowledge", description: "AI features must derive all context from SDK_AI_System.md only", icon: "xmark.circle")
            GuideDefRow(name: "No Hardcoded Prompts", description: "System prompts must be constructed from SDK documentation at runtime", icon: "xmark.circle")
            GuideDefRow(name: "No Unscoped Data Access", description: "All data operations must go through the governed execution pipeline", icon: "xmark.circle")
            GuideDefRow(name: "No Direct File System", description: "Use SDKDataStore or SDKStorageManager for all persistence", icon: "xmark.circle")
            GuideDefRow(name: "No Unaudited Operations", description: "All sensitive operations must be logged via SDKAuditLogger", icon: "xmark.circle")
            GuideDefRow(name: "No Permission Escalation", description: "Apps cannot grant themselves permissions beyond their manifest", icon: "xmark.circle")
            GuideDefRow(name: "No Rate Limit Bypass", description: "All operations subject to rate limiting based on scope risk level", icon: "xmark.circle")
            GuideDefRow(name: "No Cross-Scope Leakage", description: "Data from one scope must not leak to another without explicit permission", icon: "xmark.circle")
        }
        Section("Security Boundaries") {
            GuideDefRow(name: "Kernel Access", description: "Only WorkspaceSDK.shared.initialize() may trigger kernel boot", icon: "lock")
            GuideDefRow(name: "Plugin Sandbox", description: "Sandboxed plugins re-verified at every start, cannot escalate", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "API Key Validation", description: "Project-scoped API keys validated on every governed call", icon: "key")
            GuideDefRow(name: "Privacy Redaction", description: "Sensitive fields automatically stripped before data return", icon: "eye.slash")
        }
        Section("Error Types") {
            GuideDefRow(name: "validationError(reason:)", description: "Input validation failure — bad parameters, duplicate entries", icon: "exclamationmark.triangle")
            GuideDefRow(name: "executionFailed(reason:)", description: "Runtime execution failure — rate limits, missing handlers", icon: "xmark.octagon")
            GuideDefRow(name: "permissionDenied(scope:)", description: "Authorization failure — insufficient permissions for scope", icon: "lock.slash")
        }
    }
}

// MARK: - Best Practices

private struct BestPracticesSection: View {
    var body: some View {
        Section("Architecture") {
            GuideDefRow(name: "Mobile-First", description: "All interactions must be gesture-driven, contextual, and use NavigationStack/sheets/overlays", icon: "iphone")
            GuideDefRow(name: "Reactive State", description: "Use @Published properties and Combine for all state management", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Offline-First", description: "Design all data operations to work without network connectivity", icon: "wifi.slash")
        }
        Section("Module Design") {
            GuideDefRow(name: "Single Responsibility", description: "Each module should own one well-defined capability domain", icon: "1.circle")
            GuideDefRow(name: "Explicit Dependencies", description: "Always declare module dependencies in the descriptor", icon: "list.bullet")
            GuideDefRow(name: "Feature Exposure", description: "Expose features with typed parameter schemas for runtime discovery", icon: "rectangle.and.text.magnifyingglass")
            GuideDefRow(name: "Versioning", description: "Use semantic versioning and set minimumSDKVersion correctly", icon: "number")
        }
        Section("Plugin Development") {
            GuideDefRow(name: "Lifecycle Awareness", description: "Handle all lifecycle phases (loading, active, paused, updating, migrating)", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Sandboxed Execution", description: "Plugins run in isolated contexts with scoped permissions", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "Manifest-Driven", description: "Declare all capabilities, permissions, and hooks in the plugin manifest", icon: "doc.text")
            GuideDefRow(name: "Error Recovery", description: "Implement graceful degradation for errored phase transitions", icon: "arrow.uturn.backward")
        }
        Section("Connector Integration") {
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
        Section("Kernel & Lifecycle Definitions") {
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

        Section("Environment & Configuration Definitions") {
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

        Section("Context & Scope Definitions") {
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

        Section("Module System Definitions") {
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

        Section("Plugin System Definitions") {
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

        Section("Connector System Definitions") {
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

        Section("Security Definitions") {
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

        Section("Event System Definitions") {
            StructDef(name: "SDKBusEvent", fields: [
                ("id", "UUID", "Unique event identifier"),
                ("channel", "String", "Event channel (e.g., sdk.lifecycle)"),
                ("name", "String", "Event name (e.g., kernel.ready)"),
                ("data", "[String: String]", "Event payload key-value pairs"),
                ("source", "String", "Event source identifier"),
                ("timestamp", "Date", "Event creation timestamp"),
            ], notes: "Codable, Identifiable. Published via SDKEventBus.publish()")
        }

        Section("Data Model Definitions") {
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

        Section("Automation Definitions") {
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

        Section("Router Definitions") {
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

// MARK: - Analytics

private struct AnalyticsSection: View {
    var body: some View {
        Section("Analytics Engine") {
            Text("SDKAnalyticsEngine provides unified telemetry across all modules. It supports event tracking with structured metadata and session management.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "track(event:)", description: "Record a custom event with properties", icon: "point.3.filled.connected.trianglepath.dotted")
            GuideDefRow(name: "identify(userID:)", description: "Associate events with a specific user context", icon: "person.text.rectangle")
            GuideDefRow(name: "flush()", description: "Force immediate transmission of queued events", icon: "arrow.up.circle")
        }
        Section("Metrics Collection") {
            GuideDefRow(name: "Counter", description: "Monotonically increasing integer values", icon: "plus.forwardslash.minus")
            GuideDefRow(name: "Gauge", description: "Current value of a system variable (e.g. CPU)", icon: "gauge.medium")
            GuideDefRow(name: "Histogram", description: "Distribution of values over time", icon: "chart.bar")
        }
    }
}

// MARK: - Health

private struct HealthSection: View {
    var body: some View {
        Section("Health Monitoring") {
            Text("SDKHealthMonitor continuously watches core services and reports system stability via the Heartbeat system.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "isHealthy", description: "Computed property aggregating all service states", icon: "checkmark.shield")
            GuideDefRow(name: "Heartbeat", description: "1-minute periodic check of all registered health providers", icon: "waveform.path.ecg")
        }
        Section("Resource Watchers") {
            GuideDefRow(name: "CPUMonitor", description: "Alerts when CPU usage exceeds 80% for > 5s", icon: "cpu")
            GuideDefRow(name: "MemoryWatcher", description: "Monitors memory pressure and triggers cache clearing", icon: "memorychip")
            GuideDefRow(name: "StorageWatch", description: "Monitors free space and warns on low capacity", icon: "externaldrive")
        }
    }
}

// MARK: - Workflow

private struct WorkflowSection: View {
    var body: some View {
        Section("Workflow Engine") {
            Text("SDKWorkflowEngine orchestrates complex multi-step processes across multiple SDK modules.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "Step", description: "Single executable unit with input/output validation", icon: "list.number")
            GuideDefRow(name: "Chain", description: "Sequence of steps with error propagation handles", icon: "link")
            GuideDefRow(name: "Branch", description: "Conditional logic determining the next step", icon: "arrow.triangle.branch")
        }
        Section("Implementation Example") {
            VStack(alignment: .leading, spacing: 8) {
                Text("""
                let workflow = SDKWorkflow("ProcessData")
                    .addStep(FetchStep())
                    .addStep(ValidateStep())
                    .onSuccess { print("Complete") }
                    .onFailure { error in handle(error) }

                await workflow.execute()
                """)
                .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

// MARK: - Advanced Services

private struct AdvancedServicesSection: View {
    var body: some View {
        Section("Real-time Sync") {
            Text("SDKRealtimeSync handles multi-device state synchronization and conflict resolution using a deterministic merge algorithm.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "Sync Engine", description: "WebSocket-based delta propagation with retry logic", icon: "arrow.triangle.2.circlepath")
            GuideDefRow(name: "Conflict Resolver", description: "Last-writer-wins or custom merge strategies", icon: "arrow.triangle.merge")
        }
        Section("Feature Flags") {
            Text("SDKFeatureFlagService manages dynamic feature toggles and A/B testing configurations.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "isFeatureEnabled()", description: "Sync check for local or remote feature availability", icon: "flag.fill")
            GuideDefRow(name: "Experimentation", description: "Support for weight-based rollouts and user segments", icon: "testtube.2")
        }
        Section("Background Engine") {
            Text("SDKBackgroundEngine orchestrates long-running tasks and periodic maintenance windows.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "Maintenance Task", description: "Runs only when device is charging and on WiFi", icon: "hammer.fill")
            GuideDefRow(name: "Data Pruning", description: "Automatic cleanup of expired cache and log entries", icon: "trash.fill")
        }
    }
}

// MARK: - Project Management

private struct ProjectManagementSection: View {
    var body: some View {
        Section("Project Lifecycle") {
            Text("SDKProjectManager maintains the state of SDK projects, including enabled scopes, plugins, and build metadata.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "createProject()", description: "Initialize a new project with default configuration", icon: "plus.square")
            GuideDefRow(name: "loadProject(id:)", description: "Restore project state from local storage", icon: "folder.badge.plus")
            GuideDefRow(name: "updateProject()", description: "Persist changes to the current project manifest", icon: "arrow.clockwise")
        }
        Section("Configuration Overrides") {
            GuideDefRow(name: "SDKConfigManager", description: "Provides dynamic overrides for SDK system settings", icon: "slider.horizontal.3")
            GuideDefRow(name: "ConfigEntry", description: "Key-value pair with priority-based resolution", icon: "key")
        }
    }
}

// MARK: - Library System

private struct LibrarySystemSection: View {
    var body: some View {
        Section("Versioning & Resolving") {
            Text("The Library System manages external and internal dependencies with semantic versioning support.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "SDKLibraryVersionResolver", description: "Selects optimal library versions based on constraints", icon: "number.square")
            GuideDefRow(name: "SDKLibraryScopeBinder", description: "Binds library functions to protected SDK scopes", icon: "link")
        }
        Section("Dependency Bridging") {
            GuideDefRow(name: "SDKLibraryDependencyBridge", description: "Integrates legacy frameworks into the modern SDK graph", icon: "point.3.connected.trianglepath.dotted")
            GuideDefRow(name: "ConflictResolver", description: "Automated resolution of version and capability overlaps", icon: "exclamationmark.triangle")
        }
    }
}

// MARK: - Localization & Accessibility

private struct LocalizationAccessibilitySection: View {
    var body: some View {
        Section("Localization") {
            Text("SDKLocalizationManager provides localized strings and asset resolution for all SDK UI components.")
                .font(.subheadline).foregroundStyle(.secondary)
            GuideDefRow(name: "localizedString(key:)", description: "Retrieve translation for the current system locale", icon: "character.bubble")
            GuideDefRow(name: "setLocale(identifier:)", description: "Force override the SDK locale for testing", icon: "globe")
        }
        Section("Accessibility") {
            GuideDefRow(name: "SDKAccessibilityService", description: "Provides semantic labels and traits for VoiceOver", icon: "accessibility")
            GuideDefRow(name: "highContrastMode", description: "Global state for enhanced visibility support", icon: "circle.lefthalf.filled")
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
