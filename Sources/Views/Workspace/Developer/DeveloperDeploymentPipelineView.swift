import SwiftUI

private struct PipelineDetailsView: View {
    let pipeline: Pipeline
    var body: some View {
        Text("Pipeline Details: \(pipeline.name)")
    }
}

struct DeveloperDeploymentPipelineView: View {
    @ObservedObject var deploymentService = DeploymentService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedPipeline: Pipeline?
    @State private var showingTrigger = false
    @State private var selectedAppID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                pipelineSummaryHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Deployment Pipelines").font(.headline)
                        Spacer()
                        Button { showingTrigger = true } label: {
                            Image(systemName: "play.circle.fill").font(.title3)
                        }
                    }

                    if deploymentService.pipelines.isEmpty {
                        EmptyStateView(icon: "hammer", title: "No Pipelines", message: "Automate your build and deployment process by configuring a CI/CD pipeline.")
                    } else {
                        ForEach(deploymentService.pipelines) { pipeline in
                            pipelineRow(pipeline)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("CI/CD")
        .sheet(item: $selectedPipeline) { pipeline in
            PipelineDetailsView(pipeline: pipeline)
        }
        .sheet(isPresented: $showingTrigger) { triggerPipelineSheet }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var pipelineSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fleet Health").font(.headline)
                    Text("Last success: \(deploymentService.pipelines.first(where: { $0.status == .success })?.lastRunAt.formatted(date: .abbreviated, time: .shortened) ?? "N/A")").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.title2)
            }

            HStack(spacing: 32) {
                VStack(alignment: .leading) {
                    Text("98.2%").font(.title3.bold())
                    Text("SUCCESS RATE").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    let avg = deploymentService.pipelines.isEmpty ? "0s" : "4m 12s"
                    Text(avg).font(.title3.bold())
                    Text("AVG DURATION").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func pipelineRow(_ pipeline: Pipeline) -> some View {
        Button {
            selectedPipeline = pipeline
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.triangle.pull").font(.subheadline).foregroundStyle(.secondary)
                    Text(pipeline.name).font(.subheadline.bold())
                    Spacer()
                    statusBadge(pipeline.status)
                }

                HStack(spacing: 12) {
                    ForEach(pipeline.stages) { stage in
                        VStack(spacing: 4) {
                            Circle().fill(stageStatusColor(stage.status)).frame(width: 6, height: 6)
                            Text(stage.name).font(.system(size: 7)).foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    Text(pipeline.lastRunAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                    Spacer()
                    Text("Source: \(pipeline.triggerSource)").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func statusBadge(_ status: PipelineStatus) -> some View {
        Text(status.rawValue.uppercased()).font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(stageStatusColor(status).opacity(0.1))
            .foregroundStyle(stageStatusColor(status))
            .clipShape(Capsule())
    }

    private func stageStatusColor(_ status: PipelineStatus) -> Color {
        switch status {
        case .success: return .green
        case .running: return .blue
        case .failed: return .red
        case .pending: return .gray
        }
    }

    private var triggerPipelineSheet: some View {
        NavigationStack {
            Form {
                Section("Pipeline Context") {
                    Picker("App", selection: $selectedAppID) {
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Run Configuration") {
                    Text("This will trigger a manual execution of the primary deployment pipeline for the selected application.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Trigger Pipeline")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingTrigger = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Execute") {
                        triggerManualPipeline()
                    }
                    .disabled(selectedAppID == nil)
                }
            }
        }
    }

    private func triggerManualPipeline() {
        guard let appID = selectedAppID, let app = appService.apps.first(where: { $0.id == appID }) else { return }
        let stages = [
            PipelineStage(name: "Build", status: .success, logs: "Build successful"),
            PipelineStage(name: "Test", status: .success, logs: "All tests passed"),
            PipelineStage(name: "Deploy", status: .running, logs: "Deploying to production...")
        ]
        let pipeline = Pipeline(name: "\(app.name) - Manual Trigger", status: .running, lastRunAt: Date(), triggerSource: "Manual", stages: stages)
        Task {
            try? await deploymentService.triggerPipeline(pipeline)
            await MainActor.run { showingTrigger = false }
        }
    }
}
