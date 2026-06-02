import Foundation
import Combine

public class DeveloperPersistentStore: ObservableObject {
    public static let shared = DeveloperPersistentStore()

    @Published public var profile: DeveloperProfile
    @Published public var apps: [DeveloperApp]
    @Published public var keys: [APIKey]
    @Published public var webhooks: [WebhookEndpoint]
    @Published public var teamMembers: [OrgMember]
    @Published public var organizations: [DeveloperOrganization]
    @Published public var submissions: [MarketplaceSubmission]
    @Published public var drafts: [MarketplaceSubmissionDraft]
    @Published public var releases: [AppVersion]
    @Published public var logEntries: [LogEntry]
    @Published public var activities: [DeveloperActivityEvent]
    @Published public var grantedScopes: [GrantedScope]
    @Published public var scopeRequests: [ScopeRequest]
    @Published public var scopeAuditLogs: [ScopeAuditEvent]
    @Published public var documentationPages: [DocumentationPage]
    @Published public var certificates: [DeveloperCertificate]
    @Published public var betaGroups: [BetaGroup]
    @Published public var supportTickets: [SupportTicket]
    @Published public var installEvents: [InstallEvent]
    @Published public var customEvents: [CustomEventRecord]
    @Published public var funnels: [AnalyticsFunnel]
    @Published public var accountActivities: [AccountActivityEvent]
    @Published public var featureFlags: [FeatureFlag]
    @Published public var incidents: [Incident]
    @Published public var performanceMetrics: [PerformanceMetric]
    @Published public var remoteConfigs: [RemoteConfig]
    @Published public var secrets: [Secret]
    @Published public var crashLogs: [CrashLog]
    @Published public var networkRequests: [NetworkRequest]
    @Published public var pipelines: [Pipeline]
    @Published public var databaseSchemas: [DatabaseSchema]
    @Published public var localizationKeys: [LocalizationKey]
    @Published public var securityPolicies: [SecurityPolicy]
    @Published public var infrastructureNodes: [InfrastructureNode]

    // New properties for SDK & Extension Framework
    @Published public var sdkTemplates: [SDKTemplate]
    @Published public var sdkVersions: [SDKVersion]
    @Published public var sdkArtifacts: [SDKBuildArtifact]
    @Published public var sdkTestResults: [SDKTestResult]
    @Published public var sdkDependencies: [SDKDependency]
    @Published public var sdkModules: [SDKModule]
    @Published public var sdkBenchmarks: [SDKBenchmarkResult]
    @Published public var sdkArchives: [SDKArchive]
    @Published public var plugins: [DeveloperPlugin]
    @Published public var pluginAnalytics: [PluginAnalytics]
    @Published public var connectors: [ConnectorConfig]
    @Published public var connectorHealth: [ConnectorHealth]
    @Published public var connectorTraffic: [TrafficPacket]
    @Published public var authProfiles: [AuthProfile]
    @Published public var logicScripts: [LogicScript]
    @Published public var bounties: [DeveloperBounty]
    @Published public var rateLimits: [APIRateLimit]

    private let profileKey = "dev_portal_profile"
    private let appsKey = "dev_portal_apps"
    private let keysKey = "dev_portal_keys"
    private let webhooksKey = "dev_portal_webhooks"
    private let teamMembersKey = "dev_portal_team"
    private let organizationsKey = "dev_portal_orgs"
    private let submissionsKey = "dev_portal_submissions"
    private let draftsKey = "dev_portal_drafts"
    private let releasesKey = "dev_portal_releases"
    private let logsKey = "dev_portal_logs"
    private let activitiesKey = "dev_portal_activities"
    private let grantedScopesKey = "dev_portal_granted_scopes"
    private let scopeRequestsKey = "dev_portal_scope_requests"
    private let scopeAuditLogsKey = "dev_portal_scope_audit_logs"
    private let documentationKey = "dev_portal_documentation"
    private let certificatesKey = "dev_portal_certificates"
    private let betaGroupsKey = "dev_portal_beta_groups"
    private let supportTicketsKey = "dev_portal_support_tickets"
    private let installEventsKey = "dev_portal_install_events"
    private let customEventsKey = "dev_portal_custom_events"
    private let funnelsKey = "dev_portal_funnels"
    private let accountActivitiesKey = "dev_portal_account_activities"
    private let featureFlagsKey = "dev_portal_feature_flags"
    private let incidentsKey = "dev_portal_incidents"
    private let performanceMetricsKey = "dev_portal_performance_metrics"
    private let remoteConfigsKey = "dev_portal_remote_configs"
    private let secretsKey = "dev_portal_secrets"
    private let crashLogsKey = "dev_portal_crash_logs"
    private let networkRequestsKey = "dev_portal_network_requests"
    private let pipelinesKey = "dev_portal_pipelines"
    private let databaseSchemasKey = "dev_portal_database_schemas"
    private let localizationKeysKey = "dev_portal_localization_keys"
    private let securityPoliciesKey = "dev_portal_security_policies"
    private let infrastructureNodesKey = "dev_portal_infrastructure_nodes"

    // New keys
    private let sdkTemplatesKey = "dev_portal_sdk_templates"
    private let sdkVersionsKey = "dev_portal_sdk_versions"
    private let sdkArtifactsKey = "dev_portal_sdk_artifacts"
    private let sdkTestResultsKey = "dev_portal_sdk_test_results"
    private let sdkDependenciesKey = "dev_portal_sdk_dependencies"
    private let sdkModulesKey = "dev_portal_sdk_modules"
    private let sdkBenchmarksKey = "dev_portal_sdk_benchmarks"
    private let sdkArchivesKey = "dev_portal_sdk_archives"
    private let pluginsKey = "dev_portal_plugins"
    private let pluginAnalyticsKey = "dev_portal_plugin_analytics"
    private let connectorsKey = "dev_portal_connectors"
    private let connectorHealthKey = "dev_portal_connector_health"
    private let connectorTrafficKey = "dev_portal_connector_traffic"
    private let authProfilesKey = "dev_portal_auth_profiles"
    private let logicScriptsKey = "dev_portal_logic_scripts"
    private let bountiesKey = "dev_portal_bounties"
    private let rateLimitsKey = "dev_portal_rate_limits"

    private init() {
        self.profile = Self.load(DeveloperProfile.self, key: profileKey) ?? DeveloperProfile()
        self.apps = Self.load([DeveloperApp].self, key: appsKey) ?? []
        self.keys = Self.load([APIKey].self, key: keysKey) ?? []
        self.webhooks = Self.load([WebhookEndpoint].self, key: webhooksKey) ?? []
        self.teamMembers = Self.load([OrgMember].self, key: teamMembersKey) ?? []
        self.organizations = Self.load([DeveloperOrganization].self, key: organizationsKey) ?? []
        self.submissions = Self.load([MarketplaceSubmission].self, key: submissionsKey) ?? []
        self.drafts = Self.load([MarketplaceSubmissionDraft].self, key: draftsKey) ?? []
        self.releases = Self.load([AppVersion].self, key: releasesKey) ?? []
        self.logEntries = Self.load([LogEntry].self, key: logsKey) ?? []
        self.activities = Self.load([DeveloperActivityEvent].self, key: activitiesKey) ?? []
        self.grantedScopes = Self.load([GrantedScope].self, key: grantedScopesKey) ?? []
        self.scopeRequests = Self.load([ScopeRequest].self, key: scopeRequestsKey) ?? []
        self.scopeAuditLogs = Self.load([ScopeAuditEvent].self, key: scopeAuditLogsKey) ?? []
        self.documentationPages = Self.load([DocumentationPage].self, key: documentationKey) ?? []
        self.certificates = Self.load([DeveloperCertificate].self, key: certificatesKey) ?? []
        self.betaGroups = Self.load([BetaGroup].self, key: betaGroupsKey) ?? []
        self.supportTickets = Self.load([SupportTicket].self, key: supportTicketsKey) ?? []
        self.installEvents = Self.load([InstallEvent].self, key: installEventsKey) ?? []
        self.customEvents = Self.load([CustomEventRecord].self, key: customEventsKey) ?? []
        self.funnels = Self.load([AnalyticsFunnel].self, key: funnelsKey) ?? []
        self.accountActivities = Self.load([AccountActivityEvent].self, key: accountActivitiesKey) ?? []
        self.featureFlags = Self.load([FeatureFlag].self, key: featureFlagsKey) ?? []
        self.incidents = Self.load([Incident].self, key: incidentsKey) ?? []
        self.performanceMetrics = Self.load([PerformanceMetric].self, key: performanceMetricsKey) ?? []
        self.remoteConfigs = Self.load([RemoteConfig].self, key: remoteConfigsKey) ?? []
        self.secrets = Self.load([Secret].self, key: secretsKey) ?? []
        self.crashLogs = Self.load([CrashLog].self, key: crashLogsKey) ?? []
        self.networkRequests = Self.load([NetworkRequest].self, key: networkRequestsKey) ?? []
        self.pipelines = Self.load([Pipeline].self, key: pipelinesKey) ?? []
        self.databaseSchemas = Self.load([DatabaseSchema].self, key: databaseSchemasKey) ?? []
        self.localizationKeys = Self.load([LocalizationKey].self, key: localizationKeysKey) ?? []
        self.securityPolicies = Self.load([SecurityPolicy].self, key: securityPoliciesKey) ?? []
        self.infrastructureNodes = Self.load([InfrastructureNode].self, key: infrastructureNodesKey) ?? []

        // Load new entities
        self.sdkTemplates = Self.load([SDKTemplate].self, key: sdkTemplatesKey) ?? []
        self.sdkVersions = Self.load([SDKVersion].self, key: sdkVersionsKey) ?? []
        self.sdkArtifacts = Self.load([SDKBuildArtifact].self, key: sdkArtifactsKey) ?? []
        self.sdkTestResults = Self.load([SDKTestResult].self, key: sdkTestResultsKey) ?? []
        self.sdkDependencies = Self.load([SDKDependency].self, key: sdkDependenciesKey) ?? []
        self.sdkModules = Self.load([SDKModule].self, key: sdkModulesKey) ?? []
        self.sdkBenchmarks = Self.load([SDKBenchmarkResult].self, key: sdkBenchmarksKey) ?? []
        self.sdkArchives = Self.load([SDKArchive].self, key: sdkArchivesKey) ?? []
        self.plugins = Self.load([DeveloperPlugin].self, key: pluginsKey) ?? []
        self.pluginAnalytics = Self.load([PluginAnalytics].self, key: pluginAnalyticsKey) ?? []
        self.connectors = Self.load([ConnectorConfig].self, key: connectorsKey) ?? []
        self.connectorHealth = Self.load([ConnectorHealth].self, key: connectorHealthKey) ?? []
        self.connectorTraffic = Self.load([TrafficPacket].self, key: connectorTrafficKey) ?? []
        self.authProfiles = Self.load([AuthProfile].self, key: authProfilesKey) ?? []
        self.logicScripts = Self.load([LogicScript].self, key: logicScriptsKey) ?? []
        self.bounties = Self.load([DeveloperBounty].self, key: bountiesKey) ?? []
        self.rateLimits = Self.load([APIRateLimit].self, key: rateLimitsKey) ?? []
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }

    private func save<T: Encodable>(_ object: T, key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    // Existing save methods...
    public func saveProfile(_ newProfile: DeveloperProfile) { save(newProfile, key: profileKey); self.profile = newProfile }
    public func saveApps(_ newApps: [DeveloperApp]) { save(newApps, key: appsKey); self.apps = newApps }
    public func addApp(_ app: DeveloperApp) { self.apps.append(app); save(self.apps, key: appsKey) }
    public func saveKeys(_ newKeys: [APIKey]) { save(newKeys, key: keysKey); self.keys = newKeys }
    public func saveWebhooks(_ newWebhooks: [WebhookEndpoint]) { save(newWebhooks, key: webhooksKey); self.webhooks = newWebhooks }
    public func saveTeamMembers(_ newMembers: [OrgMember]) { save(newMembers, key: teamMembersKey); self.teamMembers = newMembers }
    public func saveOrganizations(_ newOrgs: [DeveloperOrganization]) { save(newOrgs, key: organizationsKey); self.organizations = newOrgs }
    public func saveSubmissions(_ newSubmissions: [MarketplaceSubmission]) { save(newSubmissions, key: submissionsKey); self.submissions = newSubmissions }
    public func saveDrafts(_ newDrafts: [MarketplaceSubmissionDraft]) { save(newDrafts, key: draftsKey); self.drafts = newDrafts }
    public func saveReleases(_ newReleases: [AppVersion]) { save(newReleases, key: releasesKey); self.releases = newReleases }
    public func saveLogs(_ newLogs: [LogEntry]) { save(newLogs, key: logsKey); self.logEntries = newLogs }
    public func saveActivities(_ newActivities: [DeveloperActivityEvent]) { save(newActivities, key: activitiesKey); self.activities = newActivities }
    public func saveGrantedScopes(_ newScopes: [GrantedScope]) { save(newScopes, key: grantedScopesKey); self.grantedScopes = newScopes }
    public func saveScopeRequests(_ newRequests: [ScopeRequest]) { save(newRequests, key: scopeRequestsKey); self.scopeRequests = newRequests }
    public func saveScopeAuditLogs(_ newLogs: [ScopeAuditEvent]) { save(newLogs, key: scopeAuditLogsKey); self.scopeAuditLogs = newLogs }
    public func saveDocumentationPages(_ newPages: [DocumentationPage]) { save(newPages, key: documentationKey); self.documentationPages = newPages }
    public func saveCertificates(_ newCertificates: [DeveloperCertificate]) { save(newCertificates, key: certificatesKey); self.certificates = newCertificates }
    public func saveBetaGroups(_ newGroups: [BetaGroup]) { save(newGroups, key: betaGroupsKey); self.betaGroups = newGroups }
    public func saveSupportTickets(_ newTickets: [SupportTicket]) { save(newTickets, key: supportTicketsKey); self.supportTickets = newTickets }
    public func saveInstallEvents(_ newEvents: [InstallEvent]) { save(newEvents, key: installEventsKey); self.installEvents = newEvents }
    public func saveCustomEvents(_ newEvents: [CustomEventRecord]) { save(newEvents, key: customEventsKey); self.customEvents = newEvents }
    public func saveFunnels(_ newFunnels: [AnalyticsFunnel]) { save(newFunnels, key: funnelsKey); self.funnels = newFunnels }
    public func saveAccountActivities(_ newEvents: [AccountActivityEvent]) { save(newEvents, key: accountActivitiesKey); self.accountActivities = newEvents }
    public func saveFeatureFlags(_ newFlags: [FeatureFlag]) { save(newFlags, key: featureFlagsKey); self.featureFlags = newFlags }
    public func saveIncidents(_ newIncidents: [Incident]) { save(newIncidents, key: incidentsKey); self.incidents = newIncidents }
    public func savePerformanceMetrics(_ newMetrics: [PerformanceMetric]) { save(newMetrics, key: performanceMetricsKey); self.performanceMetrics = newMetrics }
    public func saveRemoteConfigs(_ newConfigs: [RemoteConfig]) { save(newConfigs, key: remoteConfigsKey); self.remoteConfigs = newConfigs }
    public func saveSecrets(_ newSecrets: [Secret]) { save(newSecrets, key: secretsKey); self.secrets = newSecrets }
    public func saveCrashLogs(_ newLogs: [CrashLog]) { save(newLogs, key: crashLogsKey); self.crashLogs = newLogs }
    public func saveNetworkRequests(_ newRequests: [NetworkRequest]) { save(newRequests, key: networkRequestsKey); self.networkRequests = newRequests }
    public func savePipelines(_ newPipelines: [Pipeline]) { save(newPipelines, key: pipelinesKey); self.pipelines = newPipelines }
    public func saveDatabaseSchemas(_ newSchemas: [DatabaseSchema]) { save(newSchemas, key: databaseSchemasKey); self.databaseSchemas = newSchemas }
    public func saveLocalizationKeys(_ newKeys: [LocalizationKey]) { save(newKeys, key: localizationKeysKey); self.localizationKeys = newKeys }
    public func saveSecurityPolicies(_ newPolicies: [SecurityPolicy]) { save(newPolicies, key: securityPoliciesKey); self.securityPolicies = newPolicies }
    public func saveInfrastructureNodes(_ newNodes: [InfrastructureNode]) { save(newNodes, key: infrastructureNodesKey); self.infrastructureNodes = newNodes }

    // New save methods
    public func saveSDKTemplates(_ templates: [SDKTemplate]) { save(templates, key: sdkTemplatesKey); self.sdkTemplates = templates }
    public func saveSDKVersions(_ versions: [SDKVersion]) { save(versions, key: sdkVersionsKey); self.sdkVersions = versions }
    public func saveSDKArtifacts(_ artifacts: [SDKBuildArtifact]) { save(artifacts, key: sdkArtifactsKey); self.sdkArtifacts = artifacts }
    public func saveSDKTestResults(_ results: [SDKTestResult]) { save(results, key: sdkTestResultsKey); self.sdkTestResults = results }
    public func saveSDKDependencies(_ deps: [SDKDependency]) { save(deps, key: sdkDependenciesKey); self.sdkDependencies = deps }
    public func saveSDKModules(_ modules: [SDKModule]) { save(modules, key: sdkModulesKey); self.sdkModules = modules }
    public func saveSDKBenchmarks(_ results: [SDKBenchmarkResult]) { save(results, key: sdkBenchmarksKey); self.sdkBenchmarks = results }
    public func saveSDKArchives(_ archives: [SDKArchive]) { save(archives, key: sdkArchivesKey); self.sdkArchives = archives }
    public func savePlugins(_ plugins: [DeveloperPlugin]) { save(plugins, key: pluginsKey); self.plugins = plugins }
    public func savePluginAnalytics(_ analytics: [PluginAnalytics]) { save(analytics, key: pluginAnalyticsKey); self.pluginAnalytics = analytics }
    public func saveConnectors(_ connectors: [ConnectorConfig]) { save(connectors, key: connectorsKey); self.connectors = connectors }
    public func saveConnectorHealth(_ health: [ConnectorHealth]) { save(health, key: connectorHealthKey); self.connectorHealth = health }
    public func saveConnectorTraffic(_ traffic: [TrafficPacket]) { save(traffic, key: connectorTrafficKey); self.connectorTraffic = traffic }
    public func saveAuthProfiles(_ profiles: [AuthProfile]) { save(profiles, key: authProfilesKey); self.authProfiles = profiles }
    public func saveLogicScripts(_ scripts: [LogicScript]) { save(scripts, key: logicScriptsKey); self.logicScripts = scripts }
    public func saveBounties(_ bounties: [DeveloperBounty]) { save(bounties, key: bountiesKey); self.bounties = bounties }
    public func saveRateLimits(_ limits: [APIRateLimit]) { save(limits, key: rateLimitsKey); self.rateLimits = limits }
}

// Models previously defined in the same file are kept here for compatibility if they weren't moved.
public struct DeveloperCertificate: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var name: String
    public var type: String
    public var createdAt: Date
    public var expiresAt: Date

    public init(id: UUID = UUID(), appID: UUID, name: String, type: String, createdAt: Date = Date(), expiresAt: Date = Date().addingTimeInterval(365*24*3600)) {
        self.id = id
        self.appID = appID
        self.name = name
        self.type = type
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

public struct BetaGroup: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var name: String
    public var testerEmails: [String]

    public init(id: UUID = UUID(), appID: UUID, name: String, testerEmails: [String] = []) {
        self.id = id
        self.appID = appID
        self.name = name
        self.testerEmails = testerEmails
    }
}

public struct TicketComment: Identifiable, Codable, Hashable {
    public var id: UUID
    public var sender: String
    public var content: String
    public var timestamp: Date

    public init(id: UUID = UUID(), sender: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
    }
}

public struct SupportTicket: Identifiable, Codable, Hashable {
    public var id: UUID
    public var subject: String
    public var topic: String
    public var priority: String // Low, Medium, High, Critical
    public var status: String
    public var appName: String
    public var message: String
    public var comments: [TicketComment]
    public var createdAt: Date

    public init(id: UUID = UUID(), subject: String, topic: String = "General", priority: String = "Medium", status: String, appName: String, message: String = "", comments: [TicketComment] = [], createdAt: Date = Date()) {
        self.id = id
        self.subject = subject
        self.topic = topic
        self.priority = priority
        self.status = status
        self.appName = appName
        self.message = message
        self.comments = comments
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, subject, topic, priority, status, appName, message, comments, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.subject = try container.decode(String.self, forKey: .subject)
        self.topic = try container.decodeIfPresent(String.self, forKey: .topic) ?? "General"
        self.priority = try container.decodeIfPresent(String.self, forKey: .priority) ?? "Medium"
        self.status = try container.decode(String.self, forKey: .status)
        self.appName = try container.decode(String.self, forKey: .appName)
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        self.comments = try container.decodeIfPresent([TicketComment].self, forKey: .comments) ?? []
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
