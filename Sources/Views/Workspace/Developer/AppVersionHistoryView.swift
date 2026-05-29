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
                    Text("No version history found.").foregroundStyle(.secondary)
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
                                    // Rollback logic
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
}
