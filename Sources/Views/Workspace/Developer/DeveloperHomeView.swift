import SwiftUI
import Core

struct DeveloperHomeView: View {
    @State private var profile = DeveloperProfile(
        displayName: "Jules Engineer",
        username: "jules_dev",
        bio: "Full-stack developer building Tools-Kit integrations.",
        tier: .verified
    )

    @State private var recentActivity: [DeveloperLogEntry] = [
        DeveloperLogEntry(id: UUID(), timestamp: Date(), severity: .info, source: "Marketplace", eventType: "App Status", message: "Connector 'GitHub Pro' is now Live."),
        DeveloperLogEntry(id: UUID(), timestamp: Date().addingTimeInterval(-3600), severity: .warn, source: "Auth", eventType: "Token Expiry", message: "API Key 'Production_Sync' expires in 48 hours."),
        DeveloperLogEntry(id: UUID(), timestamp: Date().addingTimeInterval(-7200), severity: .info, source: "Scope", eventType: "Approval", message: "Scope 'Write:User' granted for App 'Messenger'."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                summaryStrip
                quickActionsSection
                healthStatusPanel
                recentActivityFeed
                noticesSection
                trendingSection
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
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.displayName)
                        .font(.title3.bold())
                    if profile.tier == .verified || profile.tier == .enterprise {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                }
                Text("@\(profile.username) • \(profile.tier.rawValue) Developer")
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
            summaryCard(label: "Apps", value: "12", icon: "square.grid.2x2")
            summaryCard(label: "Installs", value: "1.2k", icon: "arrow.down.circle")
            summaryCard(label: "Scopes", value: "3", icon: "lock.shield")
            summaryCard(label: "Tickets", value: "0", icon: "lifepreserver")
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
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: MarketplaceSubmissionView()) {
                    quickActionCard(title: "Submit App", icon: "plus.app", color: .blue)
                }
                NavigationLink(destination: ScopeManagementView()) {
                    quickActionCard(title: "Request Scope", icon: "key.fill", color: .orange)
                }
                NavigationLink(destination: DeveloperLogsView()) {
                    quickActionCard(title: "View Logs", icon: "list.bullet.rectangle", color: .purple)
                }
                NavigationLink(destination: DeveloperProfileView()) {
                    quickActionCard(title: "Edit Profile", icon: "person.text.rectangle", color: .green)
                }
                NavigationLink(destination: DocumentationEditorView()) {
                    quickActionCard(title: "Docs Editor", icon: "book.and.wrench", color: .cyan)
                }
                NavigationLink(destination: AnalyticsDashboardView()) {
                    quickActionCard(title: "Analytics", icon: "chart.xyaxis.line", color: .pink)
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
            Text("App Health & Status")
                .font(.headline)

            VStack(spacing: 1) {
                appStatusRow(name: "GitHub Pro", type: "Connector", status: .live)
                appStatusRow(name: "Mail AI Bot", type: "Plugin", status: .underReview)
                appStatusRow(name: "Legacy Sync", type: "Service", status: .deprecated)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private func appStatusRow(name: String, type: String, status: AppStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.semibold))
                Text(type).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(status.color).frame(width: 8, height: 8)
                Text(status.rawValue).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1), in: Capsule())
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var recentActivityFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(recentActivity) { log in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(log.severity.color).frame(width: 8, height: 8).padding(.top, 5)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.eventType).font(.caption.bold())
                                Spacer()
                                Text(log.timestamp.formatted(.dateTime.hour().minute())).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Text(log.message).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var noticesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notices & Alerts")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Identity Verification Required").font(.subheadline.weight(.semibold))
                    Text("Complete verification to unlock High-risk scopes.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending in Developer Tools")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                trendItem(title: "SDK v2.4 Release Notes", subtitle: "New Metal-accelerated UI primitives.")
                Divider()
                trendItem(title: "Security Best Practices", subtitle: "Managing OAuth tokens in shared environments.")
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func trendItem(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.medium))
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}
