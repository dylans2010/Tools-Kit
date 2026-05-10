# SDK AI System — Authoritative Architecture Reference

> **This document is the single source of truth for all AI-driven SDK features.**
> All AI behavior in SDKHelpView and SDKSupportView must be derived exclusively from this file at runtime.
> No external prompts, models, or fallback knowledge is permitted.

---

## 1. SDK Architecture and System Structure

### 1.1 Platform Overview

ToolsKit SDK is a modular, offline-first development platform built entirely in Swift and SwiftUI. It provides a kernel-managed runtime for building, extending, and composing workspace applications. The SDK follows a layered architecture with strict separation of concerns.

### 1.2 System Layers

| Layer | Purpose | Key Components |
|---|---|---|
| Kernel | Lifecycle bootstrap, health monitoring, uptime tracking | `WorkspaceSDKKernel` |
| Services | Domain-specific business logic | `SDKMailService`, `SDKNotebookService`, `SDKMeetService`, `SDKArticleService` |
| Data | Offline-first persistence, indexing, batch operations | `SDKDataStore`, `SDKModel` |
| Events | Pub/sub communication across modules | `SDKEventBus`, `SDKBusEvent` |
| Security | Permissions, policies, rate limiting, audit logging | `SDKSecurityManager`, `SDKPolicyEngine`, `SDKRateLimiter`, `SDKAuditLogger` |
| Router | On-device internal API endpoints | `SDKRouter`, `SDKRequest`, `SDKResponse` |
| DI | Dependency injection and service resolution | `ServiceContainer`, `ServiceRegistry` |
| Modules | Dynamic module registration and capability exposure | `SDKModuleRegistry`, `SDKFeatureExposureManager`, `SDKDependencyGraph` |
| Plugins | App/plugin lifecycle, manifest system, sandboxed execution | `PluginRuntimeEngine`, `SDKPluginLifecycleManager`, `SDKPluginManager` |
| Connectors | External service bridges with auth, sync, and binding | `SDKConnectorManager`, `SDKConnectorRuntimeBinder`, `BaseConnector` |
| Automation | Rule-based trigger/action system | `SDKAutomationEngine` |
| Runtime | Unified public API facade | `WorkspaceSDK`, `ToolsKitSDK` |

### 1.3 Public API Facade

`WorkspaceSDK.shared` is the unified entry point exposing all subsystems:

- `sdk.mail` — Email operations
- `sdk.notebooks` — Notebook CRUD and versioning
- `sdk.meet` — Meeting session management
- `sdk.articles` — Article publishing
- `sdk.plugins` — Plugin/app runtime
- `sdk.storage` — Data persistence
- `sdk.events` — Event bus pub/sub
- `sdk.router` — Internal API routing
- `sdk.security` — Permission management
- `sdk.kernel` — Lifecycle and health
- `sdk.environment` — Configuration and feature flags
- `sdk.services` — DI container

### 1.4 Boot Sequence

The kernel boots in a strict sequential order:

1. `SDKEnvironment.shared.load()` — Load configuration from UserDefaults
2. `ServiceContainer.shared.registerDefaults()` — Register all default service bindings
3. `SDKDataStore.shared.initialize()` — Initialize file-based JSON storage
4. `SDKEventBus.shared.start()` — Start the event bus and load history
5. `SDKRouter.shared.registerDefaultRoutes()` — Register health, info, and CRUD routes
6. `SDKPermissionManager.shared` — Initialize permission manager
7. `PluginRuntimeEngine.shared.initialize()` — Load persisted apps
8. Feature modules boot: Mail, Notebook, Meet, Articles

### 1.5 Shutdown Sequence

1. Publish `kernel.shutdown` event
2. `PluginRuntimeEngine.shared.stopAll()` — Stop all running apps
3. `SDKDataStore.shared.flush()` — Persist all collections to disk
4. `SDKEventBus.shared.stop()` — Persist event history and stop bus
5. Reset kernel state to idle

---

## 2. Module System Behavior and Lifecycle

### 2.1 Module Descriptor

Every module is described by `SDKModuleDescriptor`:

- `identifier` — Unique reverse-domain string (e.g., `com.app.analytics`)
- `displayName` — Human-readable name
- `version` — Semantic version string
- `minimumSDKVersion` — Minimum required SDK version
- `capabilities` — Array of `SDKModuleCapability` values
- `dependencies` — Array of other module identifiers required
- `exportedServices` — Services this module provides
- `isEnabled` — Whether the module is active
- `loadPriority` — Integer determining load order (lower = earlier)

### 2.2 Module Capabilities

Available capabilities: `dataAccess`, `networking`, `storage`, `rendering`, `automation`, `authentication`, `analytics`, `messaging`, `fileSystem`, `aiProcessing`, `connectorBinding`, `pluginHosting`, `eventPublishing`, `backgroundExecution`.

### 2.3 Module Registration Flow

1. Validate no duplicate identifier exists
2. Check all declared dependencies are already registered
3. Append to registry and sort by `loadPriority`
4. Log registration event
5. Persist to UserDefaults
6. Publish `module.registered` event on `sdk.modules` channel

### 2.4 Module Activation

1. Verify module exists in registry
2. Recursively activate any unactivated dependencies
3. Call provider's `activate(context:)` method if registered
4. Add to `activeModuleIDs`
5. Log activation event

### 2.5 Module Deactivation

1. Call provider's `deactivate()` method
2. Remove from `activeModuleIDs`
3. Retract all exposed features for this module via `SDKFeatureExposureManager`

### 2.6 Feature Exposure

Modules expose features through `SDKFeatureExposureManager`:

- Each feature has typed `SDKFeatureParameter` input schema
- Features declare required capabilities
- Features are invokable by ID with parameter validation
- Features can be searched by name, description, or module
- Features can be queried by capability type

### 2.7 Module Provider Protocol

```
SDKModuleProvider:
  - descriptor: SDKModuleDescriptor
  - activate(context: SDKContext) async throws
  - deactivate() async
  - healthCheck() -> Bool
```

---

## 3. Plugin System Architecture and Extensibility Rules

### 3.1 Plugin Models

Two plugin systems coexist:

**SDKPlugin** (via `SDKPluginManager`):
- Lightweight plugin with permissions, tools, and automation hooks
- Permissions: `readData`, `writeData`, `network`, `notifications`, `fileAccess`
- Executes hooks by running associated tools via `SDKToolManager`

**SDKPluginManifest** (via `SDKPluginLifecycleManager`):
- Full manifest-driven plugin with lifecycle phases
- Declares capabilities, dependencies, permissions, hooks, category
- Categories: `productivity`, `communication`, `development`, `analytics`, `automation`, `integration`, `utility`, `ai`

### 3.2 Plugin Lifecycle Phases

Phases: `unloaded` → `loading` → `active` → `paused` → `updating` → `migrating` → `errored` → `disabled`

Valid transitions are enforced by `isTransitionValid(from:to:)`.

### 3.3 Plugin Capability

Each `SDKPluginCapability` defines:
- `name` — Capability identifier
- `description` — What the capability provides
- `requiredPermissions` — Permissions needed to use it
- `injectedServiceKey` — Optional service key for DI injection

### 3.4 App Runtime (PluginRuntimeEngine)

`PluginRuntimeEngine` manages `SDKAppDefinition` instances:

1. **Registration**: Validate uniqueness, check all permissions are authorized
2. **Start**: Verify sandbox permissions, call lifecycle handler's `onStart()`, mark as running
3. **Stop**: Call lifecycle handler's `onStop()`, remove from running set
4. **Unregister**: Stop, remove lifecycle handler, remove from loaded apps

### 3.5 App Definition Properties

- `id`, `name`, `version`, `author`, `description`
- `permissions` — Array of scope strings
- `isSandboxed` — Whether sandbox enforcement applies
- `isEnabled` — Current running state
- `scopes` — Array of `SDKScope` values the app can access

### 3.6 Extensibility Rules

- Plugins must declare all required permissions in their manifest
- Permission must be grantable before installation
- Sandboxed plugins have every permission re-checked at start time
- Plugins interact with workspace via automation hooks and tool execution
- Plugin uninstallation retracts all exposed features

---

## 4. Connector System Behavior and Integration Patterns

### 4.1 BaseConnector Protocol

All connectors implement:
- `authenticate(credentials:)` — Establish connection with external service
- `sync()` — Synchronize data between external service and SDK
- `testConnection()` — Verify connectivity
- `disconnect()` — Tear down connection

### 4.2 Built-in Connectors

| Connector | Type | Auth Method |
|---|---|---|
| GmailConnector | gmail | OAuth2 |
| GitHubConnector | github | Personal Access Token |
| WebhookConnector | webhook | API Key / None |
| CalendarConnector | calendar | OAuth2 |
| LocalFileConnector | localFileSystem | None |

### 4.3 Connector Manager

`SDKConnectorManager` handles:
- Registration and removal of connector instances
- Concurrent sync across all connected connectors using `TaskGroup`
- Status tracking per connector
- Persistence of connector configurations

### 4.4 Runtime Binding

`SDKConnectorRuntimeBinder` links connectors to SDK modules:

**Binding Types**: `dataSource`, `dataSink`, `eventTrigger`, `authProvider`, `configSource`

### 4.5 Authentication Methods

Supported via `ConnectorAuthMethod`: `none`, `apiKey`, `oauth2`, `bearer`, `basic`, `certificate`, `webhook`

### 4.6 Connector Templates

Pre-configured templates for: REST API, GraphQL, WebSocket, Firebase, Slack, MQTT

### 4.7 Live Streaming

- Timer-based polling at configurable intervals
- Events published to `sdk.connectors.stream` channel
- Stream control via `startLiveStream()` / `stopLiveStream()`

---

## 5. Dependency Resolution and Management Logic

### 5.1 Dependency Graph

`SDKDependencyGraph` resolves module load order using topological sort:

1. Sort modules by `loadPriority`
2. Depth-first traversal with cycle detection
3. Missing dependency detection
4. Version conflict detection
5. Capability collision detection (exclusive capabilities: `authentication`, `connectorBinding`)

### 5.2 Conflict Types

- `versionMismatch` — Incompatible version requirements
- `circularDependency` — Cycle detected in dependency chain
- `capabilityCollision` — Multiple modules claim exclusive capability
- `missingDependency` — Required module not registered

### 5.3 Resolution Output

`SDKDependencyResolution` contains:
- `orderedModules` — Topologically sorted load order
- `conflicts` — All detected conflicts
- `warnings` — Non-fatal issues (e.g., large graph > 50 modules)
- `isClean` — True if no conflicts exist

### 5.4 Library System

- `SDKLibraryDefinition` — Reusable libraries with version, scopes, exported functions, pipeline stages
- `SDKLibraryVersionResolver` — Semantic version comparison and preferred version resolution
- `SDKLibraryDependencyBridge` — Converts library definitions into dependency graph nodes
- `SDKDependencyNode` — Graph node with kind (library/connector/plugin/sdkApp), version, links, hooks, conditions

### 5.5 Dependency Scope Validation

`SDKDependencyScopeValidator` ensures dependencies stay within allowed scope boundaries.

### 5.6 Conflict Resolution

`SDKDependencyConflictResolver` attempts automatic resolution of version mismatches and capability collisions.

### 5.7 Execution Planning

`SDKDependencyExecutionPlanner` determines optimal execution order respecting all dependency constraints.

---

## 6. Runtime Execution Model

### 6.1 Kernel State Machine

States: `idle` → `booting` → `ready` → `error` → `shuttingDown`

- Boot only allowed from `idle` or `error`
- Health check available in any state
- Uptime tracked via 1-second timer

### 6.2 SDKContext

Runtime context carries request-scoped metadata:

- **Scopes**: `global`, `workspace`, `feature`, `plugin`, `request`
- **Permissions**: Set of string-based permission tokens
- **Hierarchy**: Parent context chain for permission inheritance
- Wildcard permission `"*"` grants all access

### 6.3 Execution Pipeline (ToolsKitSDK)

Every governed operation follows this pipeline:

1. **Scope Validation** — `SDKScopeManager.validateAccess()`
2. **Policy Evaluation** — `SDKPolicyEngine.evaluate()` returns scope definition and rate rule
3. **Rate Limiting** — `SDKRateLimiter.enforce()` with token bucket algorithm
4. **Security Enforcement** — `SDKSecurityManager.enforce()` checks permissions, denied scopes, API keys
5. **Privacy Filtering** — `SDKPrivacyManager.redactRestrictedFields()` removes sensitive data
6. **Audit Logging** — `SDKAuditLogger.log()` records the operation
7. **Execution** — Actual operation runs
8. **Event Emission** — Results published via `SDKEventBridge`

### 6.4 SDKScope

Data access scopes: `all`, `tasks`, `notes`, `calendar`, `files`, `emails`, `whiteboards`, `plugins`, `slides`, `media`, `meet`, `repos`, `automations`, `intelligence`, `persona`, `custom(query:)`

### 6.5 Background Execution

`SDKBackgroundEngine` manages background tasks and execution scheduling.

### 6.6 Tool Runtime

`SDKToolRuntime` and `SDKToolManager` provide tool registration, execution, and management.

---

## 7. SwiftUI Integration Patterns and UI Binding Behavior

### 7.1 Observable Architecture

All SDK managers use `@MainActor` and `ObservableObject`:
- `@Published` properties drive SwiftUI view updates
- `Combine` pipelines for reactive data flow
- `@StateObject` for view-owned instances
- `@ObservedObject` for injected instances

### 7.2 Singleton Access Pattern

All core services use `static let shared` singleton pattern:
- `WorkspaceSDK.shared`, `WorkspaceSDKKernel.shared`
- `SDKModuleRegistry.shared`, `SDKPluginManager.shared`
- `SDKConnectorManager.shared`, `SDKEventBus.shared`
- `SDKDataStore.shared`, `SDKRouter.shared`

### 7.3 View Architecture

SDK views are organized in a hierarchical structure:

- **Main**: `SDKHomeView`, `SDKControlCenterView`, `SDKInternalView`, `SDKPluginsView`, `SDKProjectDashboardView`, `SDKWorkspaceContainerView`
- **Builder**: `SDKAppBuilderView`, `SDKBuildView`, `SDKFlowBuilderView`, `SDKDownloadView`, `CustomAppSDKView`
- **Editor**: `SDKProjectEditorView`, `SDKNavigatorView`, `SDKConsoleView`, `SDKInspectorPanelView`, IDE views
- **Explorer**: `SDKAPIBrowserView`, `SDKAPIExplorerView`, `SDKAutomationView`, `SDKCapabilitiesMatrixView`, `SDKDataControlView`
- **Diagnostics**: `SDKDebugView`, `SDKDiagnosticsView`, `SDKEventStreamView`, `SDKLogsView`, `SDKSecurityMonitorView`
- **Docs**: `SDKHelpView`, `SDKSupportView`, `SDKDeveloperGuideView`
- **Management**: `SDKDependencyManagerView`, `SDKLibraryManagerView`, `SDKModuleRegistryView`, `SDKPermissionControlView`, `SDKPluginManagerView`
- **Deployment**: `SDKDeploymentView`

### 7.4 UI Components

Shared SDK UI components from `SDKUIComponents.swift`:
- `SDKSectionHeader` — Section header with title, subtitle, icon
- `SDKStatusPill` — Status indicator capsule
- `SDKModernCard` — Card container
- `SDKStatPill` — Statistic display pill

### 7.5 Navigation Pattern

Views use `NavigationStack` with `.navigationTitle()` and toolbar items. Sheets use `.presentationDetents()` for adaptive sizing.

### 7.6 State Management

- `@State` for view-local state
- `@StateObject` for view-owned observable objects
- `@Published` on `ObservableObject` for shared state
- `Combine` `PassthroughSubject` for event streaming
- `UserDefaults` for lightweight persistence
- File-based JSON for data store persistence

---

## 8. System Constraints, Permissions, and Prohibited Interactions

### 8.1 Permission Model

- Hierarchical scope-based permissions
- Wildcard `"*"` grants unrestricted access
- Permission inheritance through `SDKContext` parent chain
- Per-app permission boundaries via `SDKSecurityManager`
- Global denied scopes override all grants

### 8.2 Security Scope Definitions

Each scope has:
- `riskLevel`: `low`, `medium`, `high`, `critical`
- `requiresJustification`: Boolean flag
- `runtimeValidationHook`: Optional validation callback

### 8.3 Rate Limiting

Token bucket algorithm with per-scope rules:

| Risk Level | Requests/min | Data Fetch Limit | Execution Cap |
|---|---|---|---|
| Low | 180 | 5000 | 180 |
| Medium | 120 | 2500 | 120 |
| High | 60 | 1000 | 60 |
| Critical | 30 | 500 | 30 |

### 8.4 Audit Logging

All governed operations are logged with:
- Event type: `dataAccess`, `scopeUsage`, `externalAPICall`, `execution`, `privacy`, `security`
- Project ID, scope, message, metadata
- Capped at 5000 entries with automatic rotation

### 8.5 Privacy Management

`SDKPrivacyManager` redacts restricted fields from data payloads before returning to callers.

### 8.6 Sandbox Enforcement

- Plugins marked `isSandboxed = true` have permissions re-verified at every start
- `SDKSandboxEngine` and `SDKSandboxController` enforce isolation
- `SDKNoSandboxOverrideController` allows bypassing sandbox in development mode
- No-sandbox mode can be toggled via `SDKRuntimeEngine`

### 8.7 Prohibited Interactions

- **No external knowledge sources**: AI features must derive all context from this document only
- **No hardcoded prompts**: System prompts must be constructed from SDK_AI_System.md content
- **No unscoped data access**: All data operations must go through the governed execution pipeline
- **No direct file system access**: Use `SDKDataStore` or `SDKStorageManager`
- **No unaudited operations**: All sensitive operations must be logged
- **No permission escalation**: Apps cannot grant themselves permissions beyond their manifest
- **No bypassing rate limits**: All operations subject to rate limiting based on scope risk level
- **No cross-scope leakage**: Data from one scope must not leak into another without explicit permission

### 8.8 Environment Configuration

`SDKEnvironment` manages:
- SDK version, build number, environment (development/staging/production)
- Log level, cache size, event history limit
- Plugin sandbox toggle, offline mode, data encryption, analytics
- Feature flags with runtime toggling

### 8.9 Error Types

`SDKError` cases:
- `validationError(reason:)` — Input validation failure
- `executionFailed(reason:)` — Runtime execution failure
- `permissionDenied(scope:)` — Authorization failure

### 8.10 Automation Constraints

Automation rules follow trigger → condition → action pattern:
- **Triggers**: `dataUpdated(scope:)`, `connectorEvent(connectorID:eventName:)`, `timeBased(interval:)`
- **Conditions**: `fieldEquals(key:value:)`, `countExceeds(count:)`
- **Actions**: `runTool`, `syncConnector`, `sendNotification`, `exportData`

### 8.11 Export and Packaging

SDK projects export as versioned `.zip` bundles:
- `config.json` — Project configuration
- `Plugins/` — Plugin definitions
- `Tools/` — Tool definitions
- `Connectors/` — Connector configurations
- `Automations/` — Automation rules

---

## 9. Data Relationships

### 9.1 Core Relationships

```
WorkspaceSDKKernel
  ├── SDKEnvironment (configuration)
  ├── ServiceContainer (DI)
  │   └── ServiceRegistry (protocol-based resolution)
  ├── SDKDataStore (persistence)
  ├── SDKEventBus (pub/sub)
  ├── SDKRouter (API routing)
  ├── SDKPermissionManager (permissions)
  ├── PluginRuntimeEngine (app lifecycle)
  └── Feature Modules
      ├── SDKMailService
      ├── SDKNotebookService
      ├── SDKMeetService
      └── SDKArticleService

SDKModuleRegistry
  ├── SDKModuleDescriptor[] (module definitions)
  ├── SDKModuleProvider[] (runtime providers)
  └── SDKFeatureExposureManager (feature exposition)

SDKPluginLifecycleManager
  ├── SDKPluginManifest[] (plugin definitions)
  └── SDKPluginPhase[] (lifecycle state)

SDKConnectorManager
  ├── BaseConnector[] (connector instances)
  └── SDKConnectorRuntimeBinder
      ├── ConnectorBinding[] (module bindings)
      └── ConnectorTemplate[] (pre-configured templates)

SDKSecurityManager
  ├── SDKPolicyEngine (scope definitions, policy evaluation)
  ├── SDKRateLimiter (token bucket rate limiting)
  ├── SDKAuditLogger (operation audit trail)
  └── SDKPrivacyManager (field redaction)
```

### 9.2 Event Channels

- `sdk.lifecycle` — Kernel boot/shutdown events
- `sdk.modules` — Module registration/activation events
- `sdk.plugins` — Plugin phase transition events
- `sdk.apps` — App registration/start/stop events
- `sdk.connectors` — Connector binding events
- `sdk.connectors.stream` — Live data streaming events
- `sdk.features` — Feature exposure events

---

*This document was generated from a full audit of the ToolsKit SDK codebase in Sources/Core/SDK and Sources/Views/Workspace/SDK. It serves as the only authorized context source for AI-driven SDK features.*
