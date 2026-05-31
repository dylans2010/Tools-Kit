import SwiftUI

struct DeveloperHomeView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                statsOverview

                VStack(alignment: .leading, spacing: 32) {
                    domainGrid(title: "Applications", icon: "app.window.checkerboard", systems: [
                        ("App Manager", AnyView(AppManagementView()), "square.stack.3d.up"),
                        ("App Builder", AnyView(AppBuilderView()), "plus.app"),
                        ("Integrations", AnyView(DeveloperIntegrationGalleryView()), "puzzlepiece"),
                        ("Remote Config", AnyView(DeveloperRemoteConfigView()), "slider.horizontal.3"),
                        ("Project Installer", AnyView(ProjectInstallerView()), "square.and.arrow.down")
                    ])

                    domainGrid(title: "Operations & Delivery", icon: "arrow.triangle.pull", systems: [
                        ("CI/CD Pipelines", AnyView(DeveloperDeploymentPipelineView()), "hammer"),
                        ("Releases", AnyView(DeveloperReleaseManagementView()), "shippingbox"),
                        ("Beta Testing", AnyView(DeveloperBetaTestingView()), "person.3.sequence"),
                        ("Sandbox Env", AnyView(DeveloperSandboxEnvironmentView()), "square.dashed")
                    ])

                    domainGrid(title: "Observability", icon: "eye", systems: [
                        ("System Logs", AnyView(DeveloperLogsView()), "list.bullet.rectangle"),
                        ("Infrastructure", AnyView(DeveloperInfrastructureStatusView()), "cpu"),
                        ("Database", AnyView(DeveloperDatabaseManagerView()), "tablecells"),
                        ("Analytics", AnyView(AnalyticsDashboardView()), "chart.xyaxis.line"),
                        ("Log Drains", AnyView(LogDrainConfigView()), "externaldrive.badge.plus")
                    ])

                    domainGrid(title: "Security & Privacy", icon: "lock.shield", systems: [
                        ("Auth Manager", AnyView(AuthServiceManagerView()), "key"),
                        ("Secrets", AnyView(DeveloperSecretsManagerView()), "lock.rectangle"),
                        ("Webhooks", AnyView(WebhookManagerView()), "bolt.horizontal"),
                        ("Security Audit", AnyView(DeveloperSecurityAuditView()), "checkmark.shield"),
                        ("Security Policies", AnyView(DeveloperSecurityPolicyView()), "shield.checkered")
                    ])

                    domainGrid(title: "Compliance & Identity", icon: "checkmark.seal", systems: [
                        ("Permissions", AnyView(ScopeManagementView()), "shield.lefthalf.filled"),
                        ("Certificates", AnyView(DeveloperAppCertificatesView()), "doc.badge.gearshape"),
                        ("Privacy Manifest", AnyView(PrivacyManifestEditorView()), "hand.raised"),
                        ("Data Policies", AnyView(DataHandlingPolicyBuilderView()), "doc.text.magnifyingglass"),
                        ("Compliance Audit", AnyView(ComplianceChecklistView()), "checklist")
                    ])

                    domainGrid(title: "Global Resources", icon: "globe", systems: [
                        ("Localization", AnyView(DeveloperLocalizationManagerView()), "character.book.closed"),
                        ("Docs Editor", AnyView(DocumentationEditorView()), "book.and.wrench"),
                        ("Marketplace", AnyView(MarketplaceListingManagerView()), "storefront"),
                        ("Organization", AnyView(OrganizationManagementView()), "building.2"),
                        ("Doc Localization", AnyView(DocumentationLocalizationView()), "text.book.closed")
                    ])

                    domainGrid(title: "Insights & Performance", icon: "chart.bar.doc.horizontal", systems: [
                        ("Crash Reports", AnyView(DeveloperCrashReportView()), "heart.text.square"),
                        ("Performance", AnyView(DeveloperPerformanceMonitorView()), "gauge.with.needle"),
                        ("Network Traffic", AnyView(DeveloperNetworkTrafficView()), "wifi.router"),
                        ("Feature Flags", AnyView(DeveloperFeatureFlagView()), "flag"),
                        ("Error Grouping", AnyView(ErrorGroupingView()), "square.grid.3x1.below.line.grid.1x2")
                    ])

                    domainGrid(title: "Account & Support", icon: "person.crop.circle", systems: [
                        ("Account Activity", AnyView(DeveloperAccountActivityView()), "person.text.rectangle"),
                        ("Profile", AnyView(DeveloperProfileView()), "person.crop.circle"),
                        ("Verification", AnyView(DeveloperVerificationView()), "person.badge.shield.checkmark"),
                        ("Support Tickets", AnyView(DeveloperSupportTicketView()), "questionmark.circle"),
                        ("CLI Tokens", AnyView(CLITokenView()), "terminal")
                    ])
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.primary.opacity(0.03))
                if !profileService.profile.avatarUrl.isEmpty, let url = URL(string: profileService.profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.quaternary)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 1) {
                Text(profileService.profile.displayName.isEmpty ? "Developer" : profileService.profile.displayName)
                    .font(.system(size: 16, weight: .semibold))
                Text("@\(profileService.profile.username) • \(profileService.profile.tier.rawValue)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var statsOverview: some View {
        HStack(spacing: 12) {
            statItem(label: "Apps", value: "\(appService.apps.count)", icon: "square.grid.2x2")
            statItem(label: "API Keys", value: "\(keyService.keys.filter { !$0.isRevoked }.count)", icon: "key")
            statItem(label: "Scopes", value: "\(scopeService.grantedScopes.count)", icon: "shield")
        }
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 16, weight: .bold))
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func domainGrid(title: String, icon: String, systems: [(String, AnyView, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .bold)).textCase(.uppercase).tracking(1)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<systems.count, id: \.self) { index in
                    let system = systems[index]
                    NavigationLink(destination: system.1) {
                        HStack(spacing: 12) {
                            Image(systemName: system.2)
                                .font(.system(size: 14))
                                .frame(width: 28, height: 28)
                                .background(Color.primary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(system.0)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
