import SwiftUI

struct DeveloperReleaseManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var selectedTrack: ReleaseTrack = .production
    @State private var showingReleaseCreator = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                appSelector

                if let appID = selectedAppID, let app = appService.apps.first(where: { $0.id == appID }) {
                    trackSelector

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(selectedTrack.rawValue) Releases").font(.headline)
                            Spacer()
                            Button { showingReleaseCreator = true } label: {
                                Label("New Release", systemImage: "plus.app")
                                    .font(.caption.bold())
                            }
                        }

                        let trackReleases = app.versions.filter { releaseTrack(for: $0) == selectedTrack }

                        if trackReleases.isEmpty {
                            EmptyStateView(icon: "shippingbox", title: "No \(selectedTrack.rawValue) Releases", message: "Start by promoting a build to this track.")
                        } else {
                            ForEach(trackReleases.sorted(by: { $0.createdAt > $1.createdAt })) { release in
                                releaseCard(release)
                            }
                        }
                    }
                    .padding()
                } else {
                    EmptyStateView(icon: "app.window.checkerboard", title: "Select an Application", message: "Choose an application to manage its release tracks and rollout status.")
                        .padding(.top, 40)
                }
            }
        }
        .navigationTitle("Builds & Releases")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            if selectedAppID == nil {
                selectedAppID = appService.apps.first?.id
            }
        }
        .sheet(isPresented: $showingReleaseCreator) {
            if let appID = selectedAppID {
                NewReleaseSheet(appID: appID)
            }
        }
    }

    private var appSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Project").font(.caption.bold()).foregroundStyle(.secondary)
            Picker("App", selection: $selectedAppID) {
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05)))
        }
        .padding()
    }

    private var trackSelector: some View {
        HStack(spacing: 0) {
            ForEach(ReleaseTrack.allCases, id: \.self) { track in
                Button {
                    selectedTrack = track
                } label: {
                    VStack(spacing: 8) {
                        Text(track.rawValue)
                            .font(.system(size: 12, weight: selectedTrack == track ? .bold : .medium))
                            .foregroundStyle(selectedTrack == track ? .primary : .secondary)

                        Rectangle()
                            .fill(selectedTrack == track ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func releaseCard(_ release: AppVersion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(release.version)").font(.subheadline.bold())
                    Text("Build \(release.buildNumber)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(release.status)
            }

            if !release.releaseNotes.isEmpty {
                Text(release.releaseNotes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack {
                Text(release.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Button {
                    // rollout details
                } label: {
                    Text("Details").font(.system(size: 10, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05)))
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.uppercased()).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.green.opacity(0.1), in: Capsule())
            .foregroundStyle(.green)
    }

    private func releaseTrack(for version: AppVersion) -> ReleaseTrack {
        // Simplified track logic based on status or version suffix
        if version.status.contains("Alpha") { return .alpha }
        if version.status.contains("Beta") { return .beta }
        return .production
    }
}

enum ReleaseTrack: String, CaseIterable {
    case production = "Production"
    case beta = "Beta"
    case alpha = "Alpha"
}

struct NewReleaseSheet: View {
    let appID: UUID
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var version = ""
    @State private var build = ""
    @State private var notes = ""
    @State private var track: ReleaseTrack = .production

    var body: some View {
        NavigationStack {
            Form {
                Section("Release Identity") {
                    TextField("Version Number (e.g. 1.2.0)", text: $version)
                    TextField("Build Number (e.g. 42)", text: $build)
                    Picker("Track", selection: $track) {
                        ForEach(ReleaseTrack.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                }

                Section("Release Notes") {
                    TextEditor(text: $notes).frame(height: 120)
                }

                Section {
                    Text("Submitting this release will immediately promote it to the selected track.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Release")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Release") {
                        let newVersion = AppVersion(version: version, buildNumber: build, releaseNotes: notes, status: track == .production ? "Released" : "\(track.rawValue) Released")
                        Task {
                            try? await appService.addVersion(appID: appID, version: newVersion)
                            await MainActor.run { dismiss() }
                        }
                    }
                    .disabled(version.isEmpty || build.isEmpty)
                }
            }
        }
    }
}
