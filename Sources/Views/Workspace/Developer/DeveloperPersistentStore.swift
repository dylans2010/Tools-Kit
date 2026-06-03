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
    @Published public var storageNodes: [StorageNode]
    @Published public var scopeTemplates: [ScopeTemplate]
    @Published public var betaTesters: [BetaTester]
    @Published public var betaFeedback: [BetaFeedback]
    @Published public var sdkArchitectures: [SDKProjectArchitecture]
    @Published public var pluginPackages: [PluginPackage]
    @Published public var connectorAuths: [ConnectorAuth]
    @Published public var onboardingSteps: [OnboardingStep]
    @Published public var distributionTargets: [DistributionTarget]
    @Published public var buildArtifacts: [BuildArtifact]
    @Published public var vaultVariables: [VaultVariable]
    @Published public var resourceQuotas: [ResourceQuota]
    @Published public var configInstances: [ConfigInstance]
    @Published public var testSuites: [TestSuite]
    @Published public var recruitmentCampaigns: [RecruitmentCampaign]
    @Published public var errorRegressions: [ErrorRegression]
    @Published public var dependencyVulnerabilities: [DependencyVulnerability]
    @Published public var localeAudits: [LocaleAudit]
    @Published public var structuredLogs: [StructuredLog]
    @Published public var trafficRequests: [TrafficRequest]
    @Published public var schemaMigrations: [SchemaMigration]
    @Published public var performanceTraces: [PerformanceTrace]
    @Published public var canaryRollouts: [CanaryRollout]

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
    private let storageNodesKey = "dev_portal_storage_nodes"
    private let scopeTemplatesKey = "dev_portal_scope_templates"
    private let betaTestersKey = "dev_portal_beta_testers"
    private let betaFeedbackKey = "dev_portal_beta_feedback"
    private let sdkArchitecturesKey = "dev_portal_sdk_architectures"
    private let pluginPackagesKey = "dev_portal_plugin_packages"
    private let connectorAuthsKey = "dev_portal_connector_auths"
    private let onboardingStepsKey = "dev_portal_onboarding_steps"
    private let distributionTargetsKey = "dev_portal_distribution_targets"
    private let buildArtifactsKey = "dev_portal_build_artifacts"
    private let vaultVariablesKey = "dev_portal_vault_variables"
    private let resourceQuotasKey = "dev_portal_resource_quotas"
    private let configInstancesKey = "dev_portal_config_instances"
    private let testSuitesKey = "dev_portal_test_suites"
    private let recruitmentCampaignsKey = "dev_portal_recruitment_campaigns"
    private let errorRegressionsKey = "dev_portal_error_regressions"
    private let dependencyVulnerabilitiesKey = "dev_portal_dependency_vulnerabilities"
    private let localeAuditsKey = "dev_portal_locale_audits"
    private let structuredLogsKey = "dev_portal_structured_logs"
    private let trafficRequestsKey = "dev_portal_traffic_requests"
    private let schemaMigrationsKey = "dev_portal_schema_migrations"
    private let performanceTracesKey = "dev_portal_performance_traces"
    private let canaryRolloutsKey = "dev_portal_canary_rollouts"

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
        self.storageNodes = Self.load([StorageNode].self, key: storageNodesKey) ?? []
        self.scopeTemplates = Self.load([ScopeTemplate].self, key: scopeTemplatesKey) ?? []
        self.betaTesters = Self.load([BetaTester].self, key: betaTestersKey) ?? []
        self.betaFeedback = Self.load([BetaFeedback].self, key: betaFeedbackKey) ?? []
        self.sdkArchitectures = Self.load([SDKProjectArchitecture].self, key: sdkArchitecturesKey) ?? []
        self.pluginPackages = Self.load([PluginPackage].self, key: pluginPackagesKey) ?? []
        self.connectorAuths = Self.load([ConnectorAuth].self, key: connectorAuthsKey) ?? []
        self.onboardingSteps = Self.load([OnboardingStep].self, key: onboardingStepsKey) ?? []
        self.distributionTargets = Self.load([DistributionTarget].self, key: distributionTargetsKey) ?? []
        self.buildArtifacts = Self.load([BuildArtifact].self, key: buildArtifactsKey) ?? []
        self.vaultVariables = Self.load([VaultVariable].self, key: vaultVariablesKey) ?? []
        self.resourceQuotas = Self.load([ResourceQuota].self, key: resourceQuotasKey) ?? []
        self.configInstances = Self.load([ConfigInstance].self, key: configInstancesKey) ?? []
        self.testSuites = Self.load([TestSuite].self, key: testSuitesKey) ?? []
        self.recruitmentCampaigns = Self.load([RecruitmentCampaign].self, key: recruitmentCampaignsKey) ?? []
        self.errorRegressions = Self.load([ErrorRegression].self, key: errorRegressionsKey) ?? []
        self.dependencyVulnerabilities = Self.load([DependencyVulnerability].self, key: dependencyVulnerabilitiesKey) ?? []
        self.localeAudits = Self.load([LocaleAudit].self, key: localeAuditsKey) ?? []
        self.structuredLogs = Self.load([StructuredLog].self, key: structuredLogsKey) ?? []
        self.trafficRequests = Self.load([TrafficRequest].self, key: trafficRequestsKey) ?? []
        self.schemaMigrations = Self.load([SchemaMigration].self, key: schemaMigrationsKey) ?? []
        self.performanceTraces = Self.load([PerformanceTrace].self, key: performanceTracesKey) ?? []
        self.canaryRollouts = Self.load([CanaryRollout].self, key: canaryRolloutsKey) ?? []
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

    public func saveProfile(_ newProfile: DeveloperProfile) {
        save(newProfile, key: profileKey)
        self.profile = newProfile
    }

    public func saveApps(_ newApps: [DeveloperApp]) {
        save(newApps, key: appsKey)
        self.apps = newApps
    }

    public func addApp(_ app: DeveloperApp) {
        self.apps.append(app)
        save(self.apps, key: appsKey)
    }

    public func saveKeys(_ newKeys: [APIKey]) {
        save(newKeys, key: keysKey)
        self.keys = newKeys
    }

    public func saveWebhooks(_ newWebhooks: [WebhookEndpoint]) {
        save(newWebhooks, key: webhooksKey)
        self.webhooks = newWebhooks
    }

    public func saveTeamMembers(_ newMembers: [OrgMember]) {
        save(newMembers, key: teamMembersKey)
        self.teamMembers = newMembers
    }

    public func saveOrganizations(_ newOrgs: [DeveloperOrganization]) {
        save(newOrgs, key: organizationsKey)
        self.organizations = newOrgs
    }

    public func saveSubmissions(_ newSubmissions: [MarketplaceSubmission]) {
        save(newSubmissions, key: submissionsKey)
        self.submissions = newSubmissions
    }

    public func saveDrafts(_ newDrafts: [MarketplaceSubmissionDraft]) {
        save(newDrafts, key: draftsKey)
        self.drafts = newDrafts
    }

    public func saveReleases(_ newReleases: [AppVersion]) {
        save(newReleases, key: releasesKey)
        self.releases = newReleases
    }

    public func saveLogs(_ newLogs: [LogEntry]) {
        save(newLogs, key: logsKey)
        self.logEntries = newLogs
    }

    public func saveActivities(_ newActivities: [DeveloperActivityEvent]) {
        save(newActivities, key: activitiesKey)
        self.activities = newActivities
    }

    public func saveGrantedScopes(_ newScopes: [GrantedScope]) {
        save(newScopes, key: grantedScopesKey)
        self.grantedScopes = newScopes
    }

    public func saveScopeRequests(_ newRequests: [ScopeRequest]) {
        save(newRequests, key: scopeRequestsKey)
        self.scopeRequests = newRequests
    }

    public func saveScopeAuditLogs(_ newLogs: [ScopeAuditEvent]) {
        save(newLogs, key: scopeAuditLogsKey)
        self.scopeAuditLogs = newLogs
    }

    public func saveDocumentationPages(_ newPages: [DocumentationPage]) {
        save(newPages, key: documentationKey)
        self.documentationPages = newPages
    }

    public func saveCertificates(_ newCertificates: [DeveloperCertificate]) {
        save(newCertificates, key: certificatesKey)
        self.certificates = newCertificates
    }

    public func saveBetaGroups(_ newGroups: [BetaGroup]) {
        save(newGroups, key: betaGroupsKey)
        self.betaGroups = newGroups
    }

    public func saveSupportTickets(_ newTickets: [SupportTicket]) {
        save(newTickets, key: supportTicketsKey)
        self.supportTickets = newTickets
    }

    public func saveInstallEvents(_ newEvents: [InstallEvent]) {
        save(newEvents, key: installEventsKey)
        self.installEvents = newEvents
    }

    public func saveCustomEvents(_ newEvents: [CustomEventRecord]) {
        save(newEvents, key: customEventsKey)
        self.customEvents = newEvents
    }

    public func saveFunnels(_ newFunnels: [AnalyticsFunnel]) {
        save(newFunnels, key: funnelsKey)
        self.funnels = newFunnels
    }

    public func saveAccountActivities(_ newEvents: [AccountActivityEvent]) {
        save(newEvents, key: accountActivitiesKey)
        self.accountActivities = newEvents
    }

    public func saveFeatureFlags(_ newFlags: [FeatureFlag]) {
        save(newFlags, key: featureFlagsKey)
        self.featureFlags = newFlags
    }

    public func saveIncidents(_ newIncidents: [Incident]) {
        save(newIncidents, key: incidentsKey)
        self.incidents = newIncidents
    }

    public func savePerformanceMetrics(_ newMetrics: [PerformanceMetric]) {
        save(newMetrics, key: performanceMetricsKey)
        self.performanceMetrics = newMetrics
    }

    public func saveRemoteConfigs(_ newConfigs: [RemoteConfig]) {
        save(newConfigs, key: remoteConfigsKey)
        self.remoteConfigs = newConfigs
    }

    public func saveSecrets(_ newSecrets: [Secret]) {
        save(newSecrets, key: secretsKey)
        self.secrets = newSecrets
    }

    public func saveCrashLogs(_ newLogs: [CrashLog]) {
        save(newLogs, key: crashLogsKey)
        self.crashLogs = newLogs
    }

    public func saveNetworkRequests(_ newRequests: [NetworkRequest]) {
        save(newRequests, key: networkRequestsKey)
        self.networkRequests = newRequests
    }

    public func savePipelines(_ newPipelines: [Pipeline]) {
        save(newPipelines, key: pipelinesKey)
        self.pipelines = newPipelines
    }

    public func saveDatabaseSchemas(_ newSchemas: [DatabaseSchema]) {
        save(newSchemas, key: databaseSchemasKey)
        self.databaseSchemas = newSchemas
    }

    public func saveLocalizationKeys(_ newKeys: [LocalizationKey]) {
        save(newKeys, key: localizationKeysKey)
        self.localizationKeys = newKeys
    }

    public func saveSecurityPolicies(_ newPolicies: [SecurityPolicy]) {
        save(newPolicies, key: securityPoliciesKey)
        self.securityPolicies = newPolicies
    }

    public func saveInfrastructureNodes(_ newNodes: [InfrastructureNode]) {
        save(newNodes, key: infrastructureNodesKey)
        self.infrastructureNodes = newNodes
    }

    public func saveStorageNodes(_ newNodes: [StorageNode]) {
        save(newNodes, key: storageNodesKey)
        self.storageNodes = newNodes
    }

    public func saveScopeTemplates(_ newTemplates: [ScopeTemplate]) {
        save(newTemplates, key: scopeTemplatesKey)
        self.scopeTemplates = newTemplates
    }

    public func saveBetaTesters(_ newTesters: [BetaTester]) {
        save(newTesters, key: betaTestersKey)
        self.betaTesters = newTesters
    }

    public func saveBetaFeedback(_ newFeedback: [BetaFeedback]) {
        save(newFeedback, key: betaFeedbackKey)
        self.betaFeedback = newFeedback
    }

    public func saveSDKArchitectures(_ newItems: [SDKProjectArchitecture]) { save(newItems, key: sdkArchitecturesKey); self.sdkArchitectures = newItems }
    public func savePluginPackages(_ newItems: [PluginPackage]) { save(newItems, key: pluginPackagesKey); self.pluginPackages = newItems }
    public func saveConnectorAuths(_ newItems: [ConnectorAuth]) { save(newItems, key: connectorAuthsKey); self.connectorAuths = newItems }
    public func saveOnboardingSteps(_ newItems: [OnboardingStep]) { save(newItems, key: onboardingStepsKey); self.onboardingSteps = newItems }
    public func saveDistributionTargets(_ newItems: [DistributionTarget]) { save(newItems, key: distributionTargetsKey); self.distributionTargets = newItems }
    public func saveBuildArtifacts(_ newItems: [BuildArtifact]) { save(newItems, key: buildArtifactsKey); self.buildArtifacts = newItems }
    public func saveVaultVariables(_ newItems: [VaultVariable]) { save(newItems, key: vaultVariablesKey); self.vaultVariables = newItems }
    public func saveResourceQuotas(_ newItems: [ResourceQuota]) { save(newItems, key: resourceQuotasKey); self.resourceQuotas = newItems }
    public func saveConfigInstances(_ newItems: [ConfigInstance]) { save(newItems, key: configInstancesKey); self.configInstances = newItems }
    public func saveTestSuites(_ newItems: [TestSuite]) { save(newItems, key: testSuitesKey); self.testSuites = newItems }
    public func saveRecruitmentCampaigns(_ newItems: [RecruitmentCampaign]) { save(newItems, key: recruitmentCampaignsKey); self.recruitmentCampaigns = newItems }
    public func saveErrorRegressions(_ newItems: [ErrorRegression]) { save(newItems, key: errorRegressionsKey); self.errorRegressions = newItems }
    public func saveDependencyVulnerabilities(_ newItems: [DependencyVulnerability]) { save(newItems, key: dependencyVulnerabilitiesKey); self.dependencyVulnerabilities = newItems }
    public func saveLocaleAudits(_ newItems: [LocaleAudit]) { save(newItems, key: localeAuditsKey); self.localeAudits = newItems }
    public func saveStructuredLogs(_ newItems: [StructuredLog]) { save(newItems, key: structuredLogsKey); self.structuredLogs = newItems }
    public func saveTrafficRequests(_ newItems: [TrafficRequest]) { save(newItems, key: trafficRequestsKey); self.trafficRequests = newItems }
    public func saveSchemaMigrations(_ newItems: [SchemaMigration]) { save(newItems, key: schemaMigrationsKey); self.schemaMigrations = newItems }
    public func savePerformanceTraces(_ newItems: [PerformanceTrace]) { save(newItems, key: performanceTracesKey); self.performanceTraces = newItems }
    public func saveCanaryRollouts(_ newItems: [CanaryRollout]) { save(newItems, key: canaryRolloutsKey); self.canaryRollouts = newItems }
}

public struct BetaFeedback: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var version: String
    public var type: String // CRASH, FEEDBACK
    public var content: String
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID, version: String, type: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.version = version
        self.type = type
        self.content = content
        self.timestamp = timestamp
    }
}

public struct BetaTester: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var email: String
    public var status: String // Active, Invited
    public var joinedAt: Date

    public init(id: UUID = UUID(), appID: UUID, email: String, status: String = "Active", joinedAt: Date = Date()) {
        self.id = id
        self.appID = appID
        self.email = email
        self.status = status
        self.joinedAt = joinedAt
    }
}

public struct SDKProjectArchitecture: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var modules: [String]
    public var dependencies: [String]

    public init(id: UUID = UUID(), name: String, modules: [String] = [], dependencies: [String] = []) {
        self.id = id
        self.name = name
        self.modules = modules
        self.dependencies = dependencies
    }
}

public struct PluginPackage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var description: String
    public var version: String

    public init(id: UUID = UUID(), name: String, description: String, version: String) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
    }
}

public struct ConnectorAuth: Identifiable, Codable, Hashable {
    public var id: UUID
    public var service: String
    public var account: String
    public var status: String

    public init(id: UUID = UUID(), service: String, account: String, status: String) {
        self.id = id
        self.service = service
        self.account = account
        self.status = status
    }
}

public struct OnboardingStep: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

public struct DistributionTarget: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: String
    public var status: String

    public init(id: UUID = UUID(), name: String, type: String, status: String) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
    }
}

public struct BuildArtifact: Identifiable, Codable, Hashable {
    public var id: UUID
    public var version: String
    public var build: String
    public var filename: String
    public var size: String

    public init(id: UUID = UUID(), version: String, build: String, filename: String, size: String) {
        self.id = id
        self.version = version
        self.build = build
        self.filename = filename
        self.size = size
    }
}

public struct VaultVariable: Identifiable, Codable, Hashable {
    public var id: UUID
    public var key: String
    public var value: String
    public var isSecret: Bool

    public init(id: UUID = UUID(), key: String, value: String, isSecret: Bool = false) {
        self.id = id
        self.key = key
        self.value = value
        self.isSecret = isSecret
    }
}

public struct ResourceQuota: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var used: Double
    public var total: Double
    public var unit: String

    public init(id: UUID = UUID(), name: String, used: Double, total: Double, unit: String) {
        self.id = id
        self.name = name
        self.used = used
        self.total = total
        self.unit = unit
    }
}

public struct ConfigInstance: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var version: String
    public var syncStatus: String

    public init(id: UUID = UUID(), name: String, version: String, syncStatus: String) {
        self.id = id
        self.name = name
        self.version = version
        self.syncStatus = syncStatus
    }
}

public struct TestSuite: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var testCount: Int
    public var lastResult: String

    public init(id: UUID = UUID(), name: String, testCount: Int, lastResult: String) {
        self.id = id
        self.name = name
        self.testCount = testCount
        self.lastResult = lastResult
    }
}

public struct RecruitmentCampaign: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var targetCount: Int
    public var enrolledCount: Int
    public var status: String

    public init(id: UUID = UUID(), name: String, targetCount: Int, enrolledCount: Int = 0, status: String = "Active") {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.enrolledCount = enrolledCount
        self.status = status
    }
}

public struct ErrorRegression: Identifiable, Codable, Hashable {
    public var id: UUID
    public var errorType: String
    public var version: String
    public var occurrences: Int
    public var status: String

    public init(id: UUID = UUID(), errorType: String, version: String, occurrences: Int, status: String) {
        self.id = id
        self.errorType = errorType
        self.version = version
        self.occurrences = occurrences
        self.status = status
    }
}

public struct DependencyVulnerability: Identifiable, Codable, Hashable {
    public var id: UUID
    public var package: String
    public var version: String
    public var severity: String
    public var advisory: String

    public init(id: UUID = UUID(), package: String, version: String, severity: String, advisory: String) {
        self.id = id
        self.package = package
        self.version = version
        self.severity = severity
        self.advisory = advisory
    }
}

public struct LocaleAudit: Identifiable, Codable, Hashable {
    public var id: UUID
    public var locale: String
    public var coverage: Double
    public var missingKeys: Int

    public init(id: UUID = UUID(), locale: String, coverage: Double, missingKeys: Int) {
        self.id = id
        self.locale = locale
        self.coverage = coverage
        self.missingKeys = missingKeys
    }
}

public struct StructuredLog: Identifiable, Codable, Hashable {
    public var id: UUID
    public var level: String
    public var category: String
    public var message: String
    public var timestamp: Date

    public init(id: UUID = UUID(), level: String, category: String, message: String, timestamp: Date = Date()) {
        self.id = id
        self.level = level
        self.category = category
        self.message = message
        self.timestamp = timestamp
    }
}

public struct TrafficRequest: Identifiable, Codable, Hashable {
    public var id: UUID
    public var method: String
    public var path: String
    public var status: Int
    public var latency: String

    public init(id: UUID = UUID(), method: String, path: String, status: Int, latency: String) {
        self.id = id
        self.method = method
        self.path = path
        self.status = status
        self.latency = latency
    }
}

public struct SchemaMigration: Identifiable, Codable, Hashable {
    public var id: UUID
    public var version: String
    public var description: String
    public var status: String

    public init(id: UUID = UUID(), version: String, description: String, status: String) {
        self.id = id
        self.version = version
        self.description = description
        self.status = status
    }
}

public struct PerformanceTrace: Identifiable, Codable, Hashable {
    public var id: UUID
    public var operation: String
    public var duration: String
    public var impact: String

    public init(id: UUID = UUID(), operation: String, duration: String, impact: String) {
        self.id = id
        self.operation = operation
        self.duration = duration
        self.impact = impact
    }
}

public struct CanaryRollout: Identifiable, Codable, Hashable {
    public var id: UUID
    public var feature: String
    public var percentage: Double
    public var status: String

    public init(id: UUID = UUID(), feature: String, percentage: Double, status: String) {
        self.id = id
        self.feature = feature
        self.percentage = percentage
        self.status = status
    }
}

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
