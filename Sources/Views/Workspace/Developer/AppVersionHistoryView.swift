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
                    Section {
                        EmptyStateView(icon: "clock.arrow.circlepath", title: "No History", message: "No previous versions found for this project.")
                    }
                } else {
                    ForEach(app.versions) { version in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("v\(version.version)").font(.headline)
                                Spacer()
                                Text(version.status).font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.blue)
                            }

                            Text("Build \(version.buildNumber) • \(version.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)

                            if !version.releaseNotes.isEmpty {
                                Text(version.releaseNotes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }

                            HStack {
                                ProgressView(value: version.rolloutPercentage, total: 1.0)
                                Text("\(Int(version.rolloutPercentage * 100))% Rollout").font(.caption2).foregroundStyle(.secondary)
                            }

                            if version.status != "Current" {
                                Button("Rollback to this version") {
                                    rollback(to: version)
                                }
                                .font(.caption.bold())
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Version History")
    }

    private func rollback(to version: AppVersion) {
        guard var updatedApp = app else { return }
        updatedApp.version = version.version
        // Additional logic for updating status of versions
        Task {
            try? await appService.updateApp(updatedApp)
        }
    }
}
