import SwiftUI
import Core

struct DeveloperHomeView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                summaryStrip
                quickActionsSection
                healthStatusPanel
                recentActivityFeed
                noticesSection
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
                if let avatarUrl = store.profile.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
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
                    Text(store.profile.displayName.isEmpty ? "Complete your Profile" : store.profile.displayName)
                        .font(.title3.bold())
                    if store.profile.tier == .verified || store.profile.tier == .enterprise {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                }
                Text(store.profile.username.isEmpty ? "Unset Username" : "@\(store.profile.username) • \(store.profile.tier.rawValue) Developer")
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
            summaryCard(label: "Apps", value: "\(store.apps.count)", icon: "square.grid.2x2")
            summaryCard(label: "Installs", value: "\(store.apps.reduce(0) { $0 + $1.installCount })", icon: "arrow.down.circle")
            summaryCard(label: "API Keys", value: "\(store.keys.count)", icon: "key.fill")
            summaryCard(label: "Support", value: "0", icon: "lifepreserver")
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
                NavigationLink(destination: AppBuilderView()) {
                    quickActionCard(title: "App Builder", icon: "hammer.fill", color: .blue)
                }
                NavigationLink(destination: AppManagementView()) {
                    quickActionCard(title: "Manage Apps", icon: "square.stack.3d.up", color: .orange)
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
            Text("Your Projects")
                .font(.headline)

            if store.apps.isEmpty {
                Text("No projects yet. Start by building or submitting an app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 1) {
                    ForEach(store.apps.prefix(3)) { app in
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
                if store.keys.isEmpty && store.apps.isEmpty {
                    Text("No recent activity recorded.").font(.caption).foregroundStyle(.secondary)
                } else {
                    // In a real app, this would be fetched from a log service.
                    // Here we show some contextual activity based on store state.
                    if let lastKey = store.keys.last {
                        activityRow(title: "Key Generated", detail: "API Key '\(lastKey.name)' was created.", date: lastKey.createdAt, color: .blue)
                    }
                    if let lastApp = store.apps.last {
                        activityRow(title: "App Created", detail: "Project '\(lastApp.name)' was added.", date: lastApp.createdAt, color: .green)
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func activityRow(title: String, detail: String, date: Date, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.caption.bold())
                    Spacer()
                    Text(date.formatted(.dateTime.hour().minute())).font(.caption2).foregroundStyle(.tertiary)
                }
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var noticesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.profile.displayName.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Profile Incomplete").font(.subheadline.weight(.semibold))
                        Text("Finish setting up your profile to enable all features.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
