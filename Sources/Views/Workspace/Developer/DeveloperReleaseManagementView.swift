import SwiftUI

struct DeveloperReleaseManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var selectedTrack: ReleaseTrack = .production
    @State private var showingReleaseCreator = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                appSelector

                if let appID = selectedAppID, let app = appService.apps.first(where: { $0.id == appID }) {
                    trackSelector

                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("\(selectedTrack.rawValue) Track").font(.headline)
                            Spacer()
                            Button { showingReleaseCreator = true } label: {
                                Label("Promote Build", systemImage: "plus.app.fill")
                                    .font(.system(size: 11, weight: .bold))
                            }
                        }

                        let trackReleases = app.versions.filter { releaseTrack(for: $0) == selectedTrack }

                        if trackReleases.isEmpty {
                            EmptyStateView(icon: "shippingbox", title: "No Builds", message: "Promote a build to the \(selectedTrack.rawValue.lowercased()) track to start distribution.")
                                .padding(.top, 40)
                        } else {
                            ForEach(trackReleases.sorted(by: { $0.createdAt > $1.createdAt })) { release in
                                releaseCard(release, app: app)
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
        .navigationTitle("Releases")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
        .sheet(isPresented: $showingReleaseCreator) {
            if let appID = selectedAppID {
                NewReleaseSheet(appID: appID)
            }
        }
    }

    private var appSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Project").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Picker("App", selection: $selectedAppID) {
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var trackSelector: some View {
        HStack(spacing: 0) {
            ForEach(ReleaseTrack.allCases, id: \.self) { track in
                Button {
                    selectedTrack = track
                } label: {
                    VStack(spacing: 12) {
                        Text(track.rawValue)
                            .font(.system(size: 11, weight: selectedTrack == track ? .bold : .medium))
                            .foregroundStyle(selectedTrack == track ? .primary : .secondary)

                        Rectangle()
                            .fill(selectedTrack == track ? Color.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func releaseCard(_ release: AppVersion, app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(release.version)").font(.subheadline.bold())
                    Text("Build \(release.buildNumber)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(release.status)
            }

            if !release.releaseNotes.isEmpty {
                Text(release.releaseNotes)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(release.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                if release.version != app.version {
                    Button {
                        promoteToPrimary(release)
                    } label: {
                        Text("Promote to Prod").font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.uppercased()).font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.primary.opacity(0.05))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
    }

    private func releaseTrack(for version: AppVersion) -> ReleaseTrack {
        if version.status.contains("Alpha") { return .alpha }
        if version.status.contains("Beta") { return .beta }
        return .production
    }

    private func promoteToPrimary(_ release: AppVersion) {
        guard var updatedApp = appService.apps.first(where: { $0.id == selectedAppID }) else { return }
        updatedApp.version = release.version
        Task {
            try? await appService.updateApp(updatedApp)
        }
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
                Section("Release Metadata") {
                    TextField("Version (e.g. 1.1.0)", text: $version)
                    TextField("Build (e.g. 1204)", text: $build)
                    Picker("Target Track", selection: $track) {
                        ForEach(ReleaseTrack.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                }

                Section("Changelog") {
                    TextEditor(text: $notes).frame(height: 120)
                }
            }
            .navigationTitle("New Release")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Promote") {
                        let status = track == .production ? "Released" : "\(track.rawValue) Released"
                        let newVersion = AppVersion(version: version, buildNumber: build, releaseNotes: notes, status: status)
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
