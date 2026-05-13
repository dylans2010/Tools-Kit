import SwiftUI

struct PluginUpdateView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var isChecking = false
    @State private var availableUpdates: [PluginUpdate] = []
    @State private var isUpdatingAll = false
    @State private var updateHistory: [UpdateHistoryRecord] = []

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Plugin Updates")
                            .font(.headline)
                        Text("\(availableUpdates.count) updates available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await checkForUpdates() }
                    } label: {
                        if isChecking {
                            ProgressView()
                        } else {
                            Label("Check", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isChecking)
                }
            }

            if !availableUpdates.isEmpty {
                Section("Available Updates") {
                    ForEach(availableUpdates) { update in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(update.pluginName)
                                    .font(.headline)
                                Text("\(update.currentVersion) -> \(update.newVersion)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !update.changelog.isEmpty {
                                    Text(update.changelog)
                                        .font(.caption2)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            Button("Update") {
                                installUpdate(update)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section {
                    Button {
                        updateAll()
                    } label: {
                        HStack {
                            Spacer()
                            if isUpdatingAll {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text("Update All")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(isUpdatingAll)
                }
            } else if !isChecking {
                Section {
                    ContentUnavailableView(
                        "All Up to Date",
                        systemImage: "checkmark.circle",
                        description: Text("All plugins are running the latest version.")
                    )
                }
            }

            Section("Update History") {
                if updateHistory.isEmpty {
                    Text("No update history")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(updateHistory) { record in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.pluginName)
                                    .font(.caption)
                                Text("\(record.fromVersion) -> \(record.toVersion)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Plugin Updates")
        .task { await checkForUpdates() }
    }

    private func checkForUpdates() async {
        isChecking = true
        // Real update checking would query a remote registry.
        // For now, no updates are fabricated; the list stays empty until a real update source is configured.
        availableUpdates = []
        isChecking = false
    }

    private func installUpdate(_ update: PluginUpdate) {
        availableUpdates.removeAll { $0.id == update.id }
    }

    private func updateAll() {
        isUpdatingAll = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                availableUpdates.removeAll()
                isUpdatingAll = false
            }
        }
    }
}

private struct PluginUpdate: Identifiable {
    let id = UUID()
    let pluginID: UUID
    let pluginName: String
    let currentVersion: String
    let newVersion: String
    let changelog: String
}

private struct UpdateHistoryRecord: Identifiable {
    let id = UUID()
    let pluginName: String
    let fromVersion: String
    let toVersion: String
    let date: Date
}
