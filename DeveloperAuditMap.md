# Developer Module Audit Map

## Applications & Project Management
- **AppManagementView.swift**: Central hub for managing developer applications.
- **AppBuilderView.swift**: Interface for creating new applications with target and type selection.
- **AppDetailView.swift**: Detailed view for a specific application's settings and metadata.
- **AppVersionHistoryView.swift**: Tracks and displays the release history of an application.
- **AppEnvironmentsView.swift**: Manages different environments (Development, Staging, Production).
- **AppCollaboratorsView.swift**: Manages team access and permissions for a specific app.
- **AppBundleValidatorView.swift**: Validates application bundles against platform requirements.
- **ProjectInstallerView.swift / ProjectInstallManager.swift**: Handles local project installation and workspace integration.

## Operations & Infrastructure
- **DeveloperInfrastructureStatusView.swift**: Real-time status of infrastructure nodes and clusters.
- **DeveloperDeploymentPipelineView.swift**: CI/CD pipeline management and execution tracking.
- **DeveloperSandboxEnvironmentView.swift**: Management of developer-specific sandbox instances.
- **DeveloperLogsView.swift**: Centralized log viewer for application and system logs.
- **LogDrainConfigView.swift**: Configuration for external log streaming.
- **LogAlertRulesView.swift**: Rules for triggering alerts based on log patterns.
- **DeveloperStorageUsageView.swift**: Monitoring of disk and cloud storage consumption.
- **SandboxEnvironmentView.swift**: Lightweight sandbox controls and reset functionality.

## Data & Persistence
- **DeveloperDatabaseManagerView.swift**: Management of database schemas, tables, and operational tasks like VACUUM.
- **DeveloperPersistentStore.swift**: Centralized persistence layer using UserDefaults for developer-related entities.
- **Models/DatabaseSchema.swift**: Data structures for database management.

## Security & Compliance
- **AuthServiceManagerView.swift**: Management of authentication services and API keys.
- **WebhookManagerView.swift**: CRUD operations for webhook endpoints.
- **WebhookTestView.swift / WebhookDeliveryLogView.swift**: Testing and debugging tools for webhooks.
- **ComplianceChecklistView.swift**: Verification of application compliance with platform standards.
- **PrivacyManifestEditorView.swift**: Editor for declared privacy practices and data usage.
- **DataHandlingPolicyBuilderView.swift**: Tool for generating and managing data retention/privacy policies.
- **ScopeManagementView.swift / ScopeDetailSheet.swift / ScopeRequestFormView.swift / ScopeTemplatesView.swift / ScopeAuditLogView.swift**: Comprehensive system for managing API permissions and authorization scopes.
- **DeveloperSecurityAuditView.swift**: Audit logs for security-related events.
- **DeveloperSecurityPolicyView.swift**: Definition and enforcement of organizational security policies.
- **DeveloperSecretsManagerView.swift**: Secure storage for API secrets and environment variables.

## Analytics & Monitoring
- **AnalyticsDashboardView.swift**: High-level overview of application usage and business metrics.
- **CustomEventManagerView.swift**: Management and tracking of user-defined events.
- **FunnelBuilderView.swift**: Visual builder for conversion funnels.
- **DocumentationAnalyticsView.swift**: Insights into documentation usage and search effectiveness.
- **DeveloperPerformanceMonitorView.swift**: Real-time performance metrics (CPU, Memory, Latency).
- **DeveloperNetworkTrafficView.swift**: Monitoring of API requests and network throughput.
- **DeveloperCrashReportView.swift**: Aggregation and analysis of application crashes.
- **DeveloperFeatureFlagView.swift**: Remote toggle management for feature releases.
- **ErrorGroupingView.swift**: Analysis of recurring application errors.
- **DeveloperRemoteConfigView.swift**: Dynamic configuration management for remote application behavior.

## Globalization & Content
- **DeveloperLocalizationManagerView.swift**: Management of localization keys and translation progress.
- **DocumentationEditorView.swift**: CMS-style editor for developer documentation.
- **DocSectionEditor.swift**: Granular control over documentation sections.
- **DocumentationLocalizationView.swift**: Specific workflow for localizing documentation.
- **OrganizationManagementView.swift / TeamManagementView.swift**: Management of developer organizations and team members.

## Marketplace & Distribution
- **MarketplaceListingManagerView.swift**: Management of public marketplace listings.
- **MarketplaceSubmissionView.swift / SubmissionWizardSteps.swift**: Guided workflow for submitting apps to the marketplace.
- **MarketplaceDraftListView.swift**: Management of in-progress submissions.
- **MarketplaceReviewFeedbackView.swift**: Interface for viewing and addressing reviewer comments.
- **TransferOwnershipView.swift**: Secure workflow for transferring app ownership between accounts.

## Identity & Support
- **DeveloperProfileView.swift**: Personal developer profile settings.
- **DeveloperVerificationView.swift**: Identity verification workflow.
- **DeveloperSupportTicketView.swift**: Threaded support ticket system.
- **DeveloperAccountActivityView.swift**: Security log of account-level actions.
- **DeveloperCLIView.swift / CLITokenView.swift**: Tools for integrating with the Developer Command Line Interface.
