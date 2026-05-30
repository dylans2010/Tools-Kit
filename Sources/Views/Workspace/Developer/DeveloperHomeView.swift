import SwiftUI

struct DeveloperHomeView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var activityService = DeveloperActivityService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                summaryStrip

                VStack(alignment: .leading, spacing: 16) {
                    Text("Management Domains").font(.headline)

                    domainSection(title: "Applications", icon: "app.window.checkerboard", color: .blue, systems: [
                        SystemLink(title: "App Manager", destination: AnyView(AppManagementView()), icon: "square.stack.3d.up"),
                        SystemLink(title: "Builds & Releases", destination: AnyView(DeveloperReleaseManagementView()), icon: "shippingbox.fill"),
                        SystemLink(title: "Marketplace", destination: AnyView(MarketplaceListingManagerView()), icon: "storefront.fill"),
                        SystemLink(title: "App Builder", destination: AnyView(AppBuilderView()), icon: "plus.app.fill")
                    ])

                    domainSection(title: "Pipeline & Distribution", icon: "arrow.triangle.pull", color: .orange, systems: [
                        SystemLink(title: "CI/CD Pipelines", destination: AnyView(DeveloperDeploymentPipelineView()), icon: "hammer.fill"),
                        SystemLink(title: "Beta Testing", destination: AnyView(DeveloperBetaTestingView()), icon: "person.3.sequence.fill"),
                        SystemLink(title: "Certificates", destination: AnyView(DeveloperAppCertificatesView()), icon: "doc.badge.gearshape")
                    ])

                    domainSection(title: "Observability", icon: "eye.fill", color: .purple, systems: [
                        SystemLink(title: "System Logs", destination: AnyView(DeveloperLogsView()), icon: "list.bullet.rectangle"),
                        SystemLink(title: "Analytics", destination: AnyView(AnalyticsDashboardView()), icon: "chart.xyaxis.line"),
                        SystemLink(title: "Performance (APM)", destination: AnyView(DeveloperPerformanceMonitorView()), icon: "gauge.with.needle"),
                        SystemLink(title: "Crash Reports", destination: AnyView(DeveloperCrashReportView()), icon: "heart.text.square")
                    ])

                    domainSection(title: "Security & Configuration", icon: "shield.fill", color: .red, systems: [
                        SystemLink(title: "Auth & Webhooks", destination: AnyView(AuthServiceManagerView()), icon: "key.fill"),
                        SystemLink(title: "Permissions", destination: AnyView(ScopeManagementView()), icon: "shield.lefthalf.filled"),
                        SystemLink(title: "Secrets Manager", destination: AnyView(DeveloperSecretsManagerView()), icon: "lock.rectangle"),
                        SystemLink(title: "Feature Flags", destination: AnyView(DeveloperFeatureFlagView()), icon: "flag.fill"),
                        SystemLink(title: "Remote Config", destination: AnyView(DeveloperRemoteConfigView()), icon: "gearshape.2")
                    ])

                    domainSection(title: "Data & System Health", icon: "server.rack", color: .green, systems: [
                        SystemLink(title: "Database Manager", destination: AnyView(DeveloperDatabaseManagerView()), icon: "tablecells"),
                        SystemLink(title: "Incident Manager", destination: AnyView(DeveloperIncidentManagerView()), icon: "exclamationmark.triangle.fill"),
                        SystemLink(title: "Infra Status", destination: AnyView(DeveloperInfrastructureStatusView()), icon: "waveform.path.ecg"),
                        SystemLink(title: "Network Traffic", destination: AnyView(DeveloperNetworkTrafficView()), icon: "wifi.router")
                    ])

                    domainSection(title: "Global Operations", icon: "globe", color: .cyan, systems: [
                        SystemLink(title: "Localization", destination: AnyView(DeveloperLocalizationManagerView()), icon: "character.book.closed.fill"),
                        SystemLink(title: "Docs Editor", destination: AnyView(DocumentationEditorView()), icon: "book.and.wrench"),
                        SystemLink(title: "Team Manager", destination: AnyView(DeveloperTeamManagerView()), icon: "person.2.fill")
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
                Circle().fill(Color.accentColor.opacity(0.1))
                if !profileService.profile.avatarUrl.isEmpty, let url = URL(string: profileService.profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.red)
                        } else {
                            ProgressView()
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profileService.profile.displayName.isEmpty ? "Complete your Profile" : profileService.profile.displayName)
                        .font(.title3.bold())
                }
                Text("@\(profileService.profile.username) • \(profileService.profile.tier.rawValue) Developer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            summaryCard(label: "Apps", value: "\(appService.apps.count)", icon: "square.grid.2x2")
            summaryCard(label: "Installs", value: "\(appService.apps.reduce(0) { $0 + $1.installCount })", icon: "arrow.down.circle")
            summaryCard(label: "API Keys", value: "\(keyService.keys.filter { !$0.isRevoked }.count)", icon: "key.fill")
        }
    }

    private func summaryCard(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func domainSection(title: String, icon: String, color: Color, systems: [SystemLink]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline.bold())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(systems) { system in
                    NavigationLink(destination: system.destination) {
                        HStack {
                            Image(systemName: system.icon).font(.caption).foregroundStyle(color)
                            Text(system.title).font(.caption.weight(.medium))
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(color.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.1), lineWidth: 1))
    }

    private var healthStatusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Health").font(.headline)
            if appService.apps.isEmpty {
                Text("No active projects.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(appService.apps.prefix(3)) { app in
                    HStack {
                        Text(app.name).font(.subheadline.bold())
                        Spacer()
                        Circle().fill(app.status == .live ? .green : .orange).frame(width: 8, height: 8)
                        Text(app.status.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    ForEach(activityService.activities.prefix(5)) { activity in
                        HStack(alignment: .top) {
                            Circle().fill(Color.accentColor).frame(width: 6, height: 6).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.eventType.rawValue).font(.caption.bold())
                                Text(activity.description).font(.caption2).foregroundStyle(.secondary)
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
