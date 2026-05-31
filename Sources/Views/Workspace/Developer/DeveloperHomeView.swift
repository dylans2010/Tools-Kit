import SwiftUI

struct DeveloperHomeView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var activityService = DeveloperActivityService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    summaryStrip

                    VStack(alignment: .leading, spacing: 32) {
                        domainSection(title: "Applications & Projects", icon: "app.window.checkerboard", systems: [
                            SystemLink(title: "App Manager", destination: AnyView(AppManagementView()), icon: "square.stack.3d.up"),
                            SystemLink(title: "App Builder", destination: AnyView(AppBuilderView()), icon: "plus.app"),
                            SystemLink(title: "Integrations", destination: AnyView(DeveloperIntegrationGalleryView()), icon: "puzzlepiece"),
                            SystemLink(title: "Remote Config", destination: AnyView(DeveloperRemoteConfigView()), icon: "slider.horizontal.3"),
                            SystemLink(title: "Project Installer", destination: AnyView(ProjectInstallerView()), icon: "arrow.down.doc"),
                            SystemLink(title: "Storage Usage", destination: AnyView(DeveloperStorageUsageView()), icon: "cylinder.split.1x2")
                        ])

                        domainSection(title: "Operations & Infrastructure", icon: "terminal", systems: [
                            SystemLink(title: "Pipelines", destination: AnyView(DeveloperDeploymentPipelineView()), icon: "arrow.triangle.pull"),
                            SystemLink(title: "Releases", destination: AnyView(DeveloperReleaseManagementView()), icon: "shippingbox"),
                            SystemLink(title: "Beta Testing", destination: AnyView(DeveloperBetaTestingView()), icon: "testtube.2"),
                            SystemLink(title: "Infrastructure", destination: AnyView(DeveloperInfrastructureStatusView()), icon: "server.rack"),
                            SystemLink(title: "Database", destination: AnyView(DeveloperDatabaseManagerView()), icon: "tablecells"),
                            SystemLink(title: "Sandbox", destination: AnyView(DeveloperSandboxEnvironmentView()), icon: "shippingbox.and.arrow.backward")
                        ])

                        domainSection(title: "Observability", icon: "eye", systems: [
                            SystemLink(title: "System Logs", destination: AnyView(DeveloperLogsView()), icon: "list.bullet.rectangle"),
                            SystemLink(title: "Analytics", destination: AnyView(AnalyticsDashboardView()), icon: "chart.xyaxis.line"),
                            SystemLink(title: "Crash Reports", destination: AnyView(DeveloperCrashReportView()), icon: "bandage"),
                            SystemLink(title: "Monetization", destination: AnyView(DeveloperMonetizationView()), icon: "dollarsign.circle"),
                            SystemLink(title: "Performance", destination: AnyView(DeveloperPerformanceMonitorView()), icon: "gauge.with.needle"),
                            SystemLink(title: "Network", destination: AnyView(DeveloperNetworkTrafficView()), icon: "waveform.path.ecg"),
                            SystemLink(title: "Error Groups", destination: AnyView(ErrorGroupingView()), icon: "exclamationmark.octagon")
                        ])

                        domainSection(title: "Security & Access", icon: "lock.shield", systems: [
                            SystemLink(title: "Auth Manager", destination: AnyView(AuthServiceManagerView()), icon: "key"),
                            SystemLink(title: "Secrets", destination: AnyView(DeveloperSecretsManagerView()), icon: "lock.rectangle"),
                            SystemLink(title: "Webhooks", destination: AnyView(WebhookManagerView()), icon: "bolt.horizontal"),
                            SystemLink(title: "Security Audit", destination: AnyView(DeveloperSecurityAuditView()), icon: "checkmark.shield"),
                            SystemLink(title: "Security Policy", destination: AnyView(DeveloperSecurityPolicyView()), icon: "doc.shield"),
                            SystemLink(title: "CLI Tokens", destination: AnyView(CLITokenView()), icon: "chevron.left.forwardslash.chevron.right")
                        ])

                        domainSection(title: "Compliance & Identity", icon: "checkmark.seal", systems: [
                            SystemLink(title: "Permissions", destination: AnyView(ScopeManagementView()), icon: "shield.lefthalf.filled"),
                            SystemLink(title: "Scope Templates", destination: AnyView(ScopeTemplatesView()), icon: "square.stack.3d.up.fill"),
                            SystemLink(title: "Audit Logs", destination: AnyView(ScopeAuditLogView()), icon: "person.badge.shield.checkmark"),
                            SystemLink(title: "Certificates", destination: AnyView(DeveloperAppCertificatesView()), icon: "doc.badge.gearshape"),
                            SystemLink(title: "Privacy Manifest", destination: AnyView(PrivacyManifestEditorView()), icon: "hand.raised"),
                            SystemLink(title: "Data Policies", destination: AnyView(DataHandlingPolicyBuilderView()), icon: "doc.text.magnifyingglass"),
                            SystemLink(title: "Compliance", destination: AnyView(ComplianceChecklistView()), icon: "checklist"),
                            SystemLink(title: "Verification", destination: AnyView(DeveloperVerificationView()), icon: "person.crop.circle.badge.checkmark")
                        ])

                        domainSection(title: "Resources & Ecosystem", icon: "globe", systems: [
                            SystemLink(title: "Marketplace", destination: AnyView(MarketplaceListingManagerView()), icon: "storefront"),
                            SystemLink(title: "Drafts", destination: AnyView(MarketplaceDraftListView()), icon: "doc.text"),
                            SystemLink(title: "Localization", destination: AnyView(DeveloperLocalizationManagerView()), icon: "character.book.closed"),
                            SystemLink(title: "Doc Localization", destination: AnyView(DocumentationLocalizationView()), icon: "text.book.closed"),
                            SystemLink(title: "Docs Editor", destination: AnyView(DocumentationEditorView()), icon: "book.and.wrench"),
                            SystemLink(title: "Doc Analytics", destination: AnyView(DocumentationAnalyticsView()), icon: "chart.bar.doc.horizontal"),
                            SystemLink(title: "Organization", destination: AnyView(OrganizationManagementView()), icon: "building.2"),
                            SystemLink(title: "Team Manager", destination: AnyView(DeveloperTeamManagerView()), icon: "person.2")
                        ])

                        domainSection(title: "System Configuration", icon: "gearshape", systems: [
                            SystemLink(title: "Log Drains", destination: AnyView(LogDrainConfigView()), icon: "tray.and.arrow.down"),
                            SystemLink(title: "Alert Rules", destination: AnyView(LogAlertRulesView()), icon: "bell.badge"),
                            SystemLink(title: "Custom Events", destination: AnyView(CustomEventManagerView()), icon: "bolt"),
                            SystemLink(title: "Feature Flags", destination: AnyView(DeveloperFeatureFlagView()), icon: "flag"),
                            SystemLink(title: "Incidents", destination: AnyView(DeveloperIncidentManagerView()), icon: "exclamationmark.triangle"),
                            SystemLink(title: "Support", destination: AnyView(DeveloperSupportTicketView()), icon: "questionmark.circle"),
                            SystemLink(title: "Activity", destination: AnyView(DeveloperAccountActivityView()), icon: "person.text.rectangle")
                        ])
                    }

                    healthStatusPanel
                    recentActivityFeed
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Developer")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.primary.opacity(0.05))
                if !profileService.profile.avatarUrl.isEmpty, let url = URL(string: profileService.profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(profileService.profile.displayName.isEmpty ? "Developer" : profileService.profile.displayName)
                    .font(.headline)
                Text("@\(profileService.profile.username) • \(profileService.profile.tier.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            NavigationLink(destination: DeveloperProfileView()) {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            summaryCard(label: "Apps", value: "\(appService.apps.count)", icon: "square.grid.2x2")
            summaryCard(label: "Keys", value: "\(keyService.keys.filter { !$0.isRevoked }.count)", icon: "key")
            summaryCard(label: "Scopes", value: "\(scopeService.grantedScopes.count)", icon: "shield")
        }
    }

    private func summaryCard(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(.tertiary)
            Text(value).font(.headline)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func domainSection(title: String, icon: String, systems: [SystemLink]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon).font(.subheadline).foregroundStyle(.secondary)
                Text(title).font(.subheadline.bold())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(systems) { system in
                    NavigationLink(destination: system.destination) {
                        HStack(spacing: 12) {
                            Image(systemName: system.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text(system.title)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var healthStatusPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Health").font(.subheadline.bold())
            if appService.apps.isEmpty {
                Text("No active projects.").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 1) {
                    ForEach(appService.apps.prefix(3)) { app in
                        HStack {
                            Text(app.name).font(.caption.bold())
                            Spacer()
                            Circle().fill(app.status == .live ? Color.primary.opacity(0.8) : Color.primary.opacity(0.3)).frame(width: 6, height: 6)
                            Text(app.status.rawValue.uppercased()).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var recentActivityFeed: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity").font(.subheadline.bold())
            VStack(alignment: .leading, spacing: 12) {
                if activityService.activities.isEmpty {
                    Text("No recent activity.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(activityService.activities.prefix(3)) { activity in
                        HStack(alignment: .top, spacing: 12) {
                            Circle().fill(Color.primary.opacity(0.1)).frame(width: 4, height: 4).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.eventType.rawValue).font(.system(size: 10, weight: .bold))
                                Text(activity.description).font(.system(size: 9)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// Fixed duplicated name from memory instructions: DeveloperAppCertificatesView -> DeveloperAppAppCertificatesView
// Wait, memory said: Sources/Views/Workspace/Developer/DeveloperAppCertificatesView.swift
// Let's check the actual file name on disk.
