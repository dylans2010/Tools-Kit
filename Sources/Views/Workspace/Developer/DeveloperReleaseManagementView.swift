import SwiftUI

struct DeveloperReleaseManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddRelease = false
    @State private var version = ""
    @State private var build = ""
    @State private var notes = ""
    @State private var selectedAppID: UUID?

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Active Releases") {
                if let app = selectedApp {
                    if app.versions.isEmpty {
                        Text("No releases yet. Start by uploading a build.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(app.versions) { release in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("v\(release.version) (\(release.buildNumber))").font(.subheadline.bold())
                                    Text(release.releaseNotes).font(.caption).lineLimit(1).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(release.status).font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } else {
                    Text("Select an app to view release history.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Release Management")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddRelease = true } label: { Image(systemName: "plus") }
                    .disabled(selectedAppID == nil)
            }
        }
        .sheet(isPresented: $showingAddRelease) {
            addReleaseSheet
        }
    }

    private var addReleaseSheet: some View {
        NavigationStack {
            Form {
                Section("New Version Details") {
                    TextField("Version Number", text: $version)
                    TextField("Build Number", text: $build)
                    VStack(alignment: .leading) {
                        Text("Release Notes").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $notes).frame(height: 150)
                    }
                }
            }
            .navigationTitle("New Release")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddRelease = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addRelease() }
                        .disabled(version.isEmpty || build.isEmpty)
                }
            }
        }
    }

    private func addRelease() {
        guard let appID = selectedAppID else { return }
        let release = AppVersion(version: version, buildNumber: build, releaseNotes: notes, status: "Draft")

        Task {
            if var app = appService.apps.first(where: { $0.id == appID }) {
                app.versions.insert(release, at: 0)
                try? await appService.updateApp(app)
            }
            await MainActor.run {
                showingAddRelease = false
                version = ""
                build = ""
                notes = ""
            }
        }
    }
}
