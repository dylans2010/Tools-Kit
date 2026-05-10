# ToolsKit SDK: AI System Specification

This document serves as the canonical source of truth for the ToolsKit SDK. It defines the system architecture, module behavior, plugin and connector systems, and provides a complete inventory of every component within the SDK ecosystem.

---

## 1. System Inventory: Core SDK Logic

### Sources/Core/SDK/Kernel/WorkspaceSDKKernel.swift
- **Purpose**: The central bootstrap and lifecycle manager for the entire SDK.
- **Responsibilities**: Initializes all SDK services, manages the global state machine (idle, booting, ready, error, shuttingDown), and provides a health check for the platform.
- **Dependencies**: `SDKEnvironment`, `ServiceContainer`, `SDKDataStore`, `SDKEventBus`, `SDKRouter`, `SDKPermissionManager`, `PluginRuntimeEngine`, feature services.
- **Inputs/Outputs**: `boot()` and `shutdown()` are async entry points. `healthCheck()` returns a `KernelHealth` report.
- **Interaction**: Orchestrates the sequential startup of all subsystems.

### Sources/Core/SDK/Kernel/SDKContext.swift
- **Purpose**: Runtime execution context carrying request-scoped metadata and permissions.
- **Responsibilities**: Tracks execution lineage, permission inheritance, and carried metadata through the pipeline.
- **Dependencies**: `ContextScope` enum.
- **Inputs/Outputs**: Context objects with metadata and permission sets.
- **Interaction**: Passed through the execution engine and router to ensure governed access.

### Sources/Core/SDK/Kernel/SDKEnvironment.swift
- **Purpose**: Global configuration and feature flag management.
- **Responsibilities**: Manages `SDKConfiguration` (version, build, logging, sandbox settings) and feature flags.
- **Dependencies**: `UserDefaults` for persistence.
- **Inputs/Outputs**: Configuration snapshots and toggleable feature flags.
- **Interaction**: Loaded by the Kernel during boot.

### Sources/Core/SDK/WorkspaceSDK.swift
- **Purpose**: The primary unified public interface for the entire SDK platform.
- **Responsibilities**: Provides static shared access to Mail, Notebooks, Meet, Articles, Plugins, Storage, Events, Router, and Security.
- **Dependencies**: All major SDK managers and engines.
- **Inputs/Outputs**: Public methods for `initialize()`, `shutdown()`, `api()`, and data/event shortcuts.
- **Interaction**: The main entry point for any SDK consumer (internal or external).

### Sources/Core/SDK/ToolsKitSDK.swift
- **Purpose**: Central orchestrator and bridge for governed data and execution operations.
- **Responsibilities**: Bridges legacy and modern SDK calls, enforces policy governance on every operation, manages data fetching/writing, and coordinates external sync.
- **Dependencies**: `SDKDataEngine`, `SDKScopeManager`, `SDKEventBridge`, `SDKExecutionEngine`, `SDKSecurityManager`, `SDKPolicyEngine`, `SDKAuditLogger`.
- **Inputs/Outputs**: Governed API methods for data access, AI operations, automation triggers, and external connections.
- **Interaction**: Routes every call through `runGovernedCall` for policy enforcement.

### Sources/Core/SDK/SDKProjectManager.swift
- **Purpose**: Persistent management of SDK projects and configurations.
- **Responsibilities**: Handles project CRUD, duplication, health status tracking, and automation rule persistence.
- **Dependencies**: `SDKProject` model, `WorkspacePersistence`.
- **Inputs/Outputs**: Active `currentProject` binding and a collection of all projects.
- **Interaction**: Synchronizes project state with `SDKRuntimeWorkspaceState`.

### Sources/Core/SDK/SDKIDEWorkspaceState.swift
- **Purpose**: UI state manager for the SDK Developer Tools and IDE views.
- **Responsibilities**: Manages the IDE navigator tree, open tabs, active diagnostics, library/dependency graphs, and run configurations.
- **Dependencies**: `SDKWorkspaceNode`, `SDKLibraryDefinition`, `SDKDependencyNode`.
- **Inputs/Outputs**: Recalculated diagnostics and reactive layout parameters.
- **Interaction**: Drives the `SDKWorkspaceContainerView` and all Editor subviews.

### Sources/Core/SDK/DI/ServiceRegistry.swift
- **Purpose**: Protocol-based service registry for dependency injection.
- **Responsibilities**: Manages service factories and singleton instances mapped to protocol types.
- **Dependencies**: `ServiceScope` (singleton, transient, scoped).
- **Inputs/Outputs**: Resolved service instances.
- **Interaction**: The underlying engine for the `@ServiceInjected` property wrapper.

### Sources/Core/SDK/DI/ServiceContainer.swift
- **Purpose**: High-level DI container for SDK-wide service resolution.
- **Responsibilities**: Provides default registration of all core SDK services.
- **Dependencies**: `ServiceRegistry`.
- **Inputs/Outputs**: Convenient registration and resolution methods.
- **Interaction**: Called by the Kernel to register system defaults.

### Sources/Core/SDK/DI/ServiceInjected.swift
- **Purpose**: Property wrapper for lazy dependency resolution.
- **Responsibilities**: Resolves services from the `ServiceRegistry` when accessed.
- **Dependencies**: `ServiceRegistry`.
- **Interaction**: Used across the SDK to decouple components.

### Sources/Core/SDK/Data/SDKDataStore.swift
- **Purpose**: Unified offline-first data persistence layer.
- **Responsibilities**: Manages file-based JSON storage, indexing, and versioning for all `SDKModel` types.
- **Dependencies**: `FileManager`, `SDKModel`.
- **Inputs/Outputs**: CRUD operations, batch operations, and index-based queries.
- **Interaction**: Consumed by all feature services (Mail, Notebooks, etc.) for persistence.

### Sources/Core/SDK/Data/SDKModel.swift
- **Purpose**: Base protocol and standard models for SDK-persistable data.
- **Responsibilities**: Defines the `SDKModel` requirements and provides concrete models for Mail, Notebooks, Meet, Articles, and Apps.
- **Dependencies**: `Foundation`.
- **Interaction**: The foundation for all data passing through the `SDKDataStore`.

### Sources/Core/SDK/Events/SDKEventBus.swift
- **Purpose**: Unified pub/sub system for real-time inter-module communication.
- **Responsibilities**: Manages event channels, subscriptions, history persistence, and bridging to legacy event systems.
- **Dependencies**: `SDKBusEvent`, `Combine`.
- **Inputs/Outputs**: Async event streams and filtered subscriptions.
- **Interaction**: The central nervous system for state updates and triggers.

### Sources/Core/SDK/Automation/SDKAutomationEngine.swift
- **Purpose**: Execution engine for trigger-condition-action automation rules.
- **Responsibilities**: Evaluates events against active rules and executes actions (tools, notifications, syncs, exports).
- **Dependencies**: `SDKAutomationRule`, `SDKToolManager`, `SDKConnectorManager`.
- **Inputs/Outputs**: Rule evaluation triggers and action results.
- **Interaction**: Connected to `SDKProjectManager` for rule storage.

### Sources/Core/SDK/Modules/SDKModuleRegistry.swift
- **Purpose**: Dynamic registry for capability-based SDK modules.
- **Responsibilities**: Manages module registration, activation sequence (ordered by load priority), and dependency checks.
- **Dependencies**: `SDKModuleDescriptor`, `SDKModuleProvider`.
- **Inputs/Outputs**: Active module IDs and resolved load order.
- **Interaction**: Validates module compatibility before activation.

### Sources/Core/SDK/Modules/SDKDependencyGraph.swift
- **Purpose**: Dependency resolution and conflict detection engine.
- **Responsibilities**: Performs topological sorting, cycle detection, and identifies capability collisions.
- **Dependencies**: `SDKModuleDescriptor`.
- **Inputs/Outputs**: `SDKDependencyResolution` reports.
- **Interaction**: Used by the `SDKModuleRegistry` to ensure safe loading.

### Sources/Core/SDK/Modules/SDKFeatureExposure.swift
- **Purpose**: Discovery and invocation system for cross-module features.
- **Responsibilities**: Allows modules to expose typed features (parameters/outputs) and handles their execution.
- **Dependencies**: `SDKExposedFeature`, `SDKEventBus`.
- **Interaction**: Provides a dynamic way for modules to interact without hard dependencies.

### Sources/Core/SDK/Router/SDKRouter.swift
- **Purpose**: On-device internal API routing system.
- **Responsibilities**: Maps HTTP-like paths and methods to internal service handlers.
- **Dependencies**: `SDKRoute`, `SDKRequest`, `SDKResponse`.
- **Inputs/Outputs**: Async handling of `SDKRequest` returning `SDKResponse`.
- **Interaction**: Serves as the internal gateway for the `api()` methods in `WorkspaceSDK`.

### Sources/Core/SDK/Router/SDKRequest.swift
- **Purpose**: Structured request object for the API router.
- **Responsibilities**: Encapsulates path, method, parameters, body, and context.
- **Dependencies**: `SDKContext`.
- **Interaction**: Created by consumers to call SDK endpoints.

### Sources/Core/SDK/Router/SDKResponse.swift
- **Purpose**: Structured response object for the API router.
- **Responsibilities**: Encapsulates status, data, errors, and latency metrics.
- **Dependencies**: `Foundation`.
- **Interaction**: Returned by handlers to complete API calls.

### Sources/Core/SDK/Security/SDKSecurityManager.swift
- **Purpose**: Primary enforcer of SDK permission boundaries.
- **Responsibilities**: Manages app-specific permissions, denied scopes, API key usage, and records sensitive operations.
- **Dependencies**: `SDKPermissionManager`, `SDKPolicyRequest`.
- **Interaction**: Core component of the governed execution pipeline.

### Sources/Core/SDK/Security/SDKPrivacyManager.swift
- **Purpose**: Data privacy and redaction system.
- **Responsibilities**: Automatically redacts restricted fields from payloads based on scope policy and logs data exposure.
- **Dependencies**: `PrivacyPolicy` definitions.
- **Interaction**: Processes all data returned through `ToolsKitSDK` governed calls.

### Sources/Core/SDK/Security/SDKRateLimiter.swift
- **Purpose**: Throttling and resource usage enforcement.
- **Responsibilities**: Implements token bucket rate limiting for requests, data fetch limits, and execution frequency caps.
- **Dependencies**: `SDKRateLimiter.Rule`.
- **Interaction**: Enforces limits on every governed call in the pipeline.

### Sources/Core/SDK/Security/SDKAuditLogger.swift
- **Purpose**: Persistent auditing system for SDK operations.
- **Responsibilities**: Logs all data access, scope usage, API calls, and security events.
- **Dependencies**: `WorkspacePersistence`.
- **Interaction**: Provides the audit trail for security monitoring and compliance.

### Sources/Core/SDK/Security/SDKPolicyEngine.swift
- **Purpose**: Governance policy evaluator for SDK scopes.
- **Responsibilities**: Defines scope risk levels, justification requirements, and maps risk levels to rate limit rules.
- **Dependencies**: `SDKSecurityScopeDefinition`, `SDKPrivacyManager`.
- **Interaction**: Determines the execution parameters for a given request.

### Sources/Core/SDK/Connectors/BaseConnector.swift
- **Purpose**: Protocol defining the requirements for external service connectors.
- **Responsibilities**: Defines interface for authentication, synchronization, health testing, and logging.
- **Dependencies**: `ConnectorType`, `ConnectorStatus`.
- **Interaction**: The foundation for all external service integrations.

### Sources/Core/SDK/Connectors/SDKConnectorManager.swift
- **Purpose**: Management of registered connector instances.
- **Responsibilities**: Handles connector registration, removal, and coordinated synchronization.
- **Dependencies**: `BaseConnector`, `SDKProjectManager`.
- **Interaction**: Synchronizes connected state with the active SDK project.

### Sources/Core/SDK/Connectors/SDKConnectorRuntime.swift
- **Purpose**: Binding system for connectors and SDK modules.
- **Responsibilities**: Manages `ConnectorBinding` (dataSource, dataSink, etc.) and live data streaming from connectors.
- **Dependencies**: `ConnectorBinding`, `SDKEventBus`.
- **Interaction**: Allows declarative data flow between external systems and internal modules.

### Sources/Core/SDK/Connectors/GmailConnector.swift
- **Purpose**: OAuth2-based Gmail integration.
- **Responsibilities**: Handles authentication, message sync, and health checks for Google Mail.
- **Dependencies**: `AuthenticationServices`.
- **Interaction**: Bridges external email data into the SDK.

### Sources/Core/SDK/Connectors/GitHubConnector.swift
- **Purpose**: PAT-based GitHub repository integration.
- **Responsibilities**: Manages repository sync and authentication validation.
- **Dependencies**: `SDKNetworkManager`.
- **Interaction**: Integrates external source control metadata.

### Sources/Core/SDK/Connectors/WebhookConnector.swift
- **Purpose**: Generic HTTP Webhook connector.
- **Responsibilities**: Executes outbound POST requests and manages API key auth.
- **Dependencies**: `Foundation`.
- **Interaction**: Used for event-driven outbound integrations.

### Sources/Core/SDK/Connectors/CalendarConnector.swift
- **Purpose**: EventKit-based local calendar integration.
- **Responsibilities**: Syncs events from the host device's calendar.
- **Dependencies**: `EventKit`.
- **Interaction**: Bridges local OS data into the SDK.

### Sources/Core/SDK/Connectors/LocalFileConnector.swift
- **Purpose**: Sandbox-based file system connector.
- **Responsibilities**: Scans and manages data in the local app documents directory.
- **Dependencies**: `FileManager`.
- **Interaction**: Provides local storage bridging.

### Sources/Core/SDK/Tools/SDKToolManager.swift
- **Purpose**: Registry and execution manager for atomic SDK tools.
- **Responsibilities**: Manages tool registration (JSON Formatter, Summarizer, etc.) and input validation.
- **Dependencies**: `SDKTool`, `SDKToolResult`.
- **Interaction**: Provides tools for automation actions and plugin execution.

### Sources/Core/SDK/Runtime/SDKAppRuntime.swift
- **Purpose**: Execution environment for full-lifecycle SDK applications.
- **Responsibilities**: Manages app registration, start/stop sequences, and lifecycle handler routing.
- **Dependencies**: `SDKAppDefinition`, `SDKAppLifecycle`.
- **Interaction**: The main runtime for "SDK Apps" (apps with logic/UI).

### Sources/Core/SDK/Plugins/SDKPluginManager.swift
- **Purpose**: Management of tool-based SDK plugins.
- **Responsibilities**: Handles plugin installation, enablement, and automation hook execution.
- **Dependencies**: `SDKPlugin`, `SDKToolManager`.
- **Interaction**: Triggers tool execution when automation hooks are fired.

### Sources/Core/SDK/Plugins/SDKPluginLifecycle.swift
- **Purpose**: Advanced lifecycle management for complex plugins.
- **Responsibilities**: Manages transition between phases (loading, active, paused, errored, etc.).
- **Dependencies**: `SDKPluginManifest`, `SDKPluginPhase`.
- **Interaction**: Emits lifecycle events on the `SDKEventBus`.

### Sources/Core/SDK/Features/Mail/SDKMailService.swift
- **Purpose**: High-level Mail service providing email business logic.
- **Responsibilities**: Handles sending, threading, indexing, and searching messages.
- **Dependencies**: `SDKDataStore`, `MailSMTPService`, `SDKEventBus`.
- **Interaction**: Bridges SDK calls to host Mail systems while maintaining an independent local store.

### Sources/Core/SDK/Features/Notebooks/SDKNotebookService.swift
- **Purpose**: Document management service for notebooks and pages.
- **Responsibilities**: Manages notebook CRUD, page version history, and pinning.
- **Dependencies**: `SDKDataStore`, `NotebooksManager`.
- **Interaction**: Synchronizes local notebook data with the host application.

### Sources/Core/SDK/Features/Meet/SDKMeetService.swift
- **Purpose**: Session management for virtual meetings.
- **Responsibilities**: Handles session creation, status tracking, presence mapping, and room URL generation.
- **Dependencies**: `SDKDataStore`, `DailyService`.
- **Interaction**: Bridges to meeting providers for real-time collaboration.

### Sources/Core/SDK/Features/Articles/SDKArticleService.swift
- **Purpose**: Content publishing and parsing service.
- **Responsibilities**: Manages article creation, publishing state, and content metadata (word count, read time).
- **Dependencies**: `SDKDataStore`, `ArticlesManager`.
- **Interaction**: Provides article management for the SDK.

### Sources/Core/SDK/SDKExecutionEngine.swift
- **Purpose**: Low-level execution runner for governed operations.
- **Responsibilities**: Tracks active executions, manages concurrency, handles retries, and records history.
- **Dependencies**: `SDKAuditLogger`, `SDKExecutionKernel`.
- **Interaction**: The final layer before operations reach target systems.

### Sources/Core/SDK/SDKDataEngine.swift
- **Purpose**: Workspace-aware data abstraction layer.
- **Responsibilities**: Provides scoped data fetching, writing, and deletion across all workspace entities.
- **Dependencies**: `WorkspaceAPI`, `SDKDataStore`, `SDKCacheInfo`.
- **Interaction**: Acts as the data bridge between the SDK and host application systems.

### Sources/Core/SDK/SDKEventBridge.swift
- **Purpose**: Event compatibility and persistence bridge.
- **Responsibilities**: Bridges events between `SDKEventBus` and legacy systems, maintains historical audit of all events.
- **Dependencies**: `SDKEventSystem`, `Combine`.
- **Interaction**: Ensures event parity across different architectural generations.

### Sources/Core/SDK/SDKStorageManager.swift
- **Purpose**: Key-value and secure storage management.
- **Responsibilities**: Provides access to simple local storage (JSON-based) and secure storage (Keychain-based).
- **Dependencies**: `Security` framework.
- **Interaction**: Used for credentials and persistent configuration flags.

### Sources/Core/SDK/SDKLogStore.swift
- **Purpose**: Unified logging system for all SDK components.
- **Responsibilities**: Collects, persists, and provides filtered access to system logs.
- **Dependencies**: `LogLevel`, `FileManager`.
- **Interaction**: Accessible globally to provide an audit trail for development and diagnostics.

### Sources/Core/SDK/SDKRealtimeSync.swift
- **Purpose**: Real-time channel-based data synchronization.
- **Responsibilities**: Manages channel subscriptions and data broadcasting for collaborative features.
- **Dependencies**: `PassthroughSubject`, `SDKEventBridge`.
- **Interaction**: Notifies subscribers of "ticks" on active channels.

### Sources/Core/SDK/SDKLibraryVersionResolver.swift
- **Purpose**: Semantic versioning and resolution logic.
- **Responsibilities**: Compares versions and identifies preferred module versions based on availability.
- **Dependencies**: `Foundation`.
- **Interaction**: Used by the Library Manager for update tracking.

### Sources/Core/SDK/SDKDependencyExecutionPlanner.swift
- **Purpose**: Graph-based execution ordering.
- **Responsibilities**: Resolves the correct sequence for module loading using topological sorting and cycle detection.
- **Dependencies**: `SDKDependencyNode`.
- **Interaction**: Consumed by the `SDKExecutionCoordinator`.

### Sources/Core/SDK/SDKDependencyScopeValidator.swift
- **Purpose**: Security validation for dependency trees.
- **Responsibilities**: Ensures all modules in an execution plan have their required scopes authorized.
- **Dependencies**: `SDKDependencyNode`.
- **Interaction**: A guard check before starting SDK execution.

### Sources/Core/SDK/SDKCoreDataStack.swift
- **Purpose**: CoreData persistence for system-level SDK structures.
- **Responsibilities**: Manages the persistent container and context for SDK managed objects.
- **Dependencies**: `CoreData`.
- **Interaction**: Used for structured system-level data persistence.

### Sources/Core/SDK/SDKLibraryExecutionEngine.swift
- **Purpose**: Runtime executor for SDK Library exports.
- **Responsibilities**: Binds scopes and executes library functions within the governed pipeline.
- **Dependencies**: `SDKLibraryScopeBinder`.
- **Interaction**: Executes functions defined in `SDKLibraryDefinition`.

### Sources/Core/SDK/SDKScopeManager.swift
- **Purpose**: Scope authorization and audit tracking.
- **Responsibilities**: Manages the set of authorized scopes and provides a dedicated audit log for permission checks.
- **Dependencies**: `SDKRuntimeEngine`, `SDKLogStore`.
- **Interaction**: Used by the `governedCall` logic to validate access.

### Sources/Core/SDK/SDKBackgroundEngine.swift
- **Purpose**: System health monitoring and background tasks.
- **Responsibilities**: Runs health check loops, schedules background sync tasks, and manages retries for failed operations.
- **Dependencies**: `BackgroundTasks`, `SDKConnectorManager`.
- **Interaction**: Updates the global `SDKHealthReport`.

### Sources/Core/SDK/SDKConnectorEngine.swift
- **Purpose**: External connector health and sync orchestrator.
- **Responsibilities**: Manages background sync timers, retry logic, and health checks specifically for connectors.
- **Dependencies**: `SDKConnectorManager`, `SDKRateLimiter`.
- **Interaction**: Coordinates external data flows.

### Sources/Core/SDK/SDKLibraryDependencyBridge.swift
- **Purpose**: Mapping between libraries and dependency nodes.
- **Responsibilities**: Converts library definitions into dependency graph nodes with appropriate hooks and scopes.
- **Dependencies**: `SDKLibraryDefinition`, `SDKDependencyNode`.
- **Interaction**: Bridges the Library system to the Dependency Graph system.

### Sources/Core/SDK/SDKExportService.swift
- **Purpose**: Project packaging and archiving system.
- **Responsibilities**: Compiles project assets (plugins, tools, rules) into a versioned `.sdkbundle` zip file.
- **Dependencies**: `Compression`, `SDKExportConfig`.
- **Interaction**: Consumed by Build views for project distribution.

### Sources/Core/SDK/SDKExecutionCoordinator.swift
- **Purpose**: High-level runtime orchestration.
- **Responsibilities**: Validates the selected run configuration, plans the dependency order, and executes all required libraries.
- **Dependencies**: `SDKDependencyExecutionPlanner`, `SDKLibraryExecutionEngine`.
- **Interaction**: The entry point for the "Run" command in the SDK IDE.

### Sources/Core/SDK/SDKLibraryScopeBinder.swift
- **Purpose**: Scope aggregation for library execution.
- **Responsibilities**: Calculates effective scopes by combining project, plugin, and library requirements.
- **Dependencies**: `SDKLibraryDefinition`.
- **Interaction**: Ensures libraries operate within a strictly defined permission boundary.

### Sources/Core/SDK/SDKPersonaBridge.swift
- **Purpose**: SDK interface for AI Persona operations.
- **Responsibilities**: Handles AI generation, analysis, summarization, and memory injection calls.
- **Dependencies**: `WorkspaceAPI`, `SDKExecutionKernel`.
- **Interaction**: Bridges ToolsKitSDK calls to the AI system.

### Sources/Core/SDK/SDKToolRuntime.swift
- **Purpose**: Runtime execution and history for SDK tools.
- **Responsibilities**: Executes tools and maintains a localized history of tool results.
- **Dependencies**: `SDKToolManager`.
- **Interaction**: Provides metrics for tool execution.

### Sources/Core/SDK/SDKStructureValidator.swift
- **Purpose**: Integrity validation for SDK structures.
- **Responsibilities**: Detects duplicate modules, invalid references, and circular chains in the SDK graph.
- **Dependencies**: `SDKDependencyExecutionPlanner`.
- **Interaction**: Used during the build/validation pipeline.

### Sources/Core/SDK/SDKTimeTravelBridge.swift
- **Purpose**: SDK interface for Workspace snapshots.
- **Responsibilities**: Manages history, restoration, and diffing of workspace snapshots.
- **Dependencies**: `WorkspaceAPI`.
- **Interaction**: Bridges ToolsKitSDK calls to the Time Travel system.

### Sources/Core/SDK/SDKDependencyConflictResolver.swift
- **Purpose**: Conflict detection and suggestion system.
- **Responsibilities**: Identifies version mismatches and provides resolution suggestions for the dependency graph.
- **Dependencies**: `SDKDependencyNode`.
- **Interaction**: Drives the "Conflict Alerts" UI in Management views.

### Sources/Core/SDK/SDKGraphInterface.swift
- **Purpose**: SDK interface for the Intelligence Graph.
- **Responsibilities**: Queries and modifies the entity relationship graph.
- **Dependencies**: `SDKWorkspaceGraphEngine`, `WorkspaceAPI`.
- **Interaction**: Provides the graph data for the Workspace Explorer.

### Sources/Core/SDK/SDKNetworkManager.swift
- **Purpose**: Robust networking client for the SDK.
- **Responsibilities**: Handles HTTP requests with automatic retries, rate limiting (per-domain), and error handling.
- **Dependencies**: `URLSession`, `SDKLogStore`.
- **Interaction**: Used by connectors and the `externalFetch` API.

---

## 2. System Inventory: Legacy Core (Sources/Core/SDK/Legacy/)

### Sources/Core/SDK/Legacy/WorkspaceAPI.swift
- **Purpose**: Facade providing access to the host application's backend services.
- **Responsibilities**: Maps calls for Notes, Tasks, Mail, Calendar, Files, Slides, Meet, TimeTravel, Persona, and Intelligence to their respective managers.
- **Dependencies**: All host app backend managers (e.g., `NotebooksManager`, `TasksManager`).
- **Interaction**: The primary way the SDK interacts with pre-existing application data.

### Sources/Core/SDK/Legacy/SDKPermissionManager.swift
- **Purpose**: Legacy permission tracking system.
- **Responsibilities**: Handles permission grants and basic scope validation.
- **Dependencies**: `UserDefaults`.
- **Interaction**: Bridged to the modern `SDKSecurityManager`.

### Sources/Core/SDK/Legacy/SDKExecutionKernel.swift
- **Purpose**: Central command router for legacy SDK actions.
- **Responsibilities**: Orchestrates the execution of `SDKAction` enum cases through a sequence of validation, routing, and synchronization.
- **Dependencies**: `SDKSystemRouter`, `SDKActionDispatcher`, `SDKDependencyResolver`, `SDKPermissionGate`.
- **Interaction**: Handles the actual execution of tasks like "sendMail" or "createNote".

### Sources/Core/SDK/Legacy/SDKRuntimeEngine.swift
- **Purpose**: Execution runner for legacy SDK projects.
- **Responsibilities**: Manages the lifecycle of legacy project execution and toggles the `noSandbox` mode.
- **Dependencies**: `SDKSandboxController`, `SDKNoSandboxOverrideController`.
- **Interaction**: Drives the "Run" logic for source-code based projects.

### Sources/Core/SDK/Legacy/SDKSystemRouter.swift
- **Purpose**: Internal routing for legacy system actions.
- **Responsibilities**: Maps `SDKAction` to `SystemAction` categories.
- **Interaction**: Used by the legacy Execution Kernel.

### Sources/Core/SDK/Legacy/SDKExecutionBridge.swift
- **Purpose**: Runtime bridging between SDK projects and Plugin/Connector execution environments.
- **Responsibilities**: Routes code execution to the Sandbox Engine and converts SDK projects into PluginDefinitions for deployment.
- **Dependencies**: `SDKSandboxEngine`.
- **Interaction**: Used by `SDKDeploymentView` to finalize project distribution.

### Sources/Core/SDK/Legacy/SDKSandboxEngine.swift
- **Purpose**: JavaScript-based execution environment.
- **Responsibilities**: Provides a sandboxed JS context where SDK scripts can interact with workspace modules safely.
- **Dependencies**: `JavaScriptCore`.
- **Interaction**: Implements the "workspace" JS bridge.

### Sources/Core/SDK/Legacy/SDKNoSandboxOverrideController.swift
- **Purpose**: Unrestricted execution controller.
- **Responsibilities**: Executes scripts in a context that has direct, non-sandboxed access to system state.
- **Interaction**: Used when `noSandbox` mode is enabled.

### Sources/Core/SDK/Legacy/SDKStateManager.swift
- **Purpose**: Persistence for legacy SDK projects.
- **Responsibilities**: Manages the loading and saving of `SDKProjectLegacy` objects.
- **Dependencies**: `FileManager`.
- **Interaction**: Provides the project list for legacy views.

### Sources/Core/SDK/Legacy/SDKWorkspaceGraphEngine.swift
- **Purpose**: Local graph engine for workspace entities.
- **Responsibilities**: Maintains a relationship graph between tasks, notes, and decks.
- **Dependencies**: `WorkspaceAPI`.
- **Interaction**: Drives the legacy intelligence features.

### Sources/Core/SDK/Legacy/SDKActionDispatcher.swift
- **Purpose**: Dispatches system actions to target handlers.
- **Responsibilities**: Executes concrete tasks (create, delete, etc.) in response to system actions.
- **Interaction**: Final step in the legacy execution chain.

### Sources/Core/SDK/Legacy/SDKTelemetryEngine.swift
- **Purpose**: Performance and execution tracking.
- **Responsibilities**: Records traces for operations, calculates latency, and tracks success/failure rates.
- **Interaction**: Provides the data for the Telemetry UI.

### Sources/Core/SDK/Legacy/SDKEventInjectionEngine.swift
- **Purpose**: Legacy event broadcaster.
- **Responsibilities**: Broadcasts system events after actions complete.
- **Interaction**: Bridged to the modern `SDKEventBus`.

### Sources/Core/SDK/Legacy/SDKStateSynchronizer.swift
- **Purpose**: Real-time state synchronization notifier.
- **Responsibilities**: Emits notifications when workspace state changes due to SDK actions.
- **Interaction**: Keeps UI components in sync with data changes.

### Sources/Core/SDK/Legacy/SDKDependencyResolver.swift
- **Purpose**: Basic dependency validation for actions.
- **Responsibilities**: Validates that required systems are available for a given action.
- **Interaction**: Part of the legacy execution pipeline.

### Sources/Core/SDK/Legacy/SDKWorkspaceBridge.swift
- **Purpose**: High-power system state bridge.
- **Responsibilities**: Provides direct access to live system metrics (counts of entities).
- **Interaction**: Used in unrestricted execution mode.

### Sources/Core/SDK/Legacy/SDKPermissionGate.swift
- **Purpose**: Legacy permission enforcement.
- **Responsibilities**: Blocks actions if permissions are not authorized.
- **Interaction**: Security layer for the legacy kernel.

### Sources/Core/SDK/Legacy/SDKSandboxController.swift
- **Purpose**: Controller for sandboxed script execution.
- **Responsibilities**: Directs the `SDKSandboxEngine` to run scripts within an execution context.
- **Interaction**: Orchestrates the JS runtime.

### Sources/Core/SDK/Legacy/SDKMutationEngine.swift
- **Purpose**: Change tracking and application.
- **Responsibilities**: Logs and applies mutations to workspace data.
- **Interaction**: Provides an audit of state changes.

### Sources/Core/SDK/Legacy/SDKEventSystem.swift
- **Purpose**: Foundation for legacy event handling.
- **Responsibilities**: Simple pub/sub for system events.
- **Interaction**: Replaced by `SDKEventBus` but maintained for compatibility.

---

## 3. System Inventory: SDK UI (Sources/Views/Workspace/SDK/)

### Sources/Views/Workspace/SDK/Main/SDKHomeView.swift
- **Purpose**: Primary dashboard for the SDK Developer Platform.
- **Responsibilities**: Provides navigation to Build, Editor, Diagnostics, and internal tools. Displays the SDK project registry.
- **Dependencies**: `SDKProjectManager`, `SDKBuildView`, `SDKWorkspaceContainerView`.
- **Interaction**: The top-level entry point for the SDK UI.

### Sources/Views/Workspace/SDK/Main/SDKProjectDashboardView.swift
- **Purpose**: Centralized command hub for an active SDK project.
- **Responsibilities**: Displays project metadata, health status, and provides navigation to all functional areas (Connectors, Automation, IDE).
- **Dependencies**: `SDKProjectManager`, `SDKConnectorManager`, `SDKAutomationEngine`, `SDKLogStore`.
- **Interaction**: Uses `NavigationStack` with custom routing.

### Sources/Views/Workspace/SDK/Main/SDKWorkspaceContainerView.swift
- **Purpose**: Multi-panel, IDE-style container for SDK development.
- **Responsibilities**: Implements a responsive layout (Navigator, Editor, Inspector, Console) for iOS. Handles "Run" command orchestration.
- **Dependencies**: `SDKRuntimeWorkspaceState`, `SDKExecutionCoordinator`.
- **Interaction**: Provides the desktop-class development environment on mobile.

### Sources/Views/Workspace/SDK/Main/SDKControlCenterView.swift
- **Purpose**: Real-time monitor for the SDK system.
- **Responsibilities**: Displays system health metrics, active projects, performance telemetry, and realtime sync status.
- **Dependencies**: `SDKBackgroundEngine`, `SDKTelemetryEngine`, `SDKRealtimeSync`.
- **Interaction**: Used for monitoring system integrity and performance.

### Sources/Views/Workspace/SDK/Main/SDKPluginsView.swift
- **Purpose**: User-facing catalog and manager for plugins.
- **Responsibilities**: Allows browsing, installing, and toggling of tool-based plugins.
- **Dependencies**: `SDKPluginManager`.
- **Interaction**: Manages the expansion of workspace capabilities via plugins.

### Sources/Views/Workspace/SDK/Main/SDKInternalView.swift
- **Purpose**: Developer utility for deep system inspection.
- **Responsibilities**: Provides raw data exploration, endpoint testing, rate limit monitoring, and privacy log inspection.
- **Dependencies**: `SDKAuditLogger`, `SDKPrivacyManager`, `ToolsKitSDK`.
- **Interaction**: The "hidden" utility view for system debugging.

### Sources/Views/Workspace/SDK/Editor/SDKProjectEditorView.swift
- **Purpose**: Multi-tab workspace editor.
- **Responsibilities**: Routes navigation to specialized views based on the active tab (Config, Scopes, Libraries, etc.). Displays diagnostic alerts.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: The central editing area in the IDE layout.

### Sources/Views/Workspace/SDK/Editor/SDKNavigatorView.swift
- **Purpose**: Vertical tree navigation for project areas.
- **Responsibilities**: Displays functional nodes (Config, Connectors, Scopes) and system status indicators.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Drives tab opening in the Editor view.

### Sources/Views/Workspace/SDK/Editor/SDKInspectorPanelView.swift
- **Purpose**: Contextual property and JSON inspector.
- **Responsibilities**: Displays metadata for the active context and provides a raw JSON editor for state manipulation.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Provides detail-level editing for SDK components.

### Sources/Views/Workspace/SDK/Editor/SDKConsoleView.swift
- **Purpose**: System-wide event and log console.
- **Responsibilities**: Provides filtered log access, runtime hints based on diagnostics, and memory usage metrics.
- **Dependencies**: `SDKLogStore`, `SDKRuntimeWorkspaceState`.
- **Interaction**: Real-time feedback for SDK execution.

### Sources/Views/Workspace/SDK/Editor/IDEConfigView.swift
- **Purpose**: Project identity and profile editor.
- **Responsibilities**: Edits name, description, and status. Displays the runtime profile and syncs project with graph.
- **Dependencies**: `SDKProjectManager`, `SDKRuntimeWorkspaceState`.
- **Interaction**: Configures the base `SDKProject`.

### Sources/Views/Workspace/SDK/Editor/IDECapabilitiesView.swift
- **Purpose**: Capability matrix editor.
- **Responsibilities**: Displays the status of SDK features based on authorized scopes.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: visualizes the impact of scope grants.

### Sources/Views/Workspace/SDK/Editor/IDEScopesView.swift
- **Purpose**: Hierarchical scope permission manager.
- **Responsibilities**: Manages scope grants, displays risk levels, and provides auto-resolution for missing scopes.
- **Dependencies**: `SDKRuntimeWorkspaceState`, `SDKProjectManager`.
- **Interaction**: The main security configuration interface.

### Sources/Views/Workspace/SDK/Editor/IDELibrariesView.swift
- **Purpose**: Library registry and update manager.
- **Responsibilities**: Handles library installation, version bumping, and dependency resolution state.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Manages the collection of shared module libraries.

### Sources/Views/Workspace/SDK/Editor/IDEDependenciesView.swift
- **Purpose**: Dependency graph manager.
- **Responsibilities**: visualizes nodes, handles installation/removal of dependencies, and displays conflict alerts.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Edits the `SDKDependencyNode` collection.

### Sources/Views/Workspace/SDK/Editor/IDEConnectorsView.swift
- **Purpose**: Connector integration dashboard.
- **Responsibilities**: Displays the status of registered connectors and their links to dependency nodes.
- **Dependencies**: `SDKConnectorManager`, `SDKRuntimeWorkspaceState`.
- **Interaction**: View-only registry of active connectors in the IDE.

### Sources/Views/Workspace/SDK/Editor/IDERuntimeScriptsView.swift
- **Purpose**: visual workflow editor for the SDK.
- **Responsibilities**: Wraps the `SDKFlowBuilderView` for project-level scripting.
- **Dependencies**: `SDKProjectManager`.
- **Interaction**: Allows visual construction of SDK logic.

### Sources/Views/Workspace/SDK/Editor/IDEAPIEndpointsView.swift
- **Purpose**: API Explorer integration for the IDE.
- **Responsibilities**: Embeds the `SDKAPIExplorerView`.
- **Interaction**: Diagnostic interface for internal API routes.

### Sources/Views/Workspace/SDK/Editor/IDEDiagnosticsView.swift
- **Purpose**: Detailed runtime diagnostic report.
- **Responsibilities**: Lists active issues with jump-to-fix capability and auto-resolution options.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Central hub for resolving system errors.

### Sources/Views/Workspace/SDK/Editor/SDKScopesEditorView.swift
- **Purpose**: Wrapper for the IDEScopesView.
- **Interaction**: Standardized editor entry point.

### Sources/Views/Workspace/SDK/Editor/SDKRunConfigurationView.swift
- **Purpose**: Runner profile manager.
- **Responsibilities**: Edits execution modes (sandbox, production, noSandbox) and scoped execution parameters.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Defines how the "Run" command behaves.

### Sources/Views/Workspace/SDK/Editor/SDKToolsView.swift
- **Purpose**: Interactive tool runner.
- **Responsibilities**: Browses available tools and provides a specialized UI for executing them with inputs.
- **Dependencies**: `SDKToolManager`.
- **Interaction**: Direct interaction with the SDK Tool system.

### Sources/Views/Workspace/SDK/Builder/SDKBuildView.swift
- **Purpose**: Primary configuration and export pipeline interface.
- **Responsibilities**: Manages build modes, platform targets, pipeline execution (validation, cache clean, export), and result sharing.
- **Dependencies**: `SDKProjectManager`, `SDKExportService`, `SDKTelemetryEngine`.
- **Interaction**: The central UI for preparing an SDK project for distribution.

### Sources/Views/Workspace/SDK/Builder/SDKAppBuilderView.swift
- **Purpose**: Step-by-step visual configuration for new SDK apps.
- **Responsibilities**: Wizards users through Identity, Scopes, Plugins, Tools, and Connectors to produce an exported bundle.
- **Dependencies**: `SDKAppBuilderViewModel`, `SDKExportService`.
- **Interaction**: Simplified alternative to the full IDE.

### Sources/Views/Workspace/SDK/Builder/SDKFlowBuilderView.swift
- **Purpose**: Infinite canvas visual logic builder.
- **Responsibilities**: Implements a grid-based canvas for placing trigger, condition, and action nodes.
- **Dependencies**: `SDKProject`.
- **Interaction**: provides a visual representation of SDK automation logic.

### Sources/Views/Workspace/SDK/Builder/CustomAppSDKView.swift
- **Purpose**: SDK bundle import and validation utility.
- **Responsibilities**: Simulates/handles zip import, performs structured validation (SDK version, integrity, compatibility), and handles registration.
- **Dependencies**: `ImportedSDKApp`, `ValidationResult`.
- **Interaction**: Gatekeeper for external SDK applications.

### Sources/Views/Workspace/SDK/Builder/SDKDownloadView.swift
- **Purpose**: Versioned SDK distribution manager.
- **Responsibilities**: Provides version selection, changelogs, bundle download simulation, and project export configuration.
- **Dependencies**: `SDKProjectManager`, `SDKExportService`.
- **Interaction**: The source for SDK binaries and project packaging.

### Sources/Views/Workspace/SDK/Management/SDKModuleRegistryView.swift
- **Purpose**: Registry dashboard for capability modules.
- **Responsibilities**: Handles registration, activation/deactivation, and provides a dependency graph visualization.
- **Dependencies**: `SDKModuleRegistry`, `SDKDependencyGraph`.
- **Interaction**: Deep management of the module layer.

### Sources/Views/Workspace/SDK/Management/SDKPluginManagerView.swift
- **Purpose**: Advanced plugin lifecycle manager.
- **Responsibilities**: Edits full app manifests, handles start/stop lifecycle, and displays sandbox/permission status.
- **Dependencies**: `PluginRuntimeEngine`.
- **Interaction**: Detailed management of full-lifecycle SDK applications.

### Sources/Views/Workspace/SDK/Management/SDKLibraryManagerView.swift
- **Purpose**: Modular library registry editor.
- **Responsibilities**: Edits library name, version, and scope bindings. Performs lifecycle analysis.
- **Dependencies**: `SDKRuntimeWorkspaceState`, `SDKLibraryVersionResolver`.
- **Interaction**: Synchronizes libraries with the SDK graph.

### Sources/Views/Workspace/SDK/Management/SDKDependencyManagerView.swift
- **Purpose**: Execution tree node manager.
- **Responsibilities**: Implements drag-and-drop linking between nodes and handles lazy-loading configuration.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: Visual editor for the `SDKDependencyNode` collection.

### Sources/Views/Workspace/SDK/Management/SDKPermissionControlView.swift
- **Purpose**: Rapid permission toggle for projects.
- **Responsibilities**: Provides a checklist of workspace capabilities and elevated privilege controls.
- **Dependencies**: `SDKProject`.
- **Interaction**: Used within the project dashboard for quick security setup.

### Sources/Views/Workspace/SDK/Diagnostics/SDKDiagnosticsView.swift
- **Purpose**: Comprehensive system health dashboard.
- **Responsibilities**: Aggregates metrics from health check, telemetry, cache, plugins, and connectors into visual status panels.
- **Dependencies**: `SDKBackgroundEngine`, `SDKTelemetryEngine`, `SDKConnectorManager`.
- **Interaction**: The primary diagnostic overview for the SDK.

### Sources/Views/Workspace/SDK/Diagnostics/SDKActionConsoleView.swift
- **Purpose**: Command-line terminal for the SDK kernel.
- **Responsibilities**: Implements a terminal UI for executing quick commands (status, flush, sync, etc.) with persistent history.
- **Interaction**: Direct interaction with the SDK kernel logic.

### Sources/Views/Workspace/SDK/Diagnostics/SDKDebugView.swift
- **Purpose**: Host environment and performance inspector.
- **Responsibilities**: Displays physical memory, processor counts, system uptime, and incident logs.
- **Dependencies**: `SDKRuntimeEngine`, `SDKTelemetryEngine`.
- **Interaction**: Debug-level system monitoring.

### Sources/Views/Workspace/SDK/Diagnostics/SDKEventStreamView.swift
- **Purpose**: Real-time event bus monitor.
- **Responsibilities**: Displays a live stream of all events on the `SDKEventBus` with category filtering and pause/resume.
- **Dependencies**: `SDKEventBus`.
- **Interaction**: Real-time observability for system events.

### Sources/Views/Workspace/SDK/Diagnostics/SDKIntegrationTestView.swift
- **Purpose**: Runtime scenario simulation lab.
- **Responsibilities**: Executes pre-defined integration scenarios (Mail Flow, Task Conversion) through the legacy execution kernel.
- **Dependencies**: `SDKExecutionKernel`, `SDKRuntimeEngine`.
- **Interaction**: Verifies end-to-end system integrity.

### Sources/Views/Workspace/SDK/Diagnostics/SDKLogsView.swift
- **Purpose**: System log browser.
- **Responsibilities**: Provides a searchable, level-filtered view of all `SDKLogStore` entries.
- **Dependencies**: `SDKLogStore`.
- **Interaction**: Standard log management interface.

### Sources/Views/Workspace/SDK/Diagnostics/SDKSecurityMonitorView.swift
- **Purpose**: Scope access and security audit browser.
- **Responsibilities**: Displays a real-time audit log of all granted and blocked scope access attempts.
- **Dependencies**: `SDKScopeManager`.
- **Interaction**: Observability for the permission system.

### Sources/Views/Workspace/SDK/Diagnostics/SDKSystemExplorerView.swift
- **Purpose**: Interface and entity navigator.
- **Responsibilities**: Provides navigation to exposed API methods, active entities, and SDK internals.
- **Dependencies**: `WorkspaceAPI`, `SDKRuntimeEngine`.
- **Interaction**: Exploratory tool for system-wide APIs.

### Sources/Views/Workspace/SDK/Explorer/SDKWorkspaceExplorerView.swift
- **Purpose**: Entity relationship graph browser.
- **Responsibilities**: visualizes the intelligence graph with an entity list and relationship inspector.
- **Dependencies**: `SDKWorkspaceGraphEngine`, `WorkspaceAPI`.
- **Interaction**: Navigates the "knowledge graph" of the workspace.

### Sources/Views/Workspace/SDK/Explorer/SDKAPIExplorerView.swift
- **Purpose**: Internal API endpoint tester.
- **Responsibilities**: Browses all registered `SDKRouter` routes and provides a console for testing requests with parameters.
- **Dependencies**: `SDKRouter`.
- **Interaction**: Diagnostic tool for the internal API layer.

### Sources/Views/Workspace/SDK/Explorer/SDKAPIBrowserView.swift
- **Purpose**: Wrapper for the SDKAPIExplorerView.
- **Interaction**: Standardized explorer entry point.

### Sources/Views/Workspace/SDK/Explorer/SDKAutomationView.swift
- **Purpose**: Active automation trigger manager.
- **Responsibilities**: Displays and toggles active automation rules, with a wizard for adding new rules.
- **Dependencies**: `SDKAutomationEngine`.
- **Interaction**: Manages the lifecycle of automated workflows.

### Sources/Views/Workspace/SDK/Explorer/SDKCapabilitiesMatrixView.swift
- **Purpose**: visual feature matrix.
- **Responsibilities**: visualizes the impact of authorized scopes on available features, with detail-level runtime usage metrics.
- **Dependencies**: `SDKRuntimeWorkspaceState`.
- **Interaction**: High-level view of what the SDK can do in the current context.

### Sources/Views/Workspace/SDK/Explorer/SDKDataControlView.swift
- **Purpose**: High-risk system maintenance interface.
- **Responsibilities**: Provides tools for reindexing, cleanup, graph rebuilding, and cache invalidation.
- **Dependencies**: `WorkspaceAPI`, `SDKDataEngine`.
- **Interaction**: Requires explicit user acknowledgement before use.

### Sources/Views/Workspace/SDK/Explorer/SDKDataInspectorView.swift
- **Purpose**: Persistent collection browser.
- **Responsibilities**: Browses all collections in the `SDKDataStore` and provides previews of individual records.
- **Dependencies**: `SDKDataStore`.
- **Interaction**: Direct inspection of the offline-first database.

### Sources/Views/Workspace/SDK/Docs/SDKHelpView.swift
- **Purpose**: AI-driven SDK assistant chat.
- **Responsibilities**: Answers natural language questions using strictly constrained documentation context.
- **Dependencies**: `SDKAIContextProvider`, `AIService`.
- **Interaction**: AI-driven support for SDK developers.

### Sources/Views/Workspace/SDK/Docs/SDKDeveloperGuideView.swift
- **Purpose**: The complete system architecture documentation.
- **Responsibilities**: Provides a multi-category guide covering all SDK systems, definitions, and best practices.
- **Interaction**: The primary reference for SDK architecture.

### Sources/Views/Workspace/SDK/Docs/SDKMarkdownView.swift
- **Purpose**: Native SwiftUI Markdown renderer.
- **Responsibilities**: Parses blocks (headings, code, lists, tables) and inline styles into formatted SwiftUI components.
- **Interaction**: Core rendering component for AI responses and documentation.

### Sources/Views/Workspace/SDK/Docs/SDKAIContextProvider.swift
- **Purpose**: Context management for SDK AI features.
- **Responsibilities**: Loads `SDK_AI_System.md` and constructs constrained system prompts for the Help and Support views.
- **Interaction**: The security gatekeeper for AI context leakage.

### Sources/Views/Workspace/SDK/Docs/SDKSupportView.swift
- **Purpose**: AI-powered application architect.
- **Responsibilities**: Generates SDK-compliant project plans (modules, connectors, plugins) from natural language descriptions.
- **Dependencies**: `SDKAIContextProvider`, `AIService`.
- **Interaction**: High-level AI assistance for project scaffolding.

### Sources/Views/Workspace/SDK/Deployment/SDKDeploymentView.swift
- **Purpose**: Project distribution manager.
- **Responsibilities**: Handles project deployment to plugins or connectors via the bridge system.
- **Dependencies**: `SDKProject`, `SDKExecutionBridge`.
- **Interaction**: Final step in the SDK development lifecycle.

---

## 4. System Architecture Overview

### SDK Architecture
The ToolsKit SDK is built on a **Layered Modular Kernel** architecture. It provides a strictly governed environment for extending the Workspace host application.

1.  **Public API Layer (`WorkspaceSDK`)**: A unified singleton providing simple, protocol-isolated access to all subsystems.
2.  **Orchestration Layer (`ToolsKitSDK`, `SDKExecutionCoordinator`)**: coordinates the execution of operations through security and data layers.
3.  **Security & Governance Layer (`SDKPolicyEngine`, `SDKSecurityManager`, `SDKAuditLogger`)**: A multi-stage pipeline that validates permissions, redacts sensitive data, enforces rate limits, and audits all activities.
4.  **Runtime Layer (`WorkspaceSDKKernel`, `PluginRuntimeEngine`, `SDKRouter`)**: Manages the lifecycle of the system, internal routing, and the execution environments for plugins and apps.
5.  **Service Layer (`SDKMailService`, `SDKNotebookService`, etc.)**: Domain-specific logic that bridges SDK calls to host application systems.
6.  **Persistence Layer (`SDKDataStore`, `SDKStorageManager`)**: provides offline-first, file-based storage with indexing.
7.  **Communication Layer (`SDKEventBus`)**: A unified, persistent messaging system for real-time updates across the platform.

### Module System Behavior
Modules are the building blocks of SDK capability. They are registered with:
-   **Descriptors**: Defining ID, capabilities, dependencies, and priority.
-   **Providers**: Protocol-driven activation and health logic.
-   **Load Priority**: Determines the strict initialization sequence.
-   **Dependency Graph**: Topologically sorted to ensure prerequisites are activated first.

### Plugin System Architecture
The SDK supports two plugin models:
-   **SDKPlugin**: Atomic, tool-based extensions that respond to automation hooks.
-   **SDKAppDefinition**: Full-lifecycle applications that run in sandboxed contexts with manifest-defined permissions and lifecycle handlers (`onStart`, `onStop`).

### Connector System Architecture
Connectors provide a standardized way to integrate external services:
-   **BaseConnector Protocol**: Standardizes auth (OAuth2, API Key, etc.) and sync logic.
-   **Runtime Bindings**: Declaratively link connector data (sources/sinks) to SDK modules.
-   **Managed Sync**: `SDKConnectorEngine` handles background polling, retries, and health checks.

### Dependency and Library System
The SDK uses a directed-graph dependency system:
-   **Libraries**: Reusable packages with exported functions and scope requirements.
-   **Dependency Nodes**: Graph entities that link libraries, plugins, and apps.
-   **Resolution Engine**: detects circularities, version conflicts, and ensures scope authorization before execution.

### Runtime Execution Model
Execution follows a **Governed Call Pattern**:
1.  Request arrives at `ToolsKitSDK`.
2.  `SDKScopeManager` checks for initial grant.
3.  `SDKPolicyEngine` evaluates risk and returns a `SDKRateLimiter.Rule`.
4.  `SDKSecurityManager` enforces app boundaries and API keys.
5.  `SDKPrivacyManager` prepares redaction rules.
6.  `SDKAuditLogger` records the attempt.
7.  The operation executes against the target service or data engine.
8.  Data is redacted and returned to the caller.

### SwiftUI Integration Model
The SDK is designed for **Mobile-First native integration**:
-   **Observable Singletons**: Core managers provide reactive state to views via `@Published`.
-   **NavigationStack Routing**: All feature navigation uses modern SwiftUI routing patterns.
-   **Adaptive UI**: Layouts respond to iOS size classes (Compact/Regular) using `GeometryReader` and `horizontalSizeClass`.
-   **Gesture-Driven**: Drag-and-drop linking, swipe actions, and responsive canvases.

### Lifecycle Flow
1.  **Boot**: Kernel initializes core (DI, Storage, Bus, Router) -> Plugins -> Feature Services.
2.  **Project Load**: `SDKProjectManager` sets current project -> UI synchronizes graph and diagnostics.
3.  **Governance**: User grants scopes via UI -> `SDKScopeManager` persists -> Capabilities matrix updates.
4.  **Execution**: User triggers "Run" or tool -> `SDKExecutionCoordinator` plans graph -> `SDKExecutionEngine` runs governed calls.
5.  **Shutdown**: Bus stops -> Apps stop -> Data flushed -> State reset to idle.
