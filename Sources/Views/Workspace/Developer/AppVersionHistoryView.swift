import SwiftUI

struct AppVersionHistoryView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        List {
            if let app = app {
                if app.versions.isEmpty {
                    EmptyStateView(icon: "clock.arrow.circlepath", title: "No Versions", message: "Register a build to start tracking the version history for this application.")
                } else {
                    ForEach(app.versions.sorted(by: { $0.createdAt > $1.createdAt })) { version in
                        versionRow(version, app: app)
                    }
                }
            }
        }
        .navigationTitle("Version History")
    }

    private func versionRow(_ version: AppVersion, app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(version.version)").font(.headline)
                    Text("Build \(version.buildNumber)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(version.status)
            }

            if !version.releaseNotes.isEmpty {
                Text(version.releaseNotes)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Rollout Status").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                    Spacer()
                    Text("\(Int(version.rolloutPercentage * 100))%").font(.system(size: 9, weight: .black))
                }
                ProgressView(value: version.rolloutPercentage, total: 1.0)
                    .tint(version.status == "Released" ? .green : .blue)
            }

            HStack {
                Text(version.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)

                Spacer()

                if version.version != app.version {
                    Button {
                        rollback(to: version)
                    } label: {
                        Text("Rollback").font(.system(size: 10, weight: .bold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(status == "Released" ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
            .foregroundStyle(status == "Released" ? .green : .blue)
            .clipShape(Capsule())
    }

    private func rollback(to version: AppVersion) {
        guard var updatedApp = app else { return }
        updatedApp.version = version.version
        Task {
            try? await appService.updateApp(updatedApp)
            await DeveloperActivityService.shared.logEvent(
                eventType: .appUpdated,
                appID: appID,
                appName: "\(updatedApp.name) (Rolled back to v\(version.version))"
            )
        }
    }
}
