import SwiftUI

struct DeveloperHomeView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var activityService = DeveloperActivityService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                summaryStrip

                VStack(alignment: .leading, spacing: 24) {
                    domainSection(title: "Applications", icon: "app.window.checkerboard", systems: [
                        SystemLink(title: "App Manager", destination: AnyView(AppManagementView()), icon: "square.stack.3d.up"),
                        SystemLink(title: "Integrations", destination: AnyView(DeveloperIntegrationGalleryView()), icon: "puzzlepiece.fill"),
                        SystemLink(title: "Remote Config", destination: AnyView(DeveloperRemoteConfigView()), icon: "gearshape.2"),
                        SystemLink(title: "App Builder", destination: AnyView(AppBuilderView()), icon: "plus.app.fill")
                    ])

                    domainSection(title: "Pipeline & Operations", icon: "arrow.triangle.pull", systems: [
                        SystemLink(title: "CI/CD Pipelines", destination: AnyView(DeveloperDeploymentPipelineView()), icon: "hammer.fill"),
                        SystemLink(title: "Releases", destination: AnyView(DeveloperReleaseManagementView()), icon: "shippingbox.fill"),
                        SystemLink(title: "Beta Testing", destination: AnyView(DeveloperBetaTestingView()), icon: "person.3.sequence.fill"),
                        SystemLink(title: "Team Manager", destination: AnyView(DeveloperTeamManagerView()), icon: "person.2.fill")
                    ])

                    domainSection(title: "Observability & Health", icon: "eye.fill", systems: [
                        SystemLink(title: "System Logs", destination: AnyView(DeveloperLogsView()), icon: "list.bullet.rectangle"),
                        SystemLink(title: "Infrastructure", destination: AnyView(DeveloperInfrastructureStatusView()), icon: "waveform.path.ecg"),
                        SystemLink(title: "Database", destination: AnyView(DeveloperDatabaseManagerView()), icon: "tablecells"),
                        SystemLink(title: "Analytics", destination: AnyView(AnalyticsDashboardView()), icon: "chart.xyaxis.line")
                    ])

                    domainSection(title: "Security & Privacy", icon: "lock.shield.fill", systems: [
                        SystemLink(title: "Auth & Webhooks", destination: AnyView(AuthServiceManagerView()), icon: "key.fill"),
                        SystemLink(title: "Secrets Manager", destination: AnyView(DeveloperSecretsManagerView()), icon: "lock.rectangle"),
                        SystemLink(title: "Webhooks", destination: AnyView(DeveloperWebhookManagerView()), icon: "bolt.horizontal.fill"),
                        SystemLink(title: "Security Audit", destination: AnyView(DeveloperSecurityAuditView()), icon: "checkmark.shield")
                    ])

                    domainSection(title: "Compliance & Identity", icon: "checkmark.seal.fill", systems: [
                        SystemLink(title: "Permissions", destination: AnyView(ScopeManagementView()), icon: "shield.lefthalf.filled"),
                        SystemLink(title: "Certificates", destination: AnyView(DeveloperAppCertificatesView()), icon: "doc.badge.gearshape"),
                        SystemLink(title: "Privacy Manifest", destination: AnyView(PrivacyManifestEditorView()), icon: "hand.raised.fill"),
                        SystemLink(title: "Data Policies", destination: AnyView(DataHandlingPolicyBuilderView()), icon: "doc.text.magnifyingglass"),
                        SystemLink(title: "Verification", destination: AnyView(DeveloperVerificationView()), icon: "person.badge.shield.checkmark")
                    ])

                    domainSection(title: "Global Resources", icon: "globe", systems: [
                        SystemLink(title: "Localization", destination: AnyView(DeveloperLocalizationManagerView()), icon: "character.book.closed.fill"),
                        SystemLink(title: "Doc Localization", destination: AnyView(DocumentationLocalizationView()), icon: "text.book.closed.fill"),
                        SystemLink(title: "Docs Editor", destination: AnyView(DocumentationEditorView()), icon: "book.and.wrench"),
                        SystemLink(title: "Marketplace", destination: AnyView(MarketplaceListingManagerView()), icon: "storefront.fill"),
                        SystemLink(title: "Organization", destination: AnyView(OrganizationManagementView()), icon: "building.2.fill")
                    ])

                    domainSection(title: "System Insights", icon: "chart.bar.doc.horizontal", systems: [
                        SystemLink(title: "Crash Reports", destination: AnyView(DeveloperCrashReportView()), icon: "heart.text.square"),
                        SystemLink(title: "Performance", destination: AnyView(DeveloperPerformanceMonitorView()), icon: "gauge.with.needle"),
                        SystemLink(title: "Network Traffic", destination: AnyView(DeveloperNetworkTrafficView()), icon: "wifi.router"),
                        SystemLink(title: "Feature Flags", destination: AnyView(DeveloperFeatureFlagView()), icon: "flag.fill")
                    ])

                    domainSection(title: "Support & Identity", icon: "person.crop.circle.badge.questionmark", systems: [
                        SystemLink(title: "Account Activity", destination: AnyView(DeveloperAccountActivityView()), icon: "person.text.rectangle"),
                        SystemLink(title: "Profile", destination: AnyView(DeveloperProfileView()), icon: "person.crop.circle"),
                        SystemLink(title: "Support Tickets", destination: AnyView(DeveloperSupportTicketView()), icon: "questionmark.circle"),
                        SystemLink(title: "CLI Tokens", destination: AnyView(CLITokenView()), icon: "terminal")
                    ])
                }

                healthStatusPanel
                recentActivityFeed
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Developer Portal")
        .navigationBarTitleDisplayMode(.inline)
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
                                .foregroundStyle(.secondary)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(profileService.profile.displayName.isEmpty ? "Developer" : profileService.profile.displayName)
                    .font(.headline)
                Text("@\(profileService.profile.username) • \(profileService.profile.tier.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func domainSection(title: String, icon: String, systems: [SystemLink]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.subheadline).foregroundStyle(.primary)
                Text(title).font(.subheadline.bold())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(systems) { system in
                    NavigationLink(destination: system.destination) {
                        HStack {
                            Image(systemName: system.icon).font(.caption).foregroundStyle(.secondary)
                            Text(system.title).font(.caption)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var healthStatusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Health").font(.headline)
            if appService.apps.isEmpty {
                Text("No active projects.").font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(appService.apps.prefix(3)) { app in
                        HStack {
                            Text(app.name).font(.caption.bold())
                            Spacer()
                            Circle().fill(app.status == .live ? .green : .orange).frame(width: 6, height: 6)
                            Text(app.status.rawValue.uppercased()).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var recentActivityFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity").font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                if activityService.activities.isEmpty {
                    Text("No recent activity.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(activityService.activities.prefix(3)) { activity in
                        HStack(alignment: .top, spacing: 10) {
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
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SystemLink: Identifiable {
    let id = UUID()
    let title: String
    let destination: AnyView
    let icon: String
}
