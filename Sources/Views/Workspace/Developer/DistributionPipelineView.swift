import SwiftUI

struct DistributionPipelineView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Configured Pipelines") {
                pipelineList
            }

            Section {
                addPipelineButton
            }
        }
        .navigationTitle("Distribution")
        .onAppear {
            initialSetup()
        }
    }

    @ViewBuilder
    private var pipelineList: some View {
        if store.distributionTargets.isEmpty {
            Text("No pipelines configured.").font(.caption).foregroundStyle(.secondary)
        } else {
            ForEach(store.distributionTargets) { target in
                targetRow(for: target)
            }
        }
    }

    private func targetRow(for target: DistributionTarget) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(target.name).font(.subheadline.bold())
                Spacer()
                statusBadge(target.status)
            }
            Text(target.type).font(.caption).foregroundStyle(.secondary)

            HStack {
                Button("Deploy Now") {
                    deploy(to: target)
                }
                .font(.caption.bold())
                .buttonStyle(.bordered)
                Button("Settings") { }
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    private var addPipelineButton: some View {
        Button {
            var current = store.distributionTargets
            current.append(DistributionTarget(name: "TestFlight", type: "Beta", status: "Pending"))
            store.saveDistributionTargets(current)
        } label: {
            Label("Add Distribution Channel", systemImage: "plus.circle")
        }
    }

    private func deploy(to target: DistributionTarget) {
        var current = store.activities
        current.append(DeveloperActivityEvent(eventType: .appUpdated, sourceAppName: "Deployed to \(target.name)"))
        store.saveActivities(current)
    }

    private func initialSetup() {
        if store.distributionTargets.isEmpty {
            store.saveDistributionTargets([
                DistributionTarget(name: "Internal Alpha", type: "Enterprise", status: "Active"),
                DistributionTarget(name: "App Store", type: "Public", status: "Ready")
            ])
        }
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }
}
