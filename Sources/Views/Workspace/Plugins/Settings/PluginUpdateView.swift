import SwiftUI

struct PluginUpdateView: View {
    @StateObject private var manager = PluginManager.shared
    @State private var isChecking = false
    @State private var availableUpdates: [PluginUpdate] = []
    @State private var isUpdatingAll = false

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
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Plugin Updated")
                                .font(.caption)
                            Text("Updated successfully")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Plugin Updates")
        .task { await checkForUpdates() }
    }

    private func checkForUpdates() async {
        isChecking = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        availableUpdates = manager.installedPlugins.prefix(2).enumerated().map { index, plugin in
            PluginUpdate(
                pluginID: plugin.id,
                pluginName: plugin.name,
                currentVersion: "1.\(index).0",
                newVersion: "1.\(index + 1).0",
                changelog: "Bug fixes and performance improvements"
            )
        }
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
