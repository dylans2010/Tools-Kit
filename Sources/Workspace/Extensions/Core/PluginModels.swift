import Foundation

// MARK: - Plugin Definition

struct PluginDefinition: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var author: String
    var version: String
    var icon: String
    var identifier: String // com.toolskit.<pluginName> (Immutable after creation)
    var isEnabled: Bool = false
    var isInstalled: Bool = false
    var installedAt: Date? = nil
    var lastExecutedAt: Date? = nil
    var errorCount: Int = 0

    var capabilities: [PluginCapability]
    var actions: [PluginAction]
    var sourceCode: String

    // Enhanced Metadata
    var releaseNotes: String?
    var changelog: [PluginChangeLogEntry] = []
    var apiKey: String? // Required for high-risk scopes
    var privacyNote: String? // Developer justification
    var dataUsageExplanation: String?
    var retentionPolicy: String?

    // Advanced Builder Features
    var endpoints: [ExternalAPIEndpoint] = []
    var dataMappings: [DataMapping] = []
    var executionRules: [ExecutionRule] = []
    var uiExtensions: [UIExtension] = []
    var toolkitTools: [PluginToolkitTool] = []

    var permissions: [PluginPermission] {
        capabilities.map { PluginPermission(capability: $0) }
    }
}

struct PluginChangeLogEntry: Codable, Identifiable {
    var id: UUID = UUID()
    let version: String
    let date: Date
    let notes: String
}

struct PluginPermission: Codable, Identifiable {
    var id: String { capability.technicalKey }
    let capability: PluginCapability

    var technicalKey: String { capability.technicalKey }
    var description: String { capability.description }
    var riskLevel: RiskLevel { capability.riskLevel }
    var accessLevel: AccessLevel { capability.accessLevel }
}

enum RiskLevel: String, Codable {
    case low, medium, high, critical
}

enum AccessLevel: String, Codable {
    case read, write, full, selective
}

// MARK: - Capabilities & Actions

enum PluginCapability: String, Codable, CaseIterable, Identifiable {
    // Legacy / Core
    case notes, tasks, mail, calendar, files, whiteboard, slides, media, meet, github, automation, intelligence, collaboration, ai

    // AI Persona
    case aiPersonaQuery = "ai.persona.query"
    case aiPersonaMemoryAccess = "ai.persona.memory.access"
    case aiPersonaWorkspaceAnalysis = "ai.persona.workspace.analysis"
    case aiPersonaBehaviorModel = "ai.persona.behavior.model"

    // Time Travel
    case timeReadHistory = "time.read.history"
    case timeRestoreState = "time.restore.state"
    case timeDiffGenerate = "time.diff.generate"
    case timeTimelineBranch = "time.timeline.branch"

    // Automation (Enhanced)
    case automationCreateWorkflow = "automation.create.workflow"
    case automationModifyWorkflow = "automation.modify.workflow"
    case automationExecuteTrigger = "automation.execute.trigger"
    case automationSimulateRun = "automation.simulate.run"

    // Integrations
    case integrationsConnectService = "integrations.connect.service"
    case integrationsSendEvent = "integrations.send.event"
    case integrationsReceiveWebhook = "integrations.receive.webhook"
    case integrationsPipelineBuild = "integrations.pipeline.build"

    // Intelligence (Enhanced)
    case intelligenceGraphRead = "intelligence.graph.read"
    case intelligenceGraphLink = "intelligence.graph.link"
    case intelligenceSemanticQuery = "intelligence.semantic.query"
    case intelligencePredictNext = "intelligence.predict.next"

    // Slides (Enhanced)
    case slidesGenerateAI = "slides.generate.ai"
    case slidesSyncData = "slides.sync.data"
    case slidesPresentLive = "slides.present.live"

    // External API (New)
    case externalApiConnect = "external.api.connect"
    case externalApiSendRequest = "external.api.send.request"
    case externalApiReceiveResponse = "external.api.receive.response"
    case externalApiSecureHeaders = "external.api.secureHeaders"

    // UI Extensions (New)
    case uiOverlayPresent = "ui.overlay.present"
    case uiPanelInject = "ui.panel.inject"
    case uiCommandbarExtend = "ui.commandbar.extend"
    case uiContextmenuModify = "ui.contextmenu.modify"

    // Specialized
    case workspaceModifySelective = "workspace.modify.selective"
    case mailFetchData = "mail.fetchData"
    case securityFetchData = "security.fetchData"
    case workspaceFetchFullData = "workspace.fetchFullData"

    // Connector Specific (New)
    case connectorApiRead = "connector.api.read"
    case connectorApiWrite = "connector.api.write"
    case connectorDataMap = "connector.data.map"
    case connectorFlowExecute = "connector.flow.execute"
    case connectorAuthManage = "connector.auth.manage"
    case connectorWebhookReceive = "connector.webhook.receive"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aiPersonaQuery: return "AI Persona Query"
        case .aiPersonaMemoryAccess: return "AI Persona Memory"
        case .aiPersonaWorkspaceAnalysis: return "AI Workspace Analysis"
        case .aiPersonaBehaviorModel: return "AI Behavior Modeling"
        case .timeReadHistory: return "Time Travel History"
        case .timeRestoreState: return "Time Travel Restore"
        case .timeDiffGenerate: return "Time Travel Diff"
        case .timeTimelineBranch: return "Time Travel Branching"
        case .automationCreateWorkflow: return "Create Automation"
        case .automationModifyWorkflow: return "Modify Automation"
        case .automationExecuteTrigger: return "Execute Trigger"
        case .automationSimulateRun: return "Simulate Automation"
        case .integrationsConnectService: return "Connect Services"
        case .integrationsSendEvent: return "Send Events"
        case .integrationsReceiveWebhook: return "Receive Webhooks"
        case .integrationsPipelineBuild: return "Build Pipelines"
        case .intelligenceGraphRead: return "Read Knowledge Graph"
        case .intelligenceGraphLink: return "Link Entities"
        case .intelligenceSemanticQuery: return "Semantic Query"
        case .intelligencePredictNext: return "Predict Actions"
        case .slidesGenerateAI: return "AI Slide Generation"
        case .slidesSyncData: return "Live Data Sync"
        case .slidesPresentLive: return "Live Presentation"
        case .externalApiConnect: return "Connect External API"
        case .externalApiSendRequest: return "Send API Requests"
        case .externalApiReceiveResponse: return "Receive API Data"
        case .externalApiSecureHeaders: return "Secure Header Injection"
        case .uiOverlayPresent: return "Show Overlays"
        case .uiPanelInject: return "Inject UI Panels"
        case .uiCommandbarExtend: return "Extend Command Bar"
        case .uiContextmenuModify: return "Modify Context Menus"
        case .workspaceModifySelective: return "Selective Workspace Modification"
        case .mailFetchData: return "Fetch Mail Data"
        case .securityFetchData: return "Fetch Security Data"
        case .workspaceFetchFullData: return "Fetch Full Workspace Data"
        default: return rawValue.capitalized
        }
    }

    var technicalKey: String {
        return rawValue
    }

    var description: String {
        switch self {
        case .notes: return "Read, write, and delete notes."
        case .tasks: return "Manage tasks and completion status."
        case .mail: return "Access and send emails."
        case .calendar: return "Manage calendar events."
        case .files: return "Read and write to workspace files."
        case .whiteboard: return "Read and edit whiteboards."
        case .slides: return "Create and edit presentations."
        case .media: return "Import and edit media assets."
        case .meet: return "Start, join, and read meeting transcripts."
        case .github: return "Access repositories, commits, and PRs."
        case .automation: return "Create and execute workflows."
        case .intelligence: return "Access graph and semantic search."
        case .collaboration: return "Manage sessions and comments."
        case .ai: return "Generate, summarize, and classify with AI."

        case .aiPersonaQuery: return "Queries workspace-trained AI Persona using local data only."
        case .aiPersonaMemoryAccess: return "Reads persistent persona memory derived from workspace activity."
        case .aiPersonaWorkspaceAnalysis: return "Performs deep cross-system analysis across all workspace modules."
        case .aiPersonaBehaviorModel: return "Generates predictive behavioral modeling based on user activity."

        case .timeReadHistory: return "Reads full historical changes across workspace entities."
        case .timeRestoreState: return "Restores system or object state from snapshot."
        case .timeDiffGenerate: return "Generates structured diffs between versions."
        case .timeTimelineBranch: return "Creates alternate workspace timelines for experimentation."

        case .automationCreateWorkflow: return "Creates structured automation pipelines."
        case .automationModifyWorkflow: return "Edits existing workflows."
        case .automationExecuteTrigger: return "Triggers workflows manually or event-based."
        case .automationSimulateRun: return "Simulates execution safely without side effects."

        case .integrationsConnectService: return "Connects external services securely."
        case .integrationsSendEvent: return "Sends workspace events externally."
        case .integrationsReceiveWebhook: return "Receives external system triggers."
        case .integrationsPipelineBuild: return "Builds chained automation pipelines."

        case .intelligenceGraphRead: return "Reads workspace knowledge graph."
        case .intelligenceGraphLink: return "Creates relationships between entities."
        case .intelligenceSemanticQuery: return "Enables natural language querying."
        case .intelligencePredictNext: return "Predicts next user actions or required data."

        case .slidesGenerateAI: return "Generates presentations from workspace data."
        case .slidesSyncData: return "Binds live workspace data to slides."
        case .slidesPresentLive: return "Enables real-time control of presentation flow including navigation, transitions, and live data updates during active presentation sessions."

        case .externalApiConnect: return "Allows plugin to establish a connection with defined endpoint."
        case .externalApiSendRequest: return "Allows sending structured requests."
        case .externalApiReceiveResponse: return "Allows consuming response data inside plugin logic."
        case .externalApiSecureHeaders: return "Allows injecting secure headers dynamically at runtime."

        case .uiOverlayPresent: return "Display floating overlays."
        case .uiPanelInject: return "Inject panels into views."
        case .uiCommandbarExtend: return "Add commands to command bar."
        case .uiContextmenuModify: return "Add options to right-click menus."

        case .workspaceModifySelective: return "Allows controlled modification of specific workspace entities such as notes, tasks, or files without granting full system-wide write access."
        case .mailFetchData: return "Allows retrieval of email data for processing inside sandboxed plugin environment."
        case .securityFetchData: return "Allows access to security logs, authentication events, and audit trails."
        case .workspaceFetchFullData: return "Allows full workspace dataset access excluding Vault and encrypted Mail content."

        case .connectorApiRead: return "Allows reading data from external APIs."
        case .connectorApiWrite: return "Allows sending data to external APIs."
        case .connectorDataMap: return "Enables transformation of API data into workspace structures."
        case .connectorFlowExecute: return "Allows execution of multi-step pipelines."
        case .connectorAuthManage: return "Handles authentication lifecycle."
        case .connectorWebhookReceive: return "Accepts external triggers."
        }
    }

    var riskLevel: RiskLevel {
        switch self {
        case .mailFetchData, .securityFetchData, .workspaceFetchFullData, .workspaceModifySelective: return .high
        case .aiPersonaMemoryAccess, .timeRestoreState, .automationExecuteTrigger, .integrationsConnectService, .externalApiConnect, .externalApiSendRequest, .externalApiSecureHeaders, .connectorFlowExecute, .connectorAuthManage: return .medium
        default: return .low
        }
    }

    var accessLevel: AccessLevel {
        switch self {
        case .mailFetchData, .securityFetchData, .workspaceFetchFullData: return .full
        case .workspaceModifySelective, .uiOverlayPresent, .uiPanelInject, .uiCommandbarExtend, .uiContextmenuModify: return .selective
        case .notes, .tasks, .files, .whiteboard, .slides, .media, .externalApiSendRequest, .connectorApiWrite: return .write
        default: return .read
        }
    }

    var icon: String {
        switch self {
        case .notes: return "note.text"
        case .tasks: return "checkmark.circle"
        case .mail, .mailFetchData: return "envelope"
        case .calendar: return "calendar"
        case .files: return "doc"
        case .whiteboard: return "pencil.and.outline"
        case .slides, .slidesGenerateAI, .slidesSyncData, .slidesPresentLive: return "play.rectangle"
        case .media: return "photo.on.rectangle"
        case .meet: return "video"
        case .github: return "terminal"
        case .automation, .automationCreateWorkflow, .automationModifyWorkflow, .automationExecuteTrigger, .automationSimulateRun: return "gearshape.2"
        case .intelligence, .intelligenceGraphRead, .intelligenceGraphLink, .intelligenceSemanticQuery, .intelligencePredictNext: return "brain"
        case .collaboration: return "person.2"
        case .ai: return "sparkles"
        case .aiPersonaQuery, .aiPersonaMemoryAccess, .aiPersonaWorkspaceAnalysis, .aiPersonaBehaviorModel: return "person.and.sparkles"
        case .timeReadHistory, .timeRestoreState, .timeDiffGenerate, .timeTimelineBranch: return "clock.arrow.circlepath"
        case .integrationsConnectService, .integrationsSendEvent, .integrationsReceiveWebhook, .integrationsPipelineBuild: return "puzzlepiece"
        case .externalApiConnect, .externalApiSendRequest, .externalApiReceiveResponse, .externalApiSecureHeaders: return "network"
        case .uiOverlayPresent, .uiPanelInject, .uiCommandbarExtend, .uiContextmenuModify: return "macwindow"
        case .workspaceModifySelective, .workspaceFetchFullData: return "tray.full"
        case .securityFetchData: return "shield.lefthalf.filled"
        case .connectorApiRead, .connectorApiWrite: return "arrow.up.arrow.down.square"
        case .connectorDataMap: return "arrow.left.arrow.right.square"
        case .connectorFlowExecute: return "arrow.triangle.2.circlepath"
        case .connectorAuthManage: return "key.fill"
        case .connectorWebhookReceive: return "antenna.radiowaves.left.and.right"
        }
    }
}

enum PluginAction: String, Codable, CaseIterable, Identifiable {
    // Notes
    case noteCreated = "note.created"
    case noteUpdated = "note.updated"
    case noteDeleted = "note.deleted"

    // Tasks
    case taskCreated = "task.created"
    case taskCompleted = "task.completed"
    case taskDeleted = "task.deleted"

    // Mail
    case mailReceived = "mail.received"
    case mailSent = "mail.sent"

    // GitHub
    case repoCommitPushed = "repo.commit.pushed"
    case repoPROpened = "repo.pr.opened"
    case repoPRMerged = "repo.pr.merged"

    // Meet
    case meetStarted = "meet.started"
    case meetEnded = "meet.ended"
    case meetTranscriptGenerated = "meet.transcript.generated"

    // Media
    case mediaImported = "media.imported"
    case mediaExported = "media.exported"

    // Calendar
    case calendarEventCreated = "calendar.event.created"
    case calendarEventUpdated = "calendar.event.updated"

    // Files
    case fileUploaded = "file.uploaded"
    case fileDeleted = "file.deleted"

    // Generic
    case workspaceEvent = "workspace.event"

    var id: String { rawValue }

    var parentCapability: PluginCapability {
        switch self {
        case .noteCreated, .noteUpdated, .noteDeleted: return .notes
        case .taskCreated, .taskCompleted, .taskDeleted: return .tasks
        case .mailReceived, .mailSent: return .mail
        case .repoCommitPushed, .repoPROpened, .repoPRMerged: return .github
        case .meetStarted, .meetEnded, .meetTranscriptGenerated: return .meet
        case .mediaImported, .mediaExported: return .media
        case .calendarEventCreated, .calendarEventUpdated: return .calendar
        case .fileUploaded, .fileDeleted: return .files
        case .workspaceEvent: return .intelligence
        }
    }
}

// MARK: - Event Models

struct PluginEvent: Codable, Identifiable {
    let id: UUID
    let capability: PluginCapability
    let action: String
    let payload: [String: String]
    let timestamp: Date
}

// MARK: - Advanced Models

struct ExternalAPIEndpoint: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var baseURL: String
    var path: String
    var method: HTTPMethod
    var headers: [String: String]
    var queryParams: [String: String]
    var bodySchema: String? // JSON Schema
    var authType: AuthType
    var rateLimit: Int? // requests per minute
    var timeout: Int = 30 // seconds
    var retryPolicy: RetryPolicy

    // Security
    var encryptedHeaders: [String] = [] // List of header keys that are encrypted
}

enum HTTPMethod: String, Codable, CaseIterable {
    case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
}

enum AuthType: String, Codable, CaseIterable {
    case none, apiKey, bearer, oauth
}

struct RetryPolicy: Codable {
    var maxRetries: Int = 3
    var backoff: Double = 1.5
}

struct DataMapping: Codable, Identifiable {
    var id: UUID = UUID()
    var sourceField: String // e.g. "event.note.content"
    var targetField: String // e.g. "payload.body.text"
    var transformer: String? // JS transformation logic
}

struct ExecutionRule: Codable, Identifiable {
    var id: UUID = UUID()
    var type: RuleType
    var condition: String // JS condition
    var limit: Int?
}

enum RuleType: String, Codable, CaseIterable {
    case eventFilter, timeConstraint, frequencyLimit, conditionalLogic
}

struct UIExtension: Codable, Identifiable {
    var id: UUID = UUID()
    var type: UIExtensionType
    var component: UIComponentType
    var targetView: String
    var actionBinding: String // JS function name
}

enum UIExtensionType: String, Codable, CaseIterable {
    case overlay, panel, commandBar, contextMenu
}

enum UIComponentType: String, Codable, CaseIterable {
    case button, panel, modal, textInput, statusIndicator
}

struct PluginToolkitTool: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: PluginToolCategory
    var config: [String: String]
}

enum PluginToolCategory: String, Codable, CaseIterable {
    case ai, data, automation, integrations, workspace, developer, security, event
}

// MARK: - Legacy Models

struct PluginScope: Codable, Equatable {
    let capability: PluginCapability
    let action: String
    var isValidated: Bool = false
}

enum PluginPrerequisite: String, Codable, CaseIterable {
    case notes, repo, mail, ai, automation, calendar
}

// MARK: - Connector Models

struct ConnectorDefinition: Codable, Identifiable {
    let id: UUID
    var name: String
    var identifier: String // com.toolskit.connector.<name>
    var version: String
    var description: String
    var author: String

    var endpoints: [ExternalAPIEndpoint] = []
    var auth: ConnectorAuth = ConnectorAuth()
    var flows: [ConnectorFlow] = []
    var dataMappings: [DataMapping] = []

    var isEnabled: Bool = false
    var status: ConnectorStatus = .disconnected

    var capabilities: [PluginCapability] {
        var caps: [PluginCapability] = []
        if !endpoints.isEmpty { caps.append(.connectorApiRead); caps.append(.connectorApiWrite) }
        if !flows.isEmpty { caps.append(.connectorFlowExecute) }
        if !dataMappings.isEmpty { caps.append(.connectorDataMap) }
        if auth.type != .none { caps.append(.connectorAuthManage) }
        return caps
    }
}

enum ConnectorStatus: String, Codable {
    case active, disconnected, error, degraded
}

struct ConnectorAuth: Codable {
    var type: AuthType = .none
    var apiKey: String?
    var oauthConfig: OAuthConfig?
    var bearerToken: String?
    var customHeaders: [String: String] = [:]
}

struct OAuthConfig: Codable {
    var clientID: String
    var clientSecret: String
    var authURL: String
    var tokenURL: String
    var redirectURI: String
}

struct ConnectorFlow: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var trigger: FlowTrigger
    var steps: [FlowStep] = []
    var retryRule: RetryPolicy = RetryPolicy()
}

struct FlowTrigger: Codable {
    var type: FlowTriggerType
    var config: [String: String] = [:]
}

enum FlowTriggerType: String, Codable {
    case webhook, schedule, event, manual
}

struct FlowStep: Codable, Identifiable {
    var id: UUID = UUID()
    var type: FlowStepType
    var endpointID: UUID?
    var condition: String?
    var transformation: String?
}

enum FlowStepType: String, Codable {
    case apiCall, condition, transformation, notification, script
}

// MARK: - Security Helpers

struct PluginSecurityService {
    static func encryptHeader(_ value: String) -> String {
        // Simulated encryption: base64 + prefix
        return "SECURE:" + Data(value.utf8).base64EncodedString()
    }

    static func decryptHeader(_ encryptedValue: String) -> String {
        guard encryptedValue.hasPrefix("SECURE:") else { return encryptedValue }
        let base64 = String(encryptedValue.dropFirst(7))
        if let data = Data(base64Encoded: base64), let decrypted = String(data: data, encoding: .utf8) {
            return decrypted
        }
        return encryptedValue
    }
}
