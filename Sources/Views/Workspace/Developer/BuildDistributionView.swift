import SwiftUI

struct BuildDistributionView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var distributionService = BuildDistributionService.shared
    @State private var selectedAppID: UUID?
    @State private var showingCreateDistribution = false
    @State private var selectedVersionID: UUID?
    @State private var selectedChannel: DistributionChannel = .internalTest
    @State private var selectedPlatform = "iOS"

    var body: some View {
        List {
            Section("Project Selection") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if let appID = selectedAppID {
                Section("Active Distributions") {
                    let filtered = distributionService.distributions.filter { $0.appID == appID }
                    if filtered.isEmpty {
                        Text("No active distributions for this project.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(filtered) { dist in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(dist.platform) • \(dist.distributionChannel.rawValue)").font(.subheadline.bold())
                                    Text(dist.status.rawValue).font(.caption).foregroundStyle(statusColor(dist.status))
                                }
                                Spacer()
                                if let releasedAt = dist.releasedAt {
                                    Text(releasedAt, style: .date).font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }

                    Button {
                        showingCreateDistribution = true
                    } label: {
                        Label("New Distribution", systemImage: "paperplane.fill")
                    }
                }
            }
        }
        .navigationTitle("Build Distribution")
        .sheet(isPresented: $showingCreateDistribution) {
            createDistributionSheet
        }
    }

    private var createDistributionSheet: some View {
        NavigationStack {
            Form {
                if let app = appService.apps.first(where: { $0.id == selectedAppID }) {
                    Section("Target Build") {
                        Picker("Version", selection: $selectedVersionID) {
                            Text("Select Version").tag(Optional<UUID>.none)
                            ForEach(app.versions) { version in
                                Text("v\(version.version) (\(version.buildNumber))").tag(Optional(version.id))
                            }
                        }
                    }

                    Section("Distribution Channel") {
                        Picker("Channel", selection: $selectedChannel) {
                            ForEach(DistributionChannel.allCases, id: \.self) { channel in
                                Text(channel.rawValue).tag(channel)
                            }
                        }
                        Picker("Platform", selection: $selectedPlatform) {
                            ForEach(["iOS", "macOS", "tvOS", "watchOS"], id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Distribution")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCreateDistribution = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        if let appID = selectedAppID, let versionID = selectedVersionID {
                            Task {
                                await distributionService.createDistribution(appID: appID, versionID: versionID, platform: selectedPlatform, channel: selectedChannel)
                                await MainActor.run { showingCreateDistribution = false }
                            }
                        }
                    }
                    .disabled(selectedVersionID == nil)
                }
            }
        }
    }

    private func statusColor(_ status: DistributionStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .processing: return .orange
        case .released: return .green
        case .rejected: return .red
        }
    }
}
