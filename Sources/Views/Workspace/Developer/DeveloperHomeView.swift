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
                healthStatusPanel
                developerToolsSection
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
            Text("Developer Workspace")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: AppBuilderView()) {
                    quickActionCard(title: "Register App", icon: "plus.app.fill", color: .blue)
                }
                NavigationLink(destination: AppManagementView()) {
                    quickActionCard(title: "Manage Apps", icon: "square.stack.3d.up", color: .orange)
                }
                NavigationLink(destination: AuthServiceManagerView()) {
                    quickActionCard(title: "Auth & Webhooks", icon: "key.fill", color: .mint)
                }
                NavigationLink(destination: ScopeManagementView()) {
                    quickActionCard(title: "Permissions", icon: "shield.fill", color: .red)
                }
                NavigationLink(destination: DocumentationEditorView()) {
                    quickActionCard(title: "Docs Editor", icon: "book.and.wrench", color: .cyan)
                }
                NavigationLink(destination: MarketplaceListingManagerView()) {
                    quickActionCard(title: "Marketplace", icon: "storefront.fill", color: .teal)
                }
                NavigationLink(destination: DeveloperLogsView()) {
                    quickActionCard(title: "View Logs", icon: "list.bullet.rectangle", color: .purple)
                }
                NavigationLink(destination: AnalyticsDashboardView()) {
                    quickActionCard(title: "Analytics", icon: "chart.xyaxis.line", color: .pink)
                }
            }
        }
    }

    private var developerToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer Tools")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    toolLink(title: "JSON", icon: "braces", destination: AnyView(DeveloperJSONFormatterView()))
                    toolLink(title: "Base64", icon: "number", destination: AnyView(Base64ToolView()))
                    toolLink(title: "URL", icon: "link", destination: AnyView(URLEncoderView()))
                    toolLink(title: "JWT", icon: "shield.text.ascii", destination: AnyView(JWTDebuggerView()))
                    toolLink(title: "Markdown", icon: "doc.text", destination: AnyView(MarkdownPreviewerView()))
                    toolLink(title: "UUID", icon: "barcode", destination: AnyView(DeveloperUUIDGeneratorView()))
                    toolLink(title: "Hash", icon: "lock.rectangle", destination: AnyView(DeveloperHashGeneratorView()))
                    toolLink(title: "Password", icon: "key.viewfinder", destination: AnyView(DeveloperPasswordGeneratorView()))
                    toolLink(title: "Regex", icon: "text.magnifyingglass", destination: AnyView(DeveloperRegexTesterView()))
                    toolLink(title: "Certs", icon: "seal", destination: AnyView(CertificateValidatorView()))
                    toolLink(title: "Device", icon: "iphone", destination: AnyView(DeviceInspectorView()))
                    toolLink(title: "Color", icon: "paintpalette", destination: AnyView(ColorConverterView()))
                    toolLink(title: "Units", icon: "scalemass", destination: AnyView(DeveloperUnitConverterView()))
                    toolLink(title: "Cron", icon: "clock.arrow.2.circlepath", destination: AnyView(CronParserView()))
                    toolLink(title: "HTTP", icon: "network", destination: AnyView(HTTPRequestBuilderView()))
                    toolLink(title: "Diff", icon: "arrow.left.and.right", destination: AnyView(DiffToolView()))
                    toolLink(title: "HTML", icon: "chevron.left.forwardslash.chevron.right", destination: AnyView(HTMLInspectorView()))
                    toolLink(title: "Locales", icon: "character.bubble", destination: AnyView(LocalizationHelperView()))
                    toolLink(title: "Network", icon: "waveform.path.ecg", destination: AnyView(NetworkReachabilityView()))
                    toolLink(title: "Metadata", icon: "info.circle", destination: AnyView(ImageMetadataView()))
                }
            }
        }
    }

    private func toolLink(title: String, icon: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(width: 80, height: 80)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
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
        case .live: return .green
        case .suspended: return .red
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
        }
    }
}
