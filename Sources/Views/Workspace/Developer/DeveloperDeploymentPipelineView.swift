import SwiftUI

struct DeveloperDeploymentPipelineView: View {
    @ObservedObject var deploymentService = DeploymentService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingTriggerBuild = false
    @State private var branchName = "main"

    var filteredPipelines: [Pipeline] {
        deploymentService.pipelines.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select a Project").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Pipelines") {
                if let appID = selectedAppID {
                    if filteredPipelines.isEmpty {
                        EmptyStateView(icon: "hammer.fill", title: "No Builds", message: "Trigger your first deployment pipeline to automate your distribution workflow.")
                    } else {
                        ForEach(filteredPipelines) { pipeline in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(pipeline.branch).font(.subheadline.bold())
                                    Text(pipeline.commitHash.prefix(7)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                statusBadge(pipeline.status)
                            }
                        }
                    }
                } else {
                    Text("Select a project to view deployment history.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("CI/CD Pipelines")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingTriggerBuild = true } label: { Image(systemName: "play.fill") }
                    .disabled(selectedAppID == nil)
            }
        }
        .sheet(isPresented: $showingTriggerBuild) {
            triggerBuildSheet
        }
    }

    private func statusBadge(_ status: PipelineStatus) -> some View {
        Text(status.rawValue).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }

    private var triggerBuildSheet: some View {
        NavigationStack {
            Form {
                Section("Deployment Source") {
                    TextField("Branch Name", text: $branchName)
                }
            }
            .navigationTitle("Trigger Pipeline")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingTriggerBuild = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Trigger") {
                        if let appID = selectedAppID {
                            let pipeline = Pipeline(appID: appID, branch: branchName, commitHash: UUID().uuidString.prefix(40).lowercased())
                            Task {
                                try? await deploymentService.triggerPipeline(pipeline)
                                await MainActor.run { showingTriggerBuild = false }
                            }
                        }
                    }
                    .disabled(branchName.isEmpty)
                }
            }
        }
    }
}
