import SwiftUI

struct TimeTravelHomeView: View {
    @StateObject private var manager = TimeTravelManager.shared

    var body: some View {
        List {
            Section("Global Activity Timeline") {
                if manager.snapshots.isEmpty {
                    Text("No Version History Yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.snapshots.reversed()) { snapshot in
                        NavigationLink(destination: SnapshotDetailView(snapshot: snapshot)) {
                            VStack(alignment: .leading) {
                                Text(snapshot.message)
                                    .font(.subheadline.bold())
                                Text("\(snapshot.entityType) • \(snapshot.timestamp, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Time Travel")
        .onAppear {
            manager.refresh()
        }
    }
}

struct SnapshotDetailView: View {
    let snapshot: WorkspaceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(snapshot.message)
                .font(.title2.bold())

            Text("Entity Type: \(snapshot.entityType)")
            Text("Date: \(snapshot.timestamp, style: .date) \(snapshot.timestamp, style: .time)")

            Divider()

            Button("Restore This State") {
                // Restoration logic would go here
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Snapshot Details")
    }
}
