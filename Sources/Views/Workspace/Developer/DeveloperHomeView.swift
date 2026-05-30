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
                quickActionsSection
                monitoringSection
                lifecycleSection
                healthStatusPanel
                recentActivityFeed
                noticesSection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Developer Portal")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            appService.loadApps()
            keyService.loadKeys()
            activityService.loadActivities()
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.1))
                if !profileService.profile.avatarUrl.isEmpty, let url = URL(string: profileService.profile.avatarUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
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
                    if profileService.profile.tier == .verified || profileService.profile.tier == .enterprise {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                }
                Text(profileService.profile.username.isEmpty ? "Unset Username" : "@\(profileService.profile.username) • \(profileService.profile.tier.rawValue) Developer")
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
            summaryCard(label: "Pending Scopes", value: "\(scopeService.pendingRequests.count)", icon: "shield.lefthalf.filled")
            summaryCard(label: "API Keys", value: "\(keyService.keys.filter { !$0.isRevoked }.count)", icon: "key.fill")
        }
    }

    private func summaryCard(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "App Workspace", subtitle: "Core Registration & Security", icon: "briefcase.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: AppBuilderView()) {
                    quickActionCard(title: "Register App", icon: "plus.app.fill", color: .blue)
                }
                NavigationLink(destination: AppManagementView()) {
                    quickActionCard(title: "Manage Apps", icon: "square.stack.3d.up", color: .orange)
                }
                NavigationLink(destination: AuthServiceManagerView()) {
                    quickActionCard(title: "Auth & Keys", icon: "key.fill", color: .mint)
                }
                NavigationLink(destination: ScopeManagementView()) {
                    quickActionCard(title: "Permissions", icon: "shield.fill", color: .red)
                }
                NavigationLink(destination: CLITokenView()) {
                    quickActionCard(title: "CLI Tokens", icon: "terminal.fill", color: .secondary)
                }
                NavigationLink(destination: DeveloperAppCertificatesView()) {
                    quickActionCard(title: "Certificates", icon: "doc.badge.gearshape.fill", color: .purple)
                }
            }
        }
    }

    private var monitoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Monitoring", subtitle: "Observability & Security Audit", icon: "eye.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: DeveloperLogsView()) {
                    quickActionCard(title: "System Logs", icon: "list.bullet.rectangle", color: .purple)
                }
                NavigationLink(destination: AnalyticsDashboardView()) {
                    quickActionCard(title: "Analytics", icon: "chart.xyaxis.line", color: .pink)
                }
                NavigationLink(destination: DeveloperSecurityAuditView()) {
                    quickActionCard(title: "Security Audit", icon: "lock.shield.fill", color: .red)
                }
                NavigationLink(destination: ErrorGroupingView()) {
                    quickActionCard(title: "Error Groups", icon: "exclamationmark.octagon.fill", color: .orange)
                }
                NavigationLink(destination: LogAlertRulesView()) {
                    quickActionCard(title: "Alert Rules", icon: "bell.badge.fill", color: .yellow)
                }
                NavigationLink(destination: WebhookManagerView()) {
                    quickActionCard(title: "Webhooks", icon: "antenna.radiowaves.left.and.right", color: .blue)
                }
            }
        }
    }

    private var lifecycleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Lifecycle", subtitle: "Release & Distribution", icon: "shippingbox.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: MarketplaceListingManagerView()) {
                    quickActionCard(title: "Marketplace", icon: "storefront.fill", color: .teal)
                }
                NavigationLink(destination: DeveloperReleaseManagementView()) {
                    quickActionCard(title: "Releases", icon: "arrow.up.doc.fill", color: .blue)
                }
                NavigationLink(destination: DeveloperBetaTestingView()) {
                    quickActionCard(title: "Beta Testing", icon: "testtube.2", color: .orange)
                }
                NavigationLink(destination: DeveloperMonetizationView()) {
                    quickActionCard(title: "Monetization", icon: "dollarsign.circle.fill", color: .green)
                }
                NavigationLink(destination: DocumentationEditorView()) {
                    quickActionCard(title: "Docs Editor", icon: "book.and.wrench.fill", color: .cyan)
                }
                NavigationLink(destination: TeamManagementView()) {
                    quickActionCard(title: "Team", icon: "person.2.fill", color: .indigo)
                }
            }
        }
    }

    private func quickActionCard(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var healthStatusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Health")
                .font(.headline)

            if appService.apps.isEmpty {
                VStack(spacing: 8) {
                    Text("No projects yet.").font(.subheadline.bold())
                    Text("Register an app to start tracking status.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 1) {
                    ForEach(appService.apps.prefix(3)) { app in
                        appStatusRow(name: app.name, type: app.type.rawValue, status: app.status)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            }
        }
    }

    private func appStatusRow(name: String, type: String, status: DeveloperAppStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.semibold))
                Text(type).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(statusColor(status)).frame(width: 8, height: 8)
                Text(status.rawValue).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.1), in: Capsule())
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func statusColor(_ status: DeveloperAppStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .underReview: return .orange
        case .live: return .sdkSuccess
        case .suspended: return .sdkError
        case .deprecated: return .secondary
        case .archived: return .black
        }
    }

    private var recentActivityFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                if activityService.activities.isEmpty {
                    Text("No activity records found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    ForEach(activityService.activities.prefix(5)) { activity in
                        activityRow(title: activity.eventType.rawValue, detail: activity.description, date: activity.timestamp)
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func activityRow(title: String, detail: String, date: Date) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(Color.accentColor).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.caption.bold())
                    Spacer()
                    Text(date.formatted(.relative(presentation: .numeric))).font(.caption2).foregroundStyle(.tertiary)
                }
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var noticesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if profileService.profile.displayName.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Profile Incomplete").font(.subheadline.weight(.semibold))
                        Text("Finish setting up your profile to enable all features.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    NavigationLink(destination: DeveloperProfileView()) {
                        Text("Finish").font(.caption.bold())
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            NavigationLink(destination: DeveloperSupportTicketView()) {
                HStack {
                    Label("Need Help? Contact Support", systemImage: "questionmark.circle.fill")
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
