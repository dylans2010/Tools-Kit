import SwiftUI

struct AppDetailView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedTab = 0

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        Group {
            if let app = app {
                ScrollView {
                    VStack(spacing: 20) {
                        appHeader(app)

                        Picker("Details", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Versions").tag(1)
                            Text("Scopes").tag(2)
                            Text("Auth").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch selectedTab {
                        case 0:
                            overviewTab(app)
                        case 1:
                            versionsTab(app)
                        case 2:
                            scopesTab(app)
                        case 3:
                            authTab(app)
                        default:
                            Color.clear
                        }
                    }
                }
            } else {
                Text("App not found").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("App Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func appHeader(_ app: DeveloperApp) -> some View {
        HStack(spacing: 16) {
            Image(systemName: app.iconName)
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.title2.bold())
                Text(app.bundleId).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text(app.type.rawValue).font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                    statusBadge(app.status)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func statusBadge(_ status: DeveloperAppStatus) -> some View {
        Text(status.rawValue).font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
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

    private func overviewTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            infoSection(title: "Description", content: app.description)
            infoSection(title: "Version", content: app.version)
            infoSection(title: "Installs", content: "\(app.installCount)")
            infoSection(title: "Monetization", content: app.monetizationModel.rawValue)
        }
        .padding()
    }

    private func versionsTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if app.versions.isEmpty {
                Text("No version history available.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(app.versions) { version in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("v\(version.version) (\(version.buildNumber))").font(.subheadline.bold())
                            Text(version.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(version.status).font(.caption2)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }

    private func scopesTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Granted Scopes").font(.headline)
            if app.grantedScopes.isEmpty {
                Text("No scopes granted to this app.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(app.grantedScopes, id: \.self) { scope in
                    Text(scope).font(.caption.monospaced())
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
    }

    private func authTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned API Keys").font(.headline)
            Text("API Keys are managed in the Auth & Webhooks section.").font(.caption).foregroundStyle(.secondary)

            NavigationLink(destination: AuthServiceManagerView()) {
                Text("Manage API Keys")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            Text(content.isEmpty ? "Not provided" : content).font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
