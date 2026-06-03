import SwiftUI

struct CanaryRolloutView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Active Canary Rollouts") {
                if store.canaryRollouts.isEmpty {
                    Text("No rollouts active.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.canaryRollouts) { rollout in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(rollout.feature).font(.subheadline.bold())
                                Spacer()
                                statusBadge(rollout.status)
                            }

                            HStack {
                                Slider(value: Binding(
                                    get: { rollout.percentage },
                                    set: { val in
                                        var current = store.canaryRollouts
                                        if let idx = current.firstIndex(where: { $0.id == rollout.id }) {
                                            current[idx].percentage = val
                                            store.saveCanaryRollouts(current)
                                        }
                                    }
                                ))
                                Text("\(Int(rollout.percentage * 100))%").font(.caption.monospaced()).frame(width: 40)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Canary Rollout")
        .onAppear {
            if store.canaryRollouts.isEmpty {
                store.saveCanaryRollouts([
                    CanaryRollout(feature: "New AI Engine", percentage: 0.15, status: "Active"),
                    CanaryRollout(feature: "V2 Checkout", percentage: 0.05, status: "Paused")
                ])
            }
        }
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(status == "Active" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            .foregroundStyle(status == "Active" ? .green : .orange)
            .clipShape(Capsule())
    }
}
