import SwiftUI

struct AppConfigSyncView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var isSyncing = false

    var body: some View {
        List {
            Section("Runtime Instances") {
                if store.configInstances.isEmpty {
                    Text("No instances active.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.configInstances) { instance in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(instance.name).font(.subheadline.bold())
                                Text(instance.version).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(instance.syncStatus)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(instance.syncStatus == "In Sync" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                                .foregroundStyle(instance.syncStatus == "In Sync" ? .green : .orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section {
                Button {
                    isSyncing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isSyncing = false
                        var current = store.configInstances
                        for i in 0..<current.count {
                            current[i].syncStatus = "In Sync"
                            current[i].version = "v1.2.0"
                        }
                        store.saveConfigInstances(current)
                    }
                } label: {
                    if isSyncing {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("Force Sync All Instances", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("Config Sync")
        .onAppear {
            if store.configInstances.isEmpty {
                store.saveConfigInstances([
                    ConfigInstance(name: "Worker-A (US-East)", version: "v1.2.0", syncStatus: "In Sync"),
                    ConfigInstance(name: "Worker-B (US-West)", version: "v1.1.9", syncStatus: "Outdated")
                ])
            }
        }
    }
}
