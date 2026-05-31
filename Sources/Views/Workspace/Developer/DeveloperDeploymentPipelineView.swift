import SwiftUI

struct DeveloperDeploymentPipelineView: View {
    @ObservedObject var deploymentService = DeploymentService.shared
    @State private var selectedPipeline: Pipeline?
    @State private var showingLogs = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                pipelineSummaryHeader

                VStack(alignment: .leading, spacing: 16) {
                    Text("Active Pipelines").font(.headline)

                    if deploymentService.pipelines.isEmpty {
                        EmptyStateView(icon: "hammer", title: "No Pipelines", message: "Configure a CI/CD pipeline to automate your deployments.")
                    } else {
                        ForEach(deploymentService.pipelines) { pipeline in
                            pipelineRow(pipeline)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("CI/CD Pipelines")
        .sheet(item: $selectedPipeline) { pipeline in
            PipelineDetailsView(pipeline: pipeline)
        }
    }

    private var pipelineSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deployment Health").font(.headline)
                    Text("Last successful deploy: 2h ago").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title2)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("98.2%").font(.title3.bold())
                    Text("Success Rate").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text("4m 12s").font(.title3.bold())
                    Text("Avg Duration").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        stageIndicator(stage)
                    }
                }

                HStack {
                    Text(pipeline.lastRunAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                    Spacer()
                    Text(pipeline.triggerSource).font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func stageIndicator(_ stage: PipelineStage) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(statusColor(stage.status))
                .frame(width: 8, height: 8)
            Text(stage.name).font(.system(size: 6)).foregroundStyle(.secondary)
        }
    }

    private func statusBadge(_ status: PipelineStatus) -> some View {
        Text(status.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: PipelineStatus) -> Color {
        switch status {
        case .success: return .green
        case .running: return .blue
        case .failed: return .red
        case .pending: return .gray
        }
    }
}

struct PipelineDetailsView: View {
    let pipeline: Pipeline
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Stage Details") {
                    ForEach(pipeline.stages) { stage in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stage.name).font(.subheadline.bold())
                                if !stage.logs.isEmpty {
                                    Text(stage.logs).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Spacer()
                            if stage.status == .running {
                                ProgressView().scaleEffect(0.7)
                            } else {
                                Image(systemName: stage.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(stage.status == .success ? .green : .red)
                            }
                        }
                    }
                }

                Section("Manual Actions") {
                    Button {
                        // trigger run
                        dismiss()
                    } label: {
                        Label("Re-run Pipeline", systemImage: "play.fill")
                    }
                }
            }
            .navigationTitle(pipeline.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}
